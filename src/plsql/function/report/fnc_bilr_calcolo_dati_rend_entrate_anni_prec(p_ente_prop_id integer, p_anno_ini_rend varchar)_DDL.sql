/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr_calcolo_dati_rend_entrate_anni_prec (
  p_ente_prop_id integer,
  p_anno_ini_rend varchar
)
RETURNS TABLE (
  id_titolo integer,
  code_titolo varchar,
  desc_titolo varchar,
  id_tipologia integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  num_anni_rend integer,
  anno varchar,
  importo_accertato numeric,
  importo_riscossioni numeric,
  display_error varchar
) AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    numeroAnni integer;
    numeroAnniConfig integer;
    numeroAnniStr varchar;
    annoInizio integer;
    annoFine integer;    
    bilId integer;
    bilId1 integer;
    bilId2 integer;
    bilId3 integer;
    anno1 integer;
    anno2 integer;
    anno3 integer;
    strParametroNumAnni varchar;
    existAnnoPrec boolean;
    existAnnoPrec1 boolean;
    existAnnoPrec2 boolean;
    contaElem integer;
    strQuery varchar;
    
BEGIN
 
/*
	Funzione che estrae i dati di rendiconto di entrata degli anni precedenti 
    l'anno di bilancio specificato suddivisi per titolo, tipologia e anno.
    Gli anni considerati sono quelli configurati sulla tabella siac_d_gestione_livello
    tramite il parametro CONF_NUM_ANNI_BIL_PREV_INDIC_anno, dove anno e' l'anno
    del bilancio specificato.
    I dati restituiti sono:
    	- Importi accertamenti
        - Importi delle riscossioni.
*/

-- leggo il parametro che mi dice quanti anni di rendiconto devono essere letti 
strParametroNumAnni='CONF_NUM_ANNI_BIL_PREV_INDIC_'||p_anno_ini_rend;
raise notice 'strParametroNumAnni = %', strParametroNumAnni;

display_error='';
numeroAnniStr='';

select a.gestione_livello_desc
into numeroAnniStr
from siac_d_gestione_livello a
	where a.ente_proprietario_id=p_ente_prop_id
    	and a.gestione_livello_code=strParametroNumAnni
        and a.data_cancellazione is null;
	IF NOT FOUND THEN
      RTN_MESSAGGIO:= 'Non e'' stato definito il parametro per determinare il numero di anni del rendiconto.';    
      display_error:=RTN_MESSAGGIO;
      return next;
      return;
    END IF;
    
IF numeroAnniStr IS NULL OR trim(numeroAnniStr) ='' THEN	
	RTN_MESSAGGIO:= 'Non e'' stato definito il parametro per determinare il numero di anni del rendiconto.';    
    display_error:=RTN_MESSAGGIO;
    return next;    
    return;
end if;
    
raise notice 'numeroAnniStr = %', numeroAnniStr;    

numeroAnni:=trim(numeroAnniStr)::integer;
/* 12/03/2018: SIAC-5999.
	la variabile numeroAnniConfig serve nella query per il test degli anni 
	della tabella di configurazione da aggiungere. */
numeroAnniConfig:=numeroAnni;

annoFine:= p_anno_ini_rend::integer - 1;
annoInizio:= p_anno_ini_rend::integer -numeroAnni;
anno3:=annoFine;
anno2:=annoFine-1;
anno1:=annoFine-2;

raise notice 'annoInizio = %, annoFine = %, numeroAnni = %',
	 annoInizio, annoFine, numeroAnni;
     
	/* Leggo l'id dell'anno del rendiconto */     
bilId:=0;     
select a.bil_id 
	INTO bilId
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = p_anno_ini_rend;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId3:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;
   
	/* Leggo gli ID dei bilanci coinvolti (da 1 a 3) in modo da velocizzare le
    	query successive non usando il join con le tabelle siac_t_bil e siac_t_periodo.
        Questo vale soprattito per la query degli impegni che e' piu' lenta.    
    */
bilId1:=0; --anno precedente-2 quello del rendiconto
bilId2:=0; --anno precedente-1 quello del rendiconto
bilId3:=0; --anno precedente quello del rendiconto
    
