/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_configura_indicatori_entrata (
  p_ente_prop_id integer,
  p_anno_ini_rend_prev varchar,
  p_anno varchar,
  p_azzera_importi boolean,
  p_annulla_importi boolean,
  out codicerisultato varchar,
  out descrrisultato varchar
)
RETURNS record AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    bilId1 integer;
    bilIdAnnoRendPrev integer;
	numeroAnni integer;
    anno1 integer;
    contaElem integer;
    entePropIdCorr integer;
    elencoEnti record;
    annoDaInserire integer;
    proseguiGestione boolean;
    sqlInstr varchar;
    
BEGIN

/*
 Procedura per configurare i dati del Rendiconto di Entrata suddivisi per 
 Titolo/Tipologia sulla tabella siac_t_conf_indicatori_entrata estraendoli dal
 sistema.
 La procedura inserisce i dati degli anni precedenti quello del bilancio indicato.
 La procedura puo' essere anche lanciata per aggiornare i dati gia' inseriti.
 
 Parametri:
 	- p_ente_prop_id; ente da configurare; indicare 0 per configurarli tutti.
  	- p_anno_ini_rend_prev; anno del bilancio interessato.
  	- p_anno; anno del rendiconto da inserire.
    - p_azzera_importi; se = true azzera gli importi dell'anno specificato invece che
    	calcolarli.
    - p_annulla_importi; se = true annulla gli importi dell'anno specificato invece che
    	calcolarli.
    
*/

numeroAnni:=1;

anno1:=p_anno::integer;
     
if p_anno::integer = p_anno_ini_rend_prev::integer -1 THEN
	annoDaInserire=3;
elsif p_anno::integer = p_anno_ini_rend_prev::integer -2 THEN
	annoDaInserire=2;
elsif p_anno::integer = p_anno_ini_rend_prev::integer -3 THEN 
	annoDaInserire=1;   
else 
	codiceRisultato:=-1;
    descrRisultato:='L''anno da inserire deve essere uno dei 3 precedenti quello del bilancio';
    return;
end if;    
-- ciclo sugli enti.	
-- se p_ente_prop_id = 0, voglio configurare tutti gli enti.
FOR elencoEnti IN
	SELECT *
    FROM siac_t_ente_proprietario a
    WHERE a.data_cancellazione IS NULL
    	AND (a.ente_proprietario_id = p_ente_prop_id AND p_ente_prop_id <> 0) OR
        	p_ente_prop_id=0
    ORDER BY a.ente_proprietario_id
