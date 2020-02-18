/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_configura_indicatori_spesa (
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
    numeroAnni integer;
    annoInizio integer;
    annoFine integer;    
    annoInizioEnteContabilia integer;
    bilId1 integer;
    anno1 integer;
    bilIdAnnoRendPrev integer;
    contaElem integer;
    entePropIdCorr integer;
    elencoEnti record;
    annoDaInserire integer;
    proseguiGestione boolean;
    sqlInstr varchar;

    
BEGIN
 
/*
 Procedura per configurare i dati del Rendiconto di Spesa suddivisi per 
 Missione/Programma sulla tabella siac_t_conf_indicatori_spesa estraendoli dal
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
              -- si prosegue per inserire almeno i record missione/programma 
              -- con importi NULL
            RTN_MESSAGGIO:= 'Codice del bilancio non trovato per l''anno '||p_anno||' - ente '||entePropIdCorr ;
            --raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
            raise notice '%',RTN_MESSAGGIO;      
        END IF;


      raise notice 'bilId1 = %, bilIdAnnoRendPrev = %', bilId1, bilIdAnnoRendPrev;

	-- se e' richiesto l'azzeramento o l'annullamento degli importi esistenti,
    -- eseguo l'UPDATE.
		If p_azzera_importi = true OR p_annulla_importi = true THEN
            sqlInstr:= 'UPDATE siac_t_conf_indicatori_spesa 
                    SET ';
        	If p_azzera_importi = true then
        		If annoDaInserire = 3 then
                  sqlInstr:=sqlInstr||' 
                  conf_ind_importo_fpv_anno_prec=0,
                  conf_ind_importo_impegni_anno_prec=0,
                  conf_ind_importo_pag_comp_anno_prec=0,
                  conf_ind_importo_pag_res_anno_prec=0,
                  conf_ind_importo_res_def_anno_prec=0, ';                  
                elsif annoDaInserire = 2 then
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_fpv_anno_prec_1=0,
                    conf_ind_importo_impegni_anno_prec_1=0,
                    conf_ind_importo_pag_comp_anno_prec_1=0,
                    conf_ind_importo_pag_res_anno_prec_1=0,
                    conf_ind_importo_res_def_anno_prec_1=0, ';
                else 
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_fpv_anno_prec_2=0,
                    conf_ind_importo_impegni_anno_prec_2=0,
                    conf_ind_importo_pag_comp_anno_prec_2=0,
                    conf_ind_importo_pag_res_anno_prec_2=0,
                    conf_ind_importo_res_def_anno_prec_2=0, ';
                end if;
            elsif p_annulla_importi = true then
            	If annoDaInserire = 3 then
                  sqlInstr:=sqlInstr||' 
                  conf_ind_importo_fpv_anno_prec=NULL,
                  conf_ind_importo_impegni_anno_prec=NULL,
                  conf_ind_importo_pag_comp_anno_prec=NULL,
                  conf_ind_importo_pag_res_anno_prec=NULL,
                  conf_ind_importo_res_def_anno_prec=NULL, ';
                elsif annoDaInserire = 2 then
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_fpv_anno_prec_1=NULL,
                    conf_ind_importo_impegni_anno_prec_1=NULL,
                    conf_ind_importo_pag_comp_anno_prec_1=NULL,
                    conf_ind_importo_pag_res_anno_prec_1=NULL,
                    conf_ind_importo_res_def_anno_prec_1=NULL, ';
                else 
                    sqlInstr:=sqlInstr||' 
                    conf_ind_importo_fpv_anno_prec_2=NULL,
                    conf_ind_importo_impegni_anno_prec_2=NULL,
                    conf_ind_importo_pag_comp_anno_prec_2=NULL,
                    conf_ind_importo_pag_res_anno_prec_2=NULL,
                    conf_ind_importo_res_def_anno_prec_2=NULL, ';
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
            FROM siac_t_conf_indicatori_spesa a
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
                          from "fnc_bilr_struttura_cap_bilancio_spese"(entePropIdCorr,p_anno_ini_rend_prev,'')),
              capitoli as(
              select 	programma.classif_id programma_id,
                      macroaggr.classif_id macroaggregato_id,
                      capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
                      capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id,
                      cat_del_capitolo.elem_cat_code tipo_capitolo
              from siac_t_bil_elem capitolo,
                   siac_d_bil_elem_tipo tipo_elemento,
                   siac_r_bil_elem_stato r_capitolo_stato,
                   siac_d_bil_elem_stato stato_capitolo,      
                   siac_r_bil_elem_class r_capitolo_programma,
                   siac_r_bil_elem_class r_capitolo_macroaggr, 	 
                   siac_d_bil_elem_categoria cat_del_capitolo,
                   siac_r_bil_elem_categoria r_cat_capitolo,
                   siac_d_class_tipo programma_tipo,
                   siac_t_class programma,
                   siac_d_class_tipo macroaggr_tipo,
                   siac_t_class macroaggr
              where 		
                  capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
                  and capitolo.elem_id=	r_capitolo_stato.elem_id							
                  and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
                  and capitolo.elem_id=r_capitolo_programma.elem_id							
                  and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
                  and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                  and programma.classif_id=r_capitolo_programma.classif_id					    
                  and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
                  and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
                  and capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
                  and capitolo.ente_proprietario_id=entePropIdCorr	
                  and capitolo.bil_id = bilId1											
                  and programma_tipo.classif_tipo_code='PROGRAMMA'								
                  and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'							
                  and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
                  and stato_capitolo.elem_stato_code	='VA'     
                  and	programma_tipo.data_cancellazione 			is null
                  and	programma.data_cancellazione 				is null
                  and	macroaggr_tipo.data_cancellazione 			is null
                  and	macroaggr.data_cancellazione 				is null
                  and	capitolo.data_cancellazione 				is null
                  and	tipo_elemento.data_cancellazione 			is null
                  and	r_capitolo_programma.data_cancellazione 	is null
                  and	r_capitolo_macroaggr.data_cancellazione 	is null 
                  and	stato_capitolo.data_cancellazione 			is null 
                  and	r_capitolo_stato.data_cancellazione 		is null
                  and	cat_del_capitolo.data_cancellazione 		is null
                  and	r_cat_capitolo.data_cancellazione 			is null),
               impegni as (
                  select-- t_periodo.anno anno_bil,     
                      sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
                      r_movgest_bil_elem.elem_id
                   from siac_t_movgest t_movgest,
                        siac_d_movgest_tipo d_movgest_tipo,
                        siac_t_movgest_ts t_movgest_ts,
                        siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                        siac_r_movgest_ts_stato r_movgest_ts_stato,
                        siac_d_movgest_stato d_movgest_stato,
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                        siac_r_movgest_bil_elem r_movgest_bil_elem
                  where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                  and t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                  and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
                  and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                  and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
                  and t_movgest.ente_proprietario_id =entePropIdCorr
                  and d_movgest_tipo.movgest_tipo_code='I'
                  and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
                  and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                  --and d_movgest_stato.movgest_stato_code<>'A'
                  -- D = DEFINITIVO
                  -- N = DEFINITIVO NON LIQUIDABILE
                  -- Devo prendere anche P - PROVVISORIO????
                  and d_movgest_stato.movgest_stato_code in ('D','N') 
                    and (t_movgest.movgest_anno = anno1 and t_movgest.bil_id =bilId1) 
                  and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
                  and r_movgest_ts_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and d_movgest_tipo.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and d_movgest_ts_tipo.data_cancellazione is null
                  and r_movgest_ts_stato.data_cancellazione is null
                  and r_movgest_bil_elem.data_cancellazione is null
                  and t_movgest_ts_det.data_cancellazione is null
                  and d_movgest_ts_det_tipo.data_cancellazione is null
                GROUP BY elem_id),    
              fpv as (
              select t_bil_elem.elem_id, 
              sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
              from siac_t_bil_elem t_bil_elem,
                  siac_r_bil_elem_stato r_bil_elem_stato, 
                  siac_d_bil_elem_stato d_bil_elem_stato,
                  siac_r_bil_elem_categoria r_bil_elem_categoria,
                  siac_d_bil_elem_categoria d_bil_elem_categoria,
                  siac_t_bil_elem_det t_bil_elem_det,
                  siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
                  and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
                  and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
                  and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
                  and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
                  and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
                  and t_bil.bil_id=t_bil_elem.bil_id
                  and t_bil.periodo_id=t_periodo.periodo_id
                  and t_periodo.periodo_id=t_bil_elem_det.periodo_id
                  and t_bil_elem.ente_proprietario_id=entePropIdCorr	
                  and t_periodo.anno::integer =anno1
                  and d_bil_elem_stato.elem_stato_code='VA'
                  and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
                  and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
                  and r_bil_elem_categoria.validita_fine is NULL
                  and r_bil_elem_stato.validita_fine is NULL
                  and t_bil_elem.data_cancellazione is null
                  and r_bil_elem_stato.data_cancellazione is null
                  and d_bil_elem_stato.data_cancellazione is null
                  and r_bil_elem_categoria.data_cancellazione is null
                  and d_bil_elem_categoria.data_cancellazione is null
                  and t_bil_elem_det.data_cancellazione is null
                  and d_bil_elem_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by t_bil_elem.elem_id),
              pagam_comp as (
              select 
                  r_ord_bil_elem.elem_id,
                  sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_competenza
               from  siac_t_movgest t_movgest, 
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_liquidazione_movgest r_liq_movgest,
                  siac_r_liquidazione_ord r_liq_ord,
                  siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo t_ord,
                  siac_d_ordinativo_tipo d_ord_tipo,
                  siac_r_ordinativo_stato r_ord_stato,
                  siac_d_ordinativo_stato d_ord_stato,
                  siac_r_ordinativo_bil_elem r_ord_bil_elem,
                  siac_t_ordinativo_ts_det t_ord_ts_det,
                  siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and r_liq_ord.liq_id=r_liq_movgest.liq_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                  and r_ord_stato.ord_id=t_ord.ord_id
                  and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                  and r_ord_bil_elem.ord_id=t_ord.ord_id
                  and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                  and t_bil.bil_id=t_movgest.bil_id
                  and t_bil.periodo_id=t_periodo.periodo_id
                  and t_movgest.ente_proprietario_id=entePropIdCorr
                  and t_movgest.movgest_anno=anno1
                  and d_ord_tipo.ord_tipo_code='P'
                  and d_ord_stato.ord_stato_code<>'A'
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
                  and t_periodo.anno::integer =anno1  
                  and r_liq_movgest.validita_fine is NULL
                  and r_liq_ord.validita_fine is NULL
                  and r_ord_bil_elem.validita_fine is NULL
                  and r_ord_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and r_liq_movgest.data_cancellazione is null
                  and r_liq_ord.data_cancellazione is null
                  and t_ord_ts.data_cancellazione is null
                  and t_ord.data_cancellazione is null
                  and d_ord_tipo.data_cancellazione is null
                  and r_ord_stato.data_cancellazione is null
                  and d_ord_stato.data_cancellazione is null
                  and r_ord_bil_elem.data_cancellazione is null
                  and t_ord_ts_det.data_cancellazione is null
                  and d_ord_ts_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by r_ord_bil_elem.elem_id),
              pagamenti_residui as (
              select 
                  r_ord_bil_elem.elem_id,
                  sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_residui
               from  siac_t_movgest t_movgest, 
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_liquidazione_movgest r_liq_movgest,
                  siac_r_liquidazione_ord r_liq_ord,
                  siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo t_ord,
                  siac_d_ordinativo_tipo d_ord_tipo,
                  siac_r_ordinativo_stato r_ord_stato,
                  siac_d_ordinativo_stato d_ord_stato,
                  siac_r_ordinativo_bil_elem r_ord_bil_elem,
                  siac_t_ordinativo_ts_det t_ord_ts_det,
                  siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and r_liq_ord.liq_id=r_liq_movgest.liq_id
                  and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                  and r_ord_bil_elem.ord_id=t_ord.ord_id
                  and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                  and r_ord_stato.ord_id=t_ord.ord_id    
                  and t_bil.bil_id = t_movgest.bil_id
                  and t_periodo.periodo_id= t_bil.periodo_id
                  and t_movgest.ente_proprietario_id=entePropIdCorr
                  and t_movgest.movgest_anno < anno1
                  and d_ord_tipo.ord_tipo_code='P'        
                  and d_ord_stato.ord_stato_code<>'A'
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
                  and t_periodo.anno::integer =anno1
                  and r_liq_movgest.validita_fine is NULL
                  and r_liq_ord.validita_fine is NULL
                  and r_ord_bil_elem.validita_fine is NULL
                  and r_ord_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and r_liq_movgest.data_cancellazione is null
                  and r_liq_ord.data_cancellazione is null
                  and t_ord_ts.data_cancellazione is null
                  and t_ord.data_cancellazione is null
                  and d_ord_tipo.data_cancellazione is null
                  and r_ord_stato.data_cancellazione is null
                  and d_ord_stato.data_cancellazione is null
                  and r_ord_bil_elem.data_cancellazione is null
                  and t_ord_ts_det.data_cancellazione is null
                  and d_ord_ts_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by r_ord_bil_elem.elem_id),
              residui_pass as(
              select r_movgest_bil_elem.elem_id,
                  sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) residui_passivi 
              from siac_t_movgest t_movgest,
                  siac_t_movgest_ts t_movgest_ts,
                  siac_t_movgest_ts_det t_movgest_ts_det,
                  siac_r_movgest_bil_elem r_movgest_bil_elem,
                  siac_d_movgest_tipo d_movgest_tipo,
                  siac_r_movgest_ts_stato r_movgest_ts_stato,
                  siac_d_movgest_stato d_movgest_stato,
                  siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                  siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
               where  t_movgest_ts.movgest_id=t_movgest.movgest_id
                   and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                   and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                   and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id  
                   and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                   and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id  
                   and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id 
                   and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                   and t_bil.bil_id = t_movgest.bil_id
                  and t_periodo.periodo_id= t_bil.periodo_id
                   and t_movgest.ente_proprietario_id=entePropIdCorr
                   and t_movgest.movgest_anno < anno1
                   and d_movgest_tipo.movgest_tipo_code='I'     
                   and d_movgest_stato.movgest_stato_code in ('D','N')  
                   and d_movgest_ts_tipo.movgest_ts_tipo_code='T'      
                   and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
                   and t_periodo.anno::integer =anno1    
                   and r_movgest_ts_stato.validita_fine is NULL
                   and t_movgest.data_cancellazione is null
                   and t_movgest_ts.data_cancellazione is null
                   and t_movgest_ts_det.data_cancellazione is null
                   and r_movgest_bil_elem.data_cancellazione is null
                   and d_movgest_tipo.data_cancellazione is null
                   and r_movgest_ts_stato.data_cancellazione is null
                   and d_movgest_stato.data_cancellazione is null
                   and d_movgest_ts_tipo.data_cancellazione is null
                   and d_movgest_ts_det_tipo.data_cancellazione is null
                   and t_bil.data_cancellazione is null
                   and t_periodo.data_cancellazione is null     
              group by r_movgest_bil_elem.elem_id),
              riacc_residui as (
              select  
              r_movgest_bil_elem.elem_id,
              sum(coalesce(t_movgest_ts_det_mod.movgest_ts_det_importo,0)) riaccertamenti_residui
              from siac_r_movgest_bil_elem r_movgest_bil_elem,
                  siac_t_movgest t_movgest,
                  siac_d_movgest_tipo d_movgest_tipo,
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_movgest_ts_stato r_movgest_ts_stato,
                  siac_d_movgest_stato d_movgest_stato,
                  siac_t_movgest_ts_det t_movgest_ts_det,
                  siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                  siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                  siac_t_modifica t_modifica,
                  siac_r_modifica_stato r_modifica_stato,
                  siac_d_modifica_stato d_modifica_stato,
                  siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
              where r_movgest_bil_elem.movgest_id = t_movgest.movgest_id 
              and t_movgest.movgest_tipo_id = d_movgest_tipo.movgest_tipo_id 
              and t_movgest.movgest_id = t_movgest_ts.movgest_id 
              and t_movgest_ts.movgest_ts_id  = r_movgest_ts_stato.movgest_ts_id 
              and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
              and t_movgest_ts_det.movgest_ts_id = t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id  = t_movgest_ts.movgest_ts_tipo_id 
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id  = t_movgest_ts_det.movgest_ts_det_tipo_id 
              and t_movgest_ts_det_mod.movgest_ts_id=t_movgest_ts.movgest_ts_id      
              and t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
              and r_modifica_stato.mod_id=t_modifica.mod_id
              and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id  
              and t_movgest.ente_proprietario_id=p_ente_prop_id
              and t_movgest.movgest_anno < anno1 and t_movgest.bil_id=bilId1  
              and d_modifica_stato.mod_stato_code='V'
              and d_movgest_tipo.movgest_tipo_code = 'I'
              and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T'
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' 
              and d_movgest_stato.movgest_stato_code   in ('D','N') 
              and r_movgest_ts_stato.validita_fine is NULL
              and r_modifica_stato.validita_fine is NULL
              and r_movgest_bil_elem.data_cancellazione is null 
              and t_movgest.data_cancellazione is null 
              and d_movgest_tipo.data_cancellazione is null 
              and r_movgest_ts_stato.data_cancellazione is null 
              and t_movgest_ts.data_cancellazione is null 
              and d_movgest_stato.data_cancellazione is null 
              and t_movgest_ts_det.data_cancellazione is null 
              and d_movgest_ts_tipo.data_cancellazione is null 
              and d_movgest_ts_det_tipo.data_cancellazione is null
              and t_modifica.data_cancellazione is null
              and r_modifica_stato.data_cancellazione is null
              and d_modifica_stato.data_cancellazione is null
              and t_movgest_ts_det_mod.data_cancellazione is null
              group by r_movgest_bil_elem.elem_id)          
           INSERT INTO siac_t_conf_indicatori_spesa (
                classif_id_missione,
                classif_id_programma,
                bil_id,
                conf_ind_importo_fpv_anno_prec,
                conf_ind_importo_fpv_anno_prec_1,
                conf_ind_importo_fpv_anno_prec_2,            
                conf_ind_importo_impegni_anno_prec,
                conf_ind_importo_impegni_anno_prec_1,
                conf_ind_importo_impegni_anno_prec_2,            
                conf_ind_importo_pag_comp_anno_prec,
                conf_ind_importo_pag_comp_anno_prec_1,
                conf_ind_importo_pag_comp_anno_prec_2,            
                conf_ind_importo_pag_res_anno_prec,
                conf_ind_importo_pag_res_anno_prec_1,
                conf_ind_importo_pag_res_anno_prec_2,
                conf_ind_importo_res_def_anno_prec,
                conf_ind_importo_res_def_anno_prec_1,
                conf_ind_importo_res_def_anno_prec_2,
                validita_inizio,
                validita_fine,
                ente_proprietario_id,
                data_creazione,
                data_modifica,
                data_cancellazione,
                login_operazione)
              SELECT  strut_bilancio.missione_id::integer id_missione,
                      strut_bilancio.programma_id::integer id_programma,
                      bilIdAnnoRendPrev::integer bil_id,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_prec2,                  
                      now(), NULL, 
                      entePropIdCorr::integer  ente_proprietario_id ,
                      now(), now(), NULL, 'admin'
              FROM strut_bilancio
                  LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
                      AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
                  LEFT JOIN impegni on impegni.elem_id = capitoli.elem_id
                  LEFT JOIN fpv on fpv.elem_id = capitoli.elem_id
                  LEFT JOIN pagam_comp on pagam_comp.elem_id = capitoli.elem_id 
                  LEFT JOIN pagamenti_residui on pagamenti_residui.elem_id = capitoli.elem_id        
                  LEFT JOIN residui_pass on residui_pass.elem_id = capitoli.elem_id            
                  LEFT JOIN riacc_residui on riacc_residui.elem_id = capitoli.elem_id
              GROUP BY id_missione, id_programma
              ORDER BY id_missione, id_programma;
        else
             raise notice 'Devo fare UPDATE';
          raise notice 'Ente %, record per l''anno di bilancio % (id=%) GIA'' esistente: MODIFICO',
            entePropIdCorr, p_anno_ini_rend_prev, bilIdAnnoRendPrev;
          UPDATE siac_t_conf_indicatori_spesa 
            set conf_ind_importo_fpv_anno_prec =
                COALESCE(query_tot.importo_fpv_anno_prec, conf_ind_importo_fpv_anno_prec),
              conf_ind_importo_fpv_anno_prec_1 =
                COALESCE(query_tot.importo_fpv_anno_prec1, conf_ind_importo_fpv_anno_prec_1),
              conf_ind_importo_fpv_anno_prec_2 =
                COALESCE(query_tot.importo_fpv_anno_prec2, conf_ind_importo_fpv_anno_prec_2),
              conf_ind_importo_impegni_anno_prec =
                COALESCE(query_tot.importo_impegnato_anno_prec, conf_ind_importo_impegni_anno_prec),
              conf_ind_importo_impegni_anno_prec_1 =
                COALESCE(query_tot.importo_impegnato_anno_prec1, conf_ind_importo_impegni_anno_prec_1),
              conf_ind_importo_impegni_anno_prec_2 =
                COALESCE(query_tot.importo_impegnato_anno_prec2, conf_ind_importo_impegni_anno_prec_2),
              conf_ind_importo_pag_comp_anno_prec =
                COALESCE(query_tot.importo_pag_comp_anno_prec, conf_ind_importo_pag_comp_anno_prec),
              conf_ind_importo_pag_comp_anno_prec_1 =
                COALESCE(query_tot.importo_pag_comp_anno_prec1, conf_ind_importo_pag_comp_anno_prec_1),
              conf_ind_importo_pag_comp_anno_prec_2 =
                COALESCE(query_tot.importo_pag_comp_anno_prec2, conf_ind_importo_pag_comp_anno_prec_2) ,
              conf_ind_importo_pag_res_anno_prec =
                COALESCE(query_tot.importo_pag_residui_anno_prec, conf_ind_importo_pag_res_anno_prec),
              conf_ind_importo_pag_res_anno_prec_1 =
                COALESCE(query_tot.importo_pag_residui_anno_prec1, conf_ind_importo_pag_res_anno_prec_1),
              conf_ind_importo_pag_res_anno_prec_2 =
                COALESCE(query_tot.importo_pag_residui_anno_prec2, conf_ind_importo_pag_res_anno_prec_2),
              conf_ind_importo_res_def_anno_prec =
                COALESCE(query_tot.importo_residui_passivi_anno_prec, conf_ind_importo_res_def_anno_prec),
              conf_ind_importo_res_def_anno_prec_1 =
                COALESCE(query_tot.importo_residui_passivi_anno_prec1, conf_ind_importo_res_def_anno_prec_1),
              conf_ind_importo_res_def_anno_prec_2 =
                COALESCE(query_tot.importo_residui_passivi_anno_prec2, conf_ind_importo_res_def_anno_prec_2)          
            FROM (
             with strut_bilancio as(
                          select  *
                          from "fnc_bilr_struttura_cap_bilancio_spese"(entePropIdCorr,p_anno_ini_rend_prev,'')),
              capitoli as(
              select 	programma.classif_id programma_id,
                      macroaggr.classif_id macroaggregato_id,
                      capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
                      capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id,
                      cat_del_capitolo.elem_cat_code tipo_capitolo
              from siac_t_bil_elem capitolo,
                   siac_d_bil_elem_tipo tipo_elemento,
                   siac_r_bil_elem_stato r_capitolo_stato,
                   siac_d_bil_elem_stato stato_capitolo,      
                   siac_r_bil_elem_class r_capitolo_programma,
                   siac_r_bil_elem_class r_capitolo_macroaggr, 	 
                   siac_d_bil_elem_categoria cat_del_capitolo,
                   siac_r_bil_elem_categoria r_cat_capitolo,
                   siac_d_class_tipo programma_tipo,
                   siac_t_class programma,
                   siac_d_class_tipo macroaggr_tipo,
                   siac_t_class macroaggr
              where 		
                  capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					    
                  and capitolo.elem_id=	r_capitolo_stato.elem_id							
                  and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
                  and capitolo.elem_id=r_capitolo_programma.elem_id							
                  and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
                  and programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                  and programma.classif_id=r_capitolo_programma.classif_id					    
                  and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				
                  and macroaggr.classif_id=r_capitolo_macroaggr.classif_id						
                  and capitolo.elem_id				=	r_cat_capitolo.elem_id				
                  and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		    
                  and capitolo.ente_proprietario_id=entePropIdCorr	
                  and capitolo.bil_id = bilId1											
                  and programma_tipo.classif_tipo_code='PROGRAMMA'								
                  and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'							
                  and tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
                  and stato_capitolo.elem_stato_code	='VA'     
                  and	programma_tipo.data_cancellazione 			is null
                  and	programma.data_cancellazione 				is null
                  and	macroaggr_tipo.data_cancellazione 			is null
                  and	macroaggr.data_cancellazione 				is null
                  and	capitolo.data_cancellazione 				is null
                  and	tipo_elemento.data_cancellazione 			is null
                  and	r_capitolo_programma.data_cancellazione 	is null
                  and	r_capitolo_macroaggr.data_cancellazione 	is null 
                  and	stato_capitolo.data_cancellazione 			is null 
                  and	r_capitolo_stato.data_cancellazione 		is null
                  and	cat_del_capitolo.data_cancellazione 		is null
                  and	r_cat_capitolo.data_cancellazione 			is null),
               impegni as (
                  select    
                      sum(t_movgest_ts_det.movgest_ts_det_importo) importo_impegno,
                      r_movgest_bil_elem.elem_id
                   from siac_t_movgest t_movgest,
                        siac_d_movgest_tipo d_movgest_tipo,
                        siac_t_movgest_ts t_movgest_ts,
                        siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                        siac_r_movgest_ts_stato r_movgest_ts_stato,
                        siac_d_movgest_stato d_movgest_stato,
                        siac_t_movgest_ts_det t_movgest_ts_det,
                        siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                        siac_r_movgest_bil_elem r_movgest_bil_elem
                  where d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
                  and t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                  and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and d_movgest_stato.movgest_stato_id=r_movgest_ts_stato.movgest_stato_id
                  and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                  and r_movgest_bil_elem.movgest_id = t_movgest_ts.movgest_id
                  and t_movgest.ente_proprietario_id =entePropIdCorr
                  and d_movgest_tipo.movgest_tipo_code='I'
                  and d_movgest_ts_tipo.movgest_ts_tipo_code='T'
                  and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                  --and d_movgest_stato.movgest_stato_code<>'A'
                  -- D = DEFINITIVO
                  -- N = DEFINITIVO NON LIQUIDABILE
                  -- Devo prendere anche P - PROVVISORIO????
                  and d_movgest_stato.movgest_stato_code in ('D','N') 
                    and (t_movgest.movgest_anno = anno1 and t_movgest.bil_id =bilId1) 
                  and now() BETWEEN d_movgest_stato.validita_inizio and COALESCE(d_movgest_stato.validita_fine,now())
                  and r_movgest_ts_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and d_movgest_tipo.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and d_movgest_ts_tipo.data_cancellazione is null
                  and r_movgest_ts_stato.data_cancellazione is null
                  and r_movgest_bil_elem.data_cancellazione is null
                  and t_movgest_ts_det.data_cancellazione is null
                  and d_movgest_ts_det_tipo.data_cancellazione is null
                GROUP BY elem_id),    
              fpv as (
              select t_bil_elem.elem_id, 
              sum (coalesce(t_bil_elem_det.elem_det_importo,0)) as imp_fpv
              from siac_t_bil_elem t_bil_elem,
                  siac_r_bil_elem_stato r_bil_elem_stato, 
                  siac_d_bil_elem_stato d_bil_elem_stato,
                  siac_r_bil_elem_categoria r_bil_elem_categoria,
                  siac_d_bil_elem_categoria d_bil_elem_categoria,
                  siac_t_bil_elem_det t_bil_elem_det,
                  siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where  r_bil_elem_stato.elem_id=t_bil_elem.elem_id
                  and d_bil_elem_stato.elem_stato_id=r_bil_elem_stato.elem_stato_id
                  and r_bil_elem_categoria.elem_id=t_bil_elem.elem_id 
                  and d_bil_elem_categoria.elem_cat_id=r_bil_elem_categoria.elem_cat_id
                  and t_bil_elem_det.elem_id=t_bil_elem.elem_id 
                  and d_bil_elem_det_tipo.elem_det_tipo_id=t_bil_elem_det.elem_det_tipo_id
                  and t_bil.bil_id=t_bil_elem.bil_id
                  and t_bil.periodo_id=t_periodo.periodo_id
                  and t_periodo.periodo_id=t_bil_elem_det.periodo_id
                  and t_bil_elem.ente_proprietario_id=entePropIdCorr	
                  and t_periodo.anno::integer =anno1
                  and d_bil_elem_stato.elem_stato_code='VA'
                  and d_bil_elem_categoria.elem_cat_code	in	('FPV','FPVCC','FPVSC')
                  and d_bil_elem_det_tipo.elem_det_tipo_code='STA'
                  and r_bil_elem_categoria.validita_fine is NULL
                  and r_bil_elem_stato.validita_fine is NULL
                  and t_bil_elem.data_cancellazione is null
                  and r_bil_elem_stato.data_cancellazione is null
                  and d_bil_elem_stato.data_cancellazione is null
                  and r_bil_elem_categoria.data_cancellazione is null
                  and d_bil_elem_categoria.data_cancellazione is null
                  and t_bil_elem_det.data_cancellazione is null
                  and d_bil_elem_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by t_bil_elem.elem_id),
              pagam_comp as (
              select 
                  r_ord_bil_elem.elem_id,
                  sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_competenza
               from  siac_t_movgest t_movgest, 
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_liquidazione_movgest r_liq_movgest,
                  siac_r_liquidazione_ord r_liq_ord,
                  siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo t_ord,
                  siac_d_ordinativo_tipo d_ord_tipo,
                  siac_r_ordinativo_stato r_ord_stato,
                  siac_d_ordinativo_stato d_ord_stato,
                  siac_r_ordinativo_bil_elem r_ord_bil_elem,
                  siac_t_ordinativo_ts_det t_ord_ts_det,
                  siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and r_liq_ord.liq_id=r_liq_movgest.liq_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                  and r_ord_stato.ord_id=t_ord.ord_id
                  and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                  and r_ord_bil_elem.ord_id=t_ord.ord_id
                  and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                  and t_bil.bil_id=t_movgest.bil_id
                  and t_bil.periodo_id=t_periodo.periodo_id
                  and t_movgest.ente_proprietario_id=entePropIdCorr
                  and t_movgest.movgest_anno=anno1
                  and d_ord_tipo.ord_tipo_code='P'
                  and d_ord_stato.ord_stato_code<>'A'
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
                  and t_periodo.anno::integer =anno1  
                  and r_liq_movgest.validita_fine is NULL
                  and r_liq_ord.validita_fine is NULL
                  and r_ord_bil_elem.validita_fine is NULL
                  and r_ord_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and r_liq_movgest.data_cancellazione is null
                  and r_liq_ord.data_cancellazione is null
                  and t_ord_ts.data_cancellazione is null
                  and t_ord.data_cancellazione is null
                  and d_ord_tipo.data_cancellazione is null
                  and r_ord_stato.data_cancellazione is null
                  and d_ord_stato.data_cancellazione is null
                  and r_ord_bil_elem.data_cancellazione is null
                  and t_ord_ts_det.data_cancellazione is null
                  and d_ord_ts_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by r_ord_bil_elem.elem_id),
              pagamenti_residui as (
              select 
                  r_ord_bil_elem.elem_id,
                  sum(coalesce(t_ord_ts_det.ord_ts_det_importo,0)) pagamenti_residui
               from  siac_t_movgest t_movgest, 
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_liquidazione_movgest r_liq_movgest,
                  siac_r_liquidazione_ord r_liq_ord,
                  siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo t_ord,
                  siac_d_ordinativo_tipo d_ord_tipo,
                  siac_r_ordinativo_stato r_ord_stato,
                  siac_d_ordinativo_stato d_ord_stato,
                  siac_r_ordinativo_bil_elem r_ord_bil_elem,
                  siac_t_ordinativo_ts_det t_ord_ts_det,
                  siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
              where t_movgest_ts.movgest_id=t_movgest.movgest_id
                  and r_liq_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
                  and r_liq_ord.liq_id=r_liq_movgest.liq_id
                  and r_liq_ord.sord_id=t_ord_ts.ord_ts_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                  and t_ord.ord_id=t_ord_ts.ord_id
                  and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                  and r_ord_bil_elem.ord_id=t_ord.ord_id
                  and t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                  and r_ord_stato.ord_id=t_ord.ord_id    
                  and t_bil.bil_id = t_movgest.bil_id
                  and t_periodo.periodo_id= t_bil.periodo_id
                  and t_movgest.ente_proprietario_id=entePropIdCorr
                  and t_movgest.movgest_anno < anno1
                  and d_ord_tipo.ord_tipo_code='P'        
                  and d_ord_stato.ord_stato_code<>'A'
                  and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
                  and t_periodo.anno::integer =anno1
                  and r_liq_movgest.validita_fine is NULL
                  and r_liq_ord.validita_fine is NULL
                  and r_ord_bil_elem.validita_fine is NULL
                  and r_ord_stato.validita_fine is NULL
                  and t_movgest.data_cancellazione is null
                  and t_movgest_ts.data_cancellazione is null
                  and r_liq_movgest.data_cancellazione is null
                  and r_liq_ord.data_cancellazione is null
                  and t_ord_ts.data_cancellazione is null
                  and t_ord.data_cancellazione is null
                  and d_ord_tipo.data_cancellazione is null
                  and r_ord_stato.data_cancellazione is null
                  and d_ord_stato.data_cancellazione is null
                  and r_ord_bil_elem.data_cancellazione is null
                  and t_ord_ts_det.data_cancellazione is null
                  and d_ord_ts_det_tipo.data_cancellazione is null
                  and t_bil.data_cancellazione is null
                  and t_periodo.data_cancellazione is null
              group by r_ord_bil_elem.elem_id),
              residui_pass as(
              select r_movgest_bil_elem.elem_id,
                  sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) residui_passivi 
              from siac_t_movgest t_movgest,
                  siac_t_movgest_ts t_movgest_ts,
                  siac_t_movgest_ts_det t_movgest_ts_det,
                  siac_r_movgest_bil_elem r_movgest_bil_elem,
                  siac_d_movgest_tipo d_movgest_tipo,
                  siac_r_movgest_ts_stato r_movgest_ts_stato,
                  siac_d_movgest_stato d_movgest_stato,
                  siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                  siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo
               where  t_movgest_ts.movgest_id=t_movgest.movgest_id
                   and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                   and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                   and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id  
                   and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                   and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id  
                   and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id 
                   and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                   and t_bil.bil_id = t_movgest.bil_id
                  and t_periodo.periodo_id= t_bil.periodo_id
                   and t_movgest.ente_proprietario_id=entePropIdCorr
                   and t_movgest.movgest_anno < anno1
                   and d_movgest_tipo.movgest_tipo_code='I'     
                   and d_movgest_stato.movgest_stato_code in ('D','N')  
                   and d_movgest_ts_tipo.movgest_ts_tipo_code='T'      
                   and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
                   and t_periodo.anno::integer =anno1    
                   and r_movgest_ts_stato.validita_fine is NULL
                   and t_movgest.data_cancellazione is null
                   and t_movgest_ts.data_cancellazione is null
                   and t_movgest_ts_det.data_cancellazione is null
                   and r_movgest_bil_elem.data_cancellazione is null
                   and d_movgest_tipo.data_cancellazione is null
                   and r_movgest_ts_stato.data_cancellazione is null
                   and d_movgest_stato.data_cancellazione is null
                   and d_movgest_ts_tipo.data_cancellazione is null
                   and d_movgest_ts_det_tipo.data_cancellazione is null
                   and t_bil.data_cancellazione is null
                   and t_periodo.data_cancellazione is null     
              group by r_movgest_bil_elem.elem_id),         
              riacc_residui as (
              select  
              r_movgest_bil_elem.elem_id,
              sum(coalesce(t_movgest_ts_det_mod.movgest_ts_det_importo,0)) riaccertamenti_residui
              from siac_r_movgest_bil_elem r_movgest_bil_elem,
                  siac_t_movgest t_movgest,
                  siac_d_movgest_tipo d_movgest_tipo,
                  siac_t_movgest_ts t_movgest_ts,
                  siac_r_movgest_ts_stato r_movgest_ts_stato,
                  siac_d_movgest_stato d_movgest_stato,
                  siac_t_movgest_ts_det t_movgest_ts_det,
                  siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                  siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                  siac_t_modifica t_modifica,
                  siac_r_modifica_stato r_modifica_stato,
                  siac_d_modifica_stato d_modifica_stato,
                  siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
              where r_movgest_bil_elem.movgest_id = t_movgest.movgest_id 
              and t_movgest.movgest_tipo_id = d_movgest_tipo.movgest_tipo_id 
              and t_movgest.movgest_id = t_movgest_ts.movgest_id 
              and t_movgest_ts.movgest_ts_id  = r_movgest_ts_stato.movgest_ts_id 
              and r_movgest_ts_stato.movgest_stato_id  = d_movgest_stato.movgest_stato_id 
              and t_movgest_ts_det.movgest_ts_id = t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id  = t_movgest_ts.movgest_ts_tipo_id 
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id  = t_movgest_ts_det.movgest_ts_det_tipo_id 
              and t_movgest_ts_det_mod.movgest_ts_id=t_movgest_ts.movgest_ts_id      
              and t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
              and r_modifica_stato.mod_id=t_modifica.mod_id
              and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id  
              and t_movgest.ente_proprietario_id=p_ente_prop_id
              and t_movgest.movgest_anno < anno1 and t_movgest.bil_id=bilId1  
              and d_modifica_stato.mod_stato_code='V'
              and d_movgest_tipo.movgest_tipo_code = 'I'
              and d_movgest_ts_tipo.movgest_ts_tipo_code  = 'T'
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'A' 
              and d_movgest_stato.movgest_stato_code   in ('D','N') 
              and r_movgest_ts_stato.validita_fine is NULL
              and r_modifica_stato.validita_fine is NULL
              and r_movgest_bil_elem.data_cancellazione is null 
              and t_movgest.data_cancellazione is null 
              and d_movgest_tipo.data_cancellazione is null 
              and r_movgest_ts_stato.data_cancellazione is null 
              and t_movgest_ts.data_cancellazione is null 
              and d_movgest_stato.data_cancellazione is null 
              and t_movgest_ts_det.data_cancellazione is null 
              and d_movgest_ts_tipo.data_cancellazione is null 
              and d_movgest_ts_det_tipo.data_cancellazione is null
              and t_modifica.data_cancellazione is null
              and r_modifica_stato.data_cancellazione is null
              and d_modifica_stato.data_cancellazione is null
              and t_movgest_ts_det_mod.data_cancellazione is null
              group by r_movgest_bil_elem.elem_id),           
              valori_indic as (
                select *
                from siac_t_conf_indicatori_spesa a
                    where a.bil_id = bilIdAnnoRendPrev
                        and a.ente_proprietario_id= entePropIdCorr
                        and a.data_cancellazione IS NULL)      
              SELECT  strut_bilancio.missione_id::integer id_missione,
                      strut_bilancio.programma_id::integer id_programma,
                      bilIdAnnoRendPrev::integer bil_id,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(fpv.imp_fpv),0)::numeric 
                        ELSE NULL end importo_fpv_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(impegni.importo_impegno),0)::numeric 
                        ELSE NULL end importo_impegnato_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(pagam_comp.pagamenti_competenza),0)::numeric 
                        ELSE NULL end importo_pag_comp_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN COALESCE(sum(pagamenti_residui.pagamenti_residui),0)::numeric 
                        ELSE NULL end importo_pag_residui_anno_prec2,
                      CASE WHEN annoDaInserire = 3 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_anno_prec,
                      CASE WHEN annoDaInserire = 2 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_anno_prec1,
                      CASE WHEN annoDaInserire = 1 
                        THEN sum (COALESCE(residui_pass.residui_passivi,0)-
                            COALESCE(pagamenti_residui.pagamenti_residui,0)+
                            COALESCE(riacc_residui.riaccertamenti_residui,0)+
                            COALESCE(impegni.importo_impegno,0)-
                            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric 
                        ELSE NULL end importo_residui_passivi_anno_prec2,
                      valori_indic.conf_ind_id
              FROM strut_bilancio
                  LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
                      AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
                  LEFT JOIN impegni on impegni.elem_id = capitoli.elem_id
                  LEFT JOIN fpv on fpv.elem_id = capitoli.elem_id
                  LEFT JOIN pagam_comp on pagam_comp.elem_id = capitoli.elem_id 
                  LEFT JOIN pagamenti_residui on pagamenti_residui.elem_id = capitoli.elem_id        
                  LEFT JOIN residui_pass on residui_pass.elem_id = capitoli.elem_id
                  LEFT JOIN riacc_residui on riacc_residui.elem_id = capitoli.elem_id
                  LEFT JOIN valori_indic on (valori_indic.classif_id_missione = strut_bilancio.missione_id
                    and valori_indic.classif_id_programma =  strut_bilancio.programma_id)               
              GROUP BY id_missione, id_programma, valori_indic.conf_ind_id
              ORDER BY id_missione, id_programma) query_tot
             where siac_t_conf_indicatori_spesa.conf_ind_id=query_tot.conf_ind_id;
        end if; -- inserimento/modifica.         
    end if; -- Azzera/annulla Importi
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
SECURITY DEFINER
COST 100;