select a.bil_id 
	INTO bilId3
from siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.ente_proprietario_id=p_ente_prop_id
and b.anno = anno3::varchar;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    bilId3:=0;
    --display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
   -- return next;
    --return;
END IF;

if numeroAnni > 1 THEN
	select a.bil_id 
		INTO bilId2
    from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    and a.ente_proprietario_id=p_ente_prop_id
    and b.anno = anno2::varchar;
    IF NOT FOUND THEN
        RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
        bilId2:=0;
        --raise exception 'Codice del bilancio non trovato per l''anno %', anno2;
        --return;
    END IF;

    if numeroAnni =3 THEN
      select a.bil_id 
          INTO bilId1
      from siac_t_bil a, siac_t_periodo b
      where a.periodo_id=b.periodo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and b.anno = anno1::varchar;
      IF NOT FOUND THEN
          RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
          bilId1:=0;
          --raise exception 'Codice del bilancio non trovato per l''anno %', anno1;
          --return;
      END IF;
    end if;
end if;
    
raise notice 'bilId1 = %, bilId2 = %, bilId3 = %',
	 bilId1, bilId2, bilId3;


existAnnoPrec:=false;
existannoprec1:=false;
existAnnoPrec2:=false;

	--verifico se esiste almeno un valore non NULLO sugli importi
    --relativi all'anno precedente quello del bilancio per capire se prendere 
    -- i dati relativi a quest'anno dalla tabella di configurazione o meno.
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_accert_anno_prec is not NULL OR
        	a.conf_ind_importo_riscoss_anno_prec is not NULL);
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;

raise notice 'contaElem anno Prec = %', contaElem;
if contaElem >0 then
	existAnnoPrec:=true;
end if;

	--verifico se esiste almeno un valore non NULLO sugli importi
    --relativi all'(anno precedente-1) quello del bilancio per capire se prendere 
    -- i dati relativi a quest'anno dalla tabella di configurazione o meno.
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_accert_anno_prec_1 is not NULL OR
        	a.conf_ind_importo_riscoss_anno_prec_1 is not NULL);
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;

raise notice 'contaElem anno Prec-1 = %', contaElem;
if contaElem >0 then
	existAnnoPrec1:=true;
end if;
            

	--verifico se esiste almeno un valore non NULLO sugli importi
    --relativi all'(anno precedente-2) quello del bilancio per capire se prendere 
    -- i dati relativi a quest'anno dalla tabella di configurazione o meno.
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_accert_anno_prec_2 is not NULL OR
        	a.conf_ind_importo_riscoss_anno_prec_2 is not NULL);
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;

raise notice 'contaElem anno Prec-2 = %', contaElem;
if contaElem >0 then
	existAnnoPrec2:=true;    
end if;

raise notice 'existAnnoPrec = %, existAnnoPrec1 = %, existAnnoPrec2 = %',
	existAnnoPrec, existAnnoPrec1, existAnnoPrec2;

      
/* verifico se l'anno precedente a quello del bilancio ha tutti gli importi a 0.
In questo caso NON devo considerare l'annualita' e quindi diminuisco il valore
del numero di anni sul quale fare la media */    
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_accert_anno_prec is  NULL OR
        	  a.conf_ind_importo_accert_anno_prec <> 0) OR
        	 (a.conf_ind_importo_riscoss_anno_prec is  NULL OR
              a.conf_ind_importo_riscoss_anno_prec <> 0)  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;
raise notice 'Numero elementi ANNO PREC diversi da 0 = %', contaElem;
if contaElem = 0 then
	raise notice 'ANNO % escluso', anno3;
	numeroAnni:= numeroAnni-1;
end if;

/* verifico se l'anno precedente-1 a quello del bilancio ha tutti gli importi a 0.
In questo caso NON devo considerare l'annualita' e quindi diminuisco il valore
del numero di anni sul quale fare la media */    
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_accert_anno_prec_1 is  NULL OR
        	  a.conf_ind_importo_accert_anno_prec_1 <> 0) OR
        	 (a.conf_ind_importo_riscoss_anno_prec_1 is  NULL OR
              a.conf_ind_importo_riscoss_anno_prec_1 <> 0)	  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;