loop

	entePropIdCorr :=elencoEnti.ente_proprietario_id;
    raise notice 'Ente = %', entePropIdCorr;

    
      bilId1:=0;
      bilIdAnnoRendPrev:=0;
      proseguiGestione:=true;    
      -- leggo il bil_id dell'anno di inizio del rendiconto di previsione
      select a.bil_id 
          INTO bilIdAnnoRendPrev
      from siac_t_bil a, siac_t_periodo b
      where a.periodo_id=b.periodo_id
      and a.ente_proprietario_id=entePropIdCorr
      and b.anno = p_anno_ini_rend_prev;
      IF NOT FOUND THEN
              -- Se non esiste l'anno di bilancio del rendiconto di previsione
              -- NON si puo' proseguire.
          RTN_MESSAGGIO:= 'Codice del bilancio non trovato per l''anno del rendiconto di previsione '||
              p_anno_ini_rend_prev||' - ente '||entePropIdCorr|| '. Per questo ente NON si puo'' proseguire.' ;
          --raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
          raise notice '%',RTN_MESSAGGIO;
          proseguiGestione:=false;
      END IF;

      if proseguiGestione = true then
        -- leggo il bil_id dell'anno per il quale cerco il rendiconto di gestione
        select a.bil_id 
            INTO bilId1
        from siac_t_bil a, siac_t_periodo b
        where a.periodo_id=b.periodo_id
        and a.ente_proprietario_id=entePropIdCorr
        and b.anno = p_anno;
        IF NOT FOUND THEN
              -- Se non esiste l''anno di bilancio del rendiconto di gestione
              -- si prosegue per inseire almeno i record titolo/tipologia 
              --con importi NULL
            RTN_MESSAGGIO:= 'Codice del bilancio non trovato per l''anno '||p_anno||' - ente '||entePropIdCorr ;
            --raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
            raise notice '%',RTN_MESSAGGIO;      
        END IF;
            

        raise notice 'bilId1 = %, bilIdAnnoRendPrev = %', bilId1, bilIdAnnoRendPrev;
  	     
        -- se e' richiesto l'azzeramento o l'annullamento degli importi esistenti,
    -- eseguo l'UPDATE.
		If p_azzera_importi = true OR p_annulla_importi = true THEN
            sqlInstr:= 'UPDATE siac_t_conf_indicatori_entrata 
                    SET ';
        	If p_azzera_importi = true then
        		If annoDaInserire = 3 then
                  sqlInstr:=sqlInstr||' 
                  conf_ind_importo_accert_anno_prec=0,
                  conf_ind_importo_riscoss_anno_prec=0, ';                  
                elsif annoDaInserire = 2 then
                    sqlInstr:=sqlInstr||' 
                  conf_ind_importo_accert_anno_prec_1=0,
                  conf_ind_importo_riscoss_anno_prec_1=0, ';  
                else 
                    sqlInstr:=sqlInstr||' 
                  conf_ind_importo_accert_anno_prec_2=0,
                  conf_ind_importo_riscoss_anno_prec_2=0, ';  
                end if;
            elsif p_annulla_importi = true then
            	If annoDaInserire = 3 then
                  sqlInstr:=sqlInstr||' 
                  conf_ind_importo_accert_anno_prec=NULL,
                  conf_ind_importo_riscoss_anno_prec=NULL, ';
                elsif annoDaInserire = 2 then
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_accert_anno_prec_1=NULL,
                    conf_ind_importo_riscoss_anno_prec_1=NULL, ';
                else 
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_accert_anno_prec_2=NULL,
                    conf_ind_importo_riscoss_anno_prec_2=NULL, ';
                end if;
            end if;            
        	sqlInstr:=sqlInstr||'
            data_modifica = now(),
                  login_operazione = login_operazione|| '' fnc_configura_indicatori_spesa'' 
                  WHERE ente_proprietario_id='||entePropIdCorr||'
                      AND bil_id='||bilIdAnnoRendPrev; 
			raise notice 'sqlInstr = %',sqlInstr;
        
        	execute sqlInstr;
    else 
        --verifico se i record dell'anno di bilancio sono gia' stati inseriti.
        contaElem:=0;    
        SELECT COUNT(*)
        INTO contaElem
        FROM siac_t_conf_indicatori_entrata a
        WHERE a.bil_id = bilIdAnnoRendPrev
            AND a.ente_proprietario_id=entePropIdCorr;
        IF NOT FOUND THEN
            contaElem:=0;
            
        END IF;

        if contaElem = 0 then -- record non ancora esistente, quindi inserisco.
            raise notice 'Ente %, record per l''anno di bilancio % (id=%) NON  esistente: INSERISCO',
              entePropIdCorr, p_anno_ini_rend_prev, bilIdAnnoRendPrev;
        with strut_bilancio as(
                    select  *
                    from "fnc_bilr_struttura_cap_bilancio_entrate"(entePropIdCorr,p_anno_ini_rend_prev,'')),
        capitoli as(
        select cl.classif_id categoria_id,
          e.*
         from 	siac_r_bil_elem_class rc,
                siac_t_bil_elem e,
                siac_d_class_tipo ct,
                siac_t_class cl,
                siac_t_bil bilancio,
                siac_t_periodo anno_eserc,
                siac_d_bil_elem_tipo tipo_elemento, 
                siac_d_bil_elem_stato stato_capitolo,
                siac_r_bil_elem_stato r_capitolo_stato,
                siac_d_bil_elem_categoria cat_del_capitolo,
                siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id				=	cl.classif_tipo_id
        and cl.classif_id					=	rc.classif_id 
        and bilancio.periodo_id				=	anno_eserc.periodo_id 
        and e.bil_id						=	bilancio.bil_id 
        and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and e.elem_id						=	rc.elem_id 
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and e.ente_proprietario_id			=	entePropIdCorr
        and e.bil_id = bilId1
        and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
        and	stato_capitolo.elem_stato_code	=	'VA'
        and ct.classif_tipo_code			=	'CATEGORIA'
        and	cat_del_capitolo.elem_cat_code	=	'STD'
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	bilancio.data_cancellazione 		is null
        and	anno_eserc.data_cancellazione 		is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
        and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
        and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
        ),
         accertamenti as (
            select capitolo.elem_id,
                sum (dt_movimento.movgest_ts_det_importo) importo_accert
            from 
              siac_t_bil_elem     capitolo , 
              siac_r_movgest_bil_elem   r_mov_capitolo, 
              siac_d_bil_elem_tipo    t_capitolo, 
              siac_t_movgest     movimento, 
              siac_d_movgest_tipo    tipo_mov, 
              siac_t_movgest_ts    ts_movimento, 
              siac_r_movgest_ts_stato   r_movimento_stato, 
              siac_d_movgest_stato    tipo_stato, 
              siac_t_movgest_ts_det   dt_movimento, 
              siac_d_movgest_ts_tipo   ts_mov_tipo, 
              siac_d_movgest_ts_det_tipo  dt_mov_tipo 
              where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id  
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id  
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
              and movimento.ente_proprietario_id   = entePropIdCorr         
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and (movimento.movgest_anno = anno1 and movimento.bil_id =bilId1)
              and tipo_mov.movgest_tipo_code    	= 'A' 
              and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
              and now() 
                between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() 
                between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
              and capitolo.data_cancellazione     	is null 
              and r_mov_capitolo.data_cancellazione is null 
              and t_capitolo.data_cancellazione    	is null 
              and movimento.data_cancellazione     	is null 
              and tipo_mov.data_cancellazione     	is null 
              and r_movimento_stato.data_cancellazione   is null 
              and ts_movimento.data_cancellazione   is null 
              and tipo_stato.data_cancellazione    	is null 
              and dt_movimento.data_cancellazione   is null 
              and ts_mov_tipo.data_cancellazione    is null 
              and dt_mov_tipo.data_cancellazione    is null      
        group by capitolo.elem_id),    
        riscossioni as (
        select 		r_capitolo_ordinativo.elem_id,
                    sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
        from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
                    siac_t_ordinativo				ordinativo,
                    siac_d_ordinativo_tipo			tipo_ordinativo,
                    siac_r_ordinativo_stato			r_stato_ordinativo,
                    siac_d_ordinativo_stato			stato_ordinativo,
                    siac_t_ordinativo_ts 			ordinativo_det,
                    siac_t_ordinativo_ts_det 		ordinativo_imp,
                    siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
                    siac_t_movgest     				movimento,
                    siac_t_movgest_ts    			ts_movimento, 
                    siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
            where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
                and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
                and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
                and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id   ------		           
                and	ordinativo.ord_id					=	ordinativo_det.ord_id
                and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
                and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
                and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
                and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
                and	ts_movimento.movgest_id				=	movimento.movgest_id    
                and	ordinativo.ente_proprietario_id	=	entePropIdCorr
                and (movimento.movgest_anno <= anno1 and movimento.bil_id =bilId1)
                and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
                and	stato_ordinativo.ord_stato_code			<> 'A'       
                and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
                and	r_capitolo_ordinativo.data_cancellazione	is null
                and	ordinativo.data_cancellazione				is null
                AND	tipo_ordinativo.data_cancellazione			is null
                and	r_stato_ordinativo.data_cancellazione		is null
                AND	stato_ordinativo.data_cancellazione			is null
                AND ordinativo_det.data_cancellazione			is null
                aND ordinativo_imp.data_cancellazione			is null
                and ordinativo_imp_tipo.data_cancellazione		is null
                and	movimento.data_cancellazione				is null
                and	ts_movimento.data_cancellazione				is null
                and	r_ordinativo_movgest.data_cancellazione		is null
            and now()
        between r_capitolo_ordinativo.validita_inizio 
            and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now()
        between r_stato_ordinativo.validita_inizio 
            and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now()
        between r_ordinativo_movgest.validita_inizio 
            and COALESCE(r_ordinativo_movgest.validita_fine,now())
                group by r_capitolo_ordinativo.elem_id)
        INSERT INTO siac_t_conf_indicatori_entrata (
            classif_id_titolo,
            classif_id_tipologia,
            bil_id,
            conf_ind_importo_accert_anno_prec ,
            conf_ind_importo_accert_anno_prec_1,
            conf_ind_importo_accert_anno_prec_2,
            conf_ind_importo_riscoss_anno_prec,
            conf_ind_importo_riscoss_anno_prec_1,
            conf_ind_importo_riscoss_anno_prec_2,
            validita_inizio,
            validita_fine,
            ente_proprietario_id,
            data_creazione,
            data_modifica,
            data_cancellazione,
            login_operazione)
        SELECT  strut_bilancio.titolo_id::integer id_titolo,
                strut_bilancio.tipologia_id::integer id_tipologia,		
                bilIdAnnoRendPrev::integer bil_id,
                CASE WHEN annoDaInserire = 3 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec,
                CASE WHEN annoDaInserire = 2 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec1,
                CASE WHEN annoDaInserire = 1 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec2,
                CASE WHEN annoDaInserire = 3 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric
                    ELSE NULL end importo_riscoss_anno_prec,
                CASE WHEN annoDaInserire = 2 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric 
                    ELSE NULL end importo_riscoss_anno_prec1,
                CASE WHEN annoDaInserire = 1 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric 
                    ELSE NULL end importo_riscoss_anno_prec2,
                now(), NULL, 
                entePropIdCorr::integer  ente_proprietario_id ,
                now(), now(), NULL, 'admin'		
        FROM strut_bilancio
            LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
            LEFT JOIN accertamenti on accertamenti.elem_id = capitoli.elem_id
            LEFT JOIN riscossioni on riscossioni.elem_id = capitoli.elem_id           
        GROUP BY id_titolo, id_tipologia
        ORDER BY id_titolo, id_tipologia;

        else 
            raise notice 'Devo fare UPDATE';
            raise notice 'Ente %, record per l''anno di bilancio % (id=%) GIA'' esistente: MODIFICO',
              entePropIdCorr, p_anno_ini_rend_prev, bilIdAnnoRendPrev;
        UPDATE siac_t_conf_indicatori_entrata
            set  conf_ind_importo_accert_anno_prec= 
                COALESCE(query_tot.importo_accertato_anno_prec, conf_ind_importo_accert_anno_prec), 
            conf_ind_importo_accert_anno_prec_1=
                COALESCE(query_tot.importo_accertato_anno_prec1,conf_ind_importo_accert_anno_prec_1),
            conf_ind_importo_accert_anno_prec_2=
                COALESCE(query_tot.importo_accertato_anno_prec2,conf_ind_importo_accert_anno_prec_2),
            conf_ind_importo_riscoss_anno_prec=
                COALESCE(query_tot.importo_riscoss_anno_prec,conf_ind_importo_riscoss_anno_prec),
            conf_ind_importo_riscoss_anno_prec_1=
                COALESCE(query_tot.importo_riscoss_anno_prec1,conf_ind_importo_riscoss_anno_prec_1),
            conf_ind_importo_riscoss_anno_prec_2=
                COALESCE(query_tot.importo_riscoss_anno_prec2,conf_ind_importo_riscoss_anno_prec_2)
        FROM (         
        with strut_bilancio as(
                    select  *
                    from "fnc_bilr_struttura_cap_bilancio_entrate"(entePropIdCorr,p_anno_ini_rend_prev,'')),
        capitoli as(
        select cl.classif_id categoria_id,
          e.*
         from 	siac_r_bil_elem_class rc,
                siac_t_bil_elem e,
                siac_d_class_tipo ct,
                siac_t_class cl,
                siac_t_bil bilancio,
                siac_t_periodo anno_eserc,
                siac_d_bil_elem_tipo tipo_elemento, 
                siac_d_bil_elem_stato stato_capitolo,
                siac_r_bil_elem_stato r_capitolo_stato,
                siac_d_bil_elem_categoria cat_del_capitolo,
                siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id				=	cl.classif_tipo_id
        and cl.classif_id					=	rc.classif_id 
        and bilancio.periodo_id				=	anno_eserc.periodo_id 
        and e.bil_id						=	bilancio.bil_id 
        and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and e.elem_id						=	rc.elem_id 
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and e.ente_proprietario_id			=	entePropIdCorr
        and e.bil_id = bilId1
        and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
        and	stato_capitolo.elem_stato_code	=	'VA'
        and ct.classif_tipo_code			=	'CATEGORIA'
        and	cat_del_capitolo.elem_cat_code	=	'STD'
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	bilancio.data_cancellazione 		is null
        and	anno_eserc.data_cancellazione 		is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
        and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
        and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
        ),
         accertamenti as (
            select capitolo.elem_id,
                sum (dt_movimento.movgest_ts_det_importo) importo_accert
            from 
              siac_t_bil_elem     capitolo , 
              siac_r_movgest_bil_elem   r_mov_capitolo, 
              siac_d_bil_elem_tipo    t_capitolo, 
              siac_t_movgest     movimento, 
              siac_d_movgest_tipo    tipo_mov, 
              siac_t_movgest_ts    ts_movimento, 
              siac_r_movgest_ts_stato   r_movimento_stato, 
              siac_d_movgest_stato    tipo_stato, 
              siac_t_movgest_ts_det   dt_movimento, 
              siac_d_movgest_ts_tipo   ts_mov_tipo, 
              siac_d_movgest_ts_det_tipo  dt_mov_tipo 
              where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id      
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id  
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id  
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
              and movimento.ente_proprietario_id   = entePropIdCorr         
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and (movimento.movgest_anno = anno1 and movimento.bil_id =bilId1)
              and tipo_mov.movgest_tipo_code    	= 'A' 
              and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
              and now() 
                between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() 
                between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
              and capitolo.data_cancellazione     	is null 
              and r_mov_capitolo.data_cancellazione is null 
              and t_capitolo.data_cancellazione    	is null 
              and movimento.data_cancellazione     	is null 
              and tipo_mov.data_cancellazione     	is null 
              and r_movimento_stato.data_cancellazione   is null 
              and ts_movimento.data_cancellazione   is null 
              and tipo_stato.data_cancellazione    	is null 
              and dt_movimento.data_cancellazione   is null 
              and ts_mov_tipo.data_cancellazione    is null 
              and dt_mov_tipo.data_cancellazione    is null      
        group by capitolo.elem_id),    
        riscossioni as (
        select 		r_capitolo_ordinativo.elem_id,
                    sum(ordinativo_imp.ord_ts_det_importo) importo_riscoss
        from 		siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
                    siac_t_ordinativo				ordinativo,
                    siac_d_ordinativo_tipo			tipo_ordinativo,
                    siac_r_ordinativo_stato			r_stato_ordinativo,
                    siac_d_ordinativo_stato			stato_ordinativo,
                    siac_t_ordinativo_ts 			ordinativo_det,
                    siac_t_ordinativo_ts_det 		ordinativo_imp,
                    siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
                    siac_t_movgest     				movimento,
                    siac_t_movgest_ts    			ts_movimento, 
                    siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
            where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
                and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id 
                and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
                and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id   ------		           
                and	ordinativo.ord_id					=	ordinativo_det.ord_id
                and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
                and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
                and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
                and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
                and	ts_movimento.movgest_id				=	movimento.movgest_id    
                and	ordinativo.ente_proprietario_id	=	entePropIdCorr
                and (movimento.movgest_anno <= anno1 and movimento.bil_id =bilId1)
                and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
                and	stato_ordinativo.ord_stato_code			<> 'A'       
                and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
                and	r_capitolo_ordinativo.data_cancellazione	is null
                and	ordinativo.data_cancellazione				is null
                AND	tipo_ordinativo.data_cancellazione			is null
                and	r_stato_ordinativo.data_cancellazione		is null
                AND	stato_ordinativo.data_cancellazione			is null
                AND ordinativo_det.data_cancellazione			is null
                aND ordinativo_imp.data_cancellazione			is null
                and ordinativo_imp_tipo.data_cancellazione		is null
                and	movimento.data_cancellazione				is null
                and	ts_movimento.data_cancellazione				is null
                and	r_ordinativo_movgest.data_cancellazione		is null
            and now()
        between r_capitolo_ordinativo.validita_inizio 
            and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now()
        between r_stato_ordinativo.validita_inizio 
            and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now()
        between r_ordinativo_movgest.validita_inizio 
            and COALESCE(r_ordinativo_movgest.validita_fine,now())
                group by r_capitolo_ordinativo.elem_id),
        valori_indic as (
            select *
            from siac_t_conf_indicatori_entrata a
            where a.bil_id = bilIdAnnoRendPrev
                and a.ente_proprietario_id= entePropIdCorr
                and a.data_cancellazione IS NULL)        
        SELECT  strut_bilancio.titolo_id::integer id_titolo,
                strut_bilancio.tipologia_id::integer id_tipologia,		
                bilIdAnnoRendPrev::integer bil_id,
                CASE WHEN annoDaInserire = 3 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec,
                CASE WHEN annoDaInserire = 2 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec1,
                CASE WHEN annoDaInserire = 1 
                    THEN COALESCE(sum(accertamenti.importo_accert),0)::numeric 
                    ELSE NULL end importo_accertato_anno_prec2,
                CASE WHEN annoDaInserire = 3 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric
                    ELSE NULL end importo_riscoss_anno_prec,
                CASE WHEN annoDaInserire = 2 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric 
                    ELSE NULL end importo_riscoss_anno_prec1,
                CASE WHEN annoDaInserire = 1 
                    THEN COALESCE(sum(riscossioni.importo_riscoss),0)::numeric 
                    ELSE NULL end importo_riscoss_anno_prec2,
                valori_indic.conf_ind_id	
        FROM strut_bilancio
            LEFT JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
            LEFT JOIN accertamenti on accertamenti.elem_id = capitoli.elem_id
            LEFT JOIN riscossioni on riscossioni.elem_id = capitoli.elem_id    
            LEFT JOIN valori_indic on (valori_indic.classif_id_titolo = strut_bilancio.titolo_id
                and valori_indic.classif_id_tipologia =  strut_bilancio.tipologia_id)        
        GROUP BY id_titolo, id_tipologia, valori_indic.conf_ind_id
        ORDER BY id_titolo, id_tipologia) query_tot
        where siac_t_conf_indicatori_entrata.conf_ind_id=query_tot.conf_ind_id;
              
        end if; -- inserimento/modifica.
    end if; -- azzera/annulla importi
end if; -- proseguiGestione     
end loop;
               
codiceRisultato:=0;
descrRisultato:='Operazioni concluse correttamente';

EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;