raise notice 'Numero elementi ANNO PREC-1 diversi da 0 = %', contaElem;
if contaElem = 0 then
	raise notice 'ANNO % escluso', anno2;
	numeroAnni:= numeroAnni-1;
end if;

/* verifico se l'anno precedente-2 a quello del bilancio ha tuttio gli importi a 0.
In questo caso NON devo considerare l'annualita' e quindi diminuisco il valore
del numero di anni sul quale fare la media */    
contaElem:=0;
select count(*)
	into contaElem
	from siac_t_conf_indicatori_entrata a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_accert_anno_prec_2 is  NULL OR
        	  a.conf_ind_importo_accert_anno_prec_2 <> 0) OR
        	 (a.conf_ind_importo_riscoss_anno_prec_2 is  NULL OR
              a.conf_ind_importo_riscoss_anno_prec_2 <> 0)  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_entrata';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_entrata per l''anno %', p_anno_ini_rend;
    return;
END IF;
raise notice 'Numero elementi ANNO PREC-2 diversi da 0 = %', contaElem;
if contaElem = 0 then
	raise notice 'ANNO % escluso', anno1;
	numeroAnni:= numeroAnni-1;
end if;

strQuery:='with dati_contabilia as (
with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')),
capitoli as(
select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id
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
and e.ente_proprietario_id			=	'||p_ente_prop_id||'
and e.bil_id in ('||bilId1||', '||bilId2||', '||bilId3||')
and tipo_elemento.elem_tipo_code 	= 	''CAP-EG''
and	stato_capitolo.elem_stato_code	=	''VA''
and ct.classif_tipo_code			=	''CATEGORIA''
and	cat_del_capitolo.elem_cat_code	=	''STD''
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
      and movimento.ente_proprietario_id   = '||p_ente_prop_id||'         
      and t_capitolo.elem_tipo_code    		= 	''CAP-EG''
      and ((movimento.movgest_anno = '||anno1||' and movimento.bil_id ='||bilId1||') OR
          (movimento.movgest_anno = '||anno2||' and movimento.bil_id ='||bilId2||') OR
          (movimento.movgest_anno = '||anno3||' and movimento.bil_id ='||bilId3||'))
      and tipo_mov.movgest_tipo_code    	= ''A'' 
      and tipo_stato.movgest_stato_code   in (''D'',''N'') ------ P,A,N       
      and ts_mov_tipo.movgest_ts_tipo_code  = ''T'' 
      and dt_mov_tipo.movgest_ts_det_tipo_code = ''A'' ----- importo attuale 
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
        and	ordinativo.ente_proprietario_id	=	'||p_ente_prop_id||'
        and ((movimento.movgest_anno <= '||anno1 ||' and movimento.bil_id ='||bilId1||') OR
          (movimento.movgest_anno <= '||anno2 ||' and movimento.bil_id ='||bilId2||') OR
          (movimento.movgest_anno <= '||anno3 ||' and movimento.bil_id ='||bilId3||'))
		and	tipo_ordinativo.ord_tipo_code		= 	''I''		------ incasso
        and	stato_ordinativo.ord_stato_code			<> ''A''      
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	''A'' 	---- importo attuala
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
SELECT  strut_bilancio.titolo_id::integer id_titolo,
		strut_bilancio.titolo_code::varchar code_titolo, 
		strut_bilancio.titolo_desc::varchar desc_titolo, 
        strut_bilancio.tipologia_id::integer id_tipologia,
        strut_bilancio.tipologia_code::varchar code_tipologia,
        strut_bilancio.tipologia_desc::varchar desc_tipologia,
        capitoli.anno_bilancio anno,
        sum(accertamenti.importo_accert)::numeric importo_accertato,     
        sum(riscossioni.importo_riscoss)::numeric importo_riscossioni
FROM strut_bilancio
	FULL JOIN capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
    LEFT JOIN accertamenti on accertamenti.elem_id = capitoli.elem_id
    LEFT JOIN riscossioni on riscossioni.elem_id = capitoli.elem_id           
GROUP BY id_titolo, code_titolo, desc_titolo, 
		id_tipologia, code_tipologia, desc_tipologia,anno
-- aggiungo le 3 UNION seguenti (in base al numero di anni) per fare in modo 
-- che tutti gli anni siano sempre estratti in modo da poter sempre 
-- recuperare le info dalla tabella di configurazione anche se su Contabilia 
-- un anno non esiste.';
if numeroAnniConfig = 3 then
  strQuery:=strQuery|| ' 
  UNION
      SELECT titolo_id::integer id_titolo,
          titolo_code::varchar code_titolo, 
          titolo_desc::varchar desc_titolo, 
          tipologia_id::integer id_tipologia,
          tipologia_code::varchar code_tipologia,
          tipologia_desc::varchar desc_tipologia,
          '||anno1||'::varchar anno, NULL importo_accertato, NULL importo_riscossioni
      from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')';
end if;
if numeroAnniConfig >= 2 then
  strQuery:=strQuery|| ' 
 UNION
	SELECT titolo_id::integer id_titolo,
		titolo_code::varchar code_titolo, 
		titolo_desc::varchar desc_titolo, 
        tipologia_id::integer id_tipologia,
        tipologia_code::varchar code_tipologia,
        tipologia_desc::varchar desc_tipologia,
        '||anno2||'::varchar anno, NULL importo_accertato, NULL importo_riscossioni
    from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')';
end if;
if numeroAnniConfig >= 1 then
	strQuery:=strQuery|| ' 
 UNION
	SELECT titolo_id::integer id_titolo,
		titolo_code::varchar code_titolo, 
		titolo_desc::varchar desc_titolo, 
        tipologia_id::integer id_tipologia,
        tipologia_code::varchar code_tipologia,
        tipologia_desc::varchar desc_tipologia,
        '||anno3||'::varchar anno, NULL importo_accertato, NULL importo_riscossioni
    from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')';
end if;
strQuery:=strQuery|| ' 
 ),
importi_tab_config as (
	select * 
    	from siac_t_conf_indicatori_entrata t_conf_indic_ent
        where t_conf_indic_ent.ente_proprietario_id='||p_ente_prop_id||'
    		and t_conf_indic_ent.bil_id='||bilId||')   
SELECT  DISTINCT dati_contabilia.id_titolo::integer id_titolo,
		dati_contabilia.code_titolo::varchar code_titolo, 
		dati_contabilia.desc_titolo::varchar desc_titolo, 
        dati_contabilia.id_tipologia::integer id_tipologia,
        dati_contabilia.code_tipologia::varchar code_tipologia,
        dati_contabilia.desc_tipologia::varchar desc_tipologia,
        '||numeroAnni||'::integer num_anni_rend,
        dati_contabilia.anno anno,
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||'
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_accert_anno_prec
                ELSE dati_contabilia.importo_accertato END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_accert_anno_prec_1
                		ELSE dati_contabilia.importo_accertato END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_accert_anno_prec_2
                		ELSE dati_contabilia.importo_accertato END
                    END
            END importo_accertato, 
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||'
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_riscoss_anno_prec
                ELSE dati_contabilia.importo_riscossioni END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_riscoss_anno_prec_1
                		ELSE dati_contabilia.importo_riscossioni END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_riscoss_anno_prec_2
                		ELSE dati_contabilia.importo_riscossioni END
                    END
            END importo_riscossioni,   
        '''||display_error||'''::varchar display_error    
FROM    dati_contabilia
			LEFT JOIN importi_tab_config on 
            	(importi_tab_config.classif_id_titolo=dati_contabilia.id_titolo
                AND  importi_tab_config.classif_id_tipologia=dati_contabilia.id_tipologia)                            
WHERE dati_contabilia.anno is not null
ORDER BY code_titolo, code_tipologia;';

raise notice 'strQuery = %', strQuery;

return query execute strQuery; 
                    
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
COST 100 ROWS 1000;