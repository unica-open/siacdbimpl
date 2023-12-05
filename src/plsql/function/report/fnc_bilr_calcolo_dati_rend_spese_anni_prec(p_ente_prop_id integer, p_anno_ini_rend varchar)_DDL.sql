/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr_calcolo_dati_rend_spese_anni_prec (
  p_ente_prop_id integer,
  p_anno_ini_rend varchar
)
RETURNS TABLE (
  id_missione integer,
  code_missione varchar,
  desc_missione varchar,
  id_programma integer,
  code_programma varchar,
  desc_programma varchar,
  num_anni_rend integer,
  anno varchar,
  importo_impegnato numeric,
  importo_fpv numeric,
  importo_pag_comp numeric,
  importo_pag_residui numeric,
  importo_residui_passivi numeric,
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
	Funzione che estrae i dati di rendiconto di spesa degli anni precedenti 
    l'anno di bilancio specificato suddivisi per missione, programma e anno.
    Gli anni considerati sono quelli configurati sulla tabella siac_d_gestione_livello
    tramite il parametro CONF_NUM_ANNI_BIL_PREV_INDIC_anno, dove anno e' l'anno
    del bilancio specificato.
    I dati restituiti sono:
    	- Importi impegni
        - Importi FPV
        - Importi pagamenti di competenza
        - Importi pagamenti residui
        - Importi pagamenti residui passivi
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
	La variabile numeroAnniConfig serve nella query per il test degli anni 
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
    bilId:=0;
    display_error := 'Codice del bilancio non trovato per l''anno %', anno3;
    return next;
    return;
END IF;     
raise notice 'BilId dell''anno % = %', p_anno_ini_rend, bilId;

	/* Leggo gli ID dei bilanci coinvolti (da 1 a 3) in modo da velocizzare le
    	query successive non usando il join con le tabelle siac_t_bil e siac_t_periodo.
        Questo vale soprattutto per la query degli impegni che e' piu' lenta.    
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
    raise exception 'Codice del bilancio non trovato per l''anno %', anno3;
    return;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_fpv_anno_prec is not NULL OR
        	a.conf_ind_importo_impegni_anno_prec is not NULL OR
            a.conf_ind_importo_pag_comp_anno_prec is not NULL OR
            a.conf_ind_importo_pag_res_anno_prec is not NULL OR
            a.conf_ind_importo_res_def_anno_prec is not NULL );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_fpv_anno_prec_1 is not NULL OR
        	a.conf_ind_importo_impegni_anno_prec_1 is not NULL OR
            a.conf_ind_importo_pag_comp_anno_prec_1 is not NULL OR
            a.conf_ind_importo_pag_res_anno_prec_1 is not NULL OR
            a.conf_ind_importo_res_def_anno_prec_1 is not NULL );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and (a.conf_ind_importo_fpv_anno_prec_2 is not NULL OR
        	a.conf_ind_importo_impegni_anno_prec_2 is not NULL OR
            a.conf_ind_importo_pag_comp_anno_prec_2 is not NULL OR
            a.conf_ind_importo_pag_res_anno_prec_2 is not NULL OR
            a.conf_ind_importo_res_def_anno_prec_2 is not NULL );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_fpv_anno_prec is  NULL OR
        	  a.conf_ind_importo_fpv_anno_prec <> 0) OR
        	 (a.conf_ind_importo_impegni_anno_prec is  NULL OR
              a.conf_ind_importo_impegni_anno_prec <> 0)	OR
             (a.conf_ind_importo_pag_comp_anno_prec is  NULL OR
              a.conf_ind_importo_pag_comp_anno_prec <> 0 ) OR
             (a.conf_ind_importo_pag_res_anno_prec is  NULL OR
              a.conf_ind_importo_pag_res_anno_prec <> 0) OR
             (a.conf_ind_importo_res_def_anno_prec is  NULL OR
              a.conf_ind_importo_res_def_anno_prec <> 0)  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_fpv_anno_prec_1 is  NULL OR
        	  a.conf_ind_importo_fpv_anno_prec_1 <> 0) OR
        	 (a.conf_ind_importo_impegni_anno_prec_1 is  NULL OR
              a.conf_ind_importo_impegni_anno_prec_1 <> 0)	OR
             (a.conf_ind_importo_pag_comp_anno_prec_1 is  NULL OR
              a.conf_ind_importo_pag_comp_anno_prec_1 <> 0 ) OR
             (a.conf_ind_importo_pag_res_anno_prec_1 is  NULL OR
              a.conf_ind_importo_pag_res_anno_prec_1 <> 0) OR
             (a.conf_ind_importo_res_def_anno_prec_1 is  NULL OR
              a.conf_ind_importo_res_def_anno_prec_1 <> 0)  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
	from siac_t_conf_indicatori_spesa a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.bil_id=bilId
        and ((a.conf_ind_importo_fpv_anno_prec_2 is  NULL OR
        	  a.conf_ind_importo_fpv_anno_prec_2 <> 0) OR
        	 (a.conf_ind_importo_impegni_anno_prec_2 is  NULL OR
              a.conf_ind_importo_impegni_anno_prec_2 <> 0)	OR
             (a.conf_ind_importo_pag_comp_anno_prec_2 is  NULL OR
              a.conf_ind_importo_pag_comp_anno_prec_2 <> 0 ) OR
             (a.conf_ind_importo_pag_res_anno_prec_2 is  NULL OR
              a.conf_ind_importo_pag_res_anno_prec_2 <> 0) OR
             (a.conf_ind_importo_res_def_anno_prec_2 is  NULL OR
              a.conf_ind_importo_res_def_anno_prec_2 <> 0)  );
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Errore nell''accesso a siac_t_conf_indicatori_spesa';
    raise exception 'Errore nell''accesso a siac_t_conf_indicatori_spesa per l''anno %', p_anno_ini_rend;
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
            from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_id,
        CASE WHEN capitolo.bil_id = '||bilId1 ||'
        	THEN '||anno1||'
            ELSE CASE WHEN capitolo.bil_id = '||bilId2||'
            	THEN '||anno2||'
                ELSE '||anno3||' END
        END anno_bilancio
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
    and capitolo.ente_proprietario_id='||p_ente_prop_id	||'
    and capitolo.bil_id in ('||bilId1||', '||bilId2||', '||bilId3||')												
    and programma_tipo.classif_tipo_code=''PROGRAMMA''								
    and macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''							
    and tipo_elemento.elem_tipo_code = ''CAP-UG''						     		
    and stato_capitolo.elem_stato_code	=''VA''     
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
    and	r_cat_capitolo.data_cancellazione 			is null
-- 20/03/2020. SIAC-7446.
--	Devono essere esclusi i capitoli presenti nella tabella siac_t_bil_elem_escludi_indicatori,
--	creata per gestire un''esigenza di CMTO.   
    and capitolo.elem_id NOT IN (select elem_id
			from siac_t_bil_elem_escludi_indicatori escludi
            where escludi.ente_proprietario_id = '||p_ente_prop_id	||'
            	and escludi.validita_fine IS NULL
                and escludi.data_cancellazione IS NULL)),
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
    and t_movgest.ente_proprietario_id ='||p_ente_prop_id||'
    and d_movgest_tipo.movgest_tipo_code=''I''
    and d_movgest_ts_tipo.movgest_ts_tipo_code=''T''
    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code=''A''
    --and d_movgest_stato.movgest_stato_code<>''A''
    -- D = DEFINITIVO
    -- N = DEFINITIVO NON LIQUIDABILE
    -- Devo prendere anche P - PROVVISORIO????
    and d_movgest_stato.movgest_stato_code in (''D'',''N'') 
      and ((t_movgest.movgest_anno = '||anno1||' and t_movgest.bil_id ='||bilId1||') OR
          (t_movgest.movgest_anno = '||anno2||' and t_movgest.bil_id ='||bilId2||') OR
          (t_movgest.movgest_anno = '||anno3||' and t_movgest.bil_id ='||bilId3||'))
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
    and t_bil_elem.ente_proprietario_id='||p_ente_prop_id||'	
    and t_periodo.anno::integer >='||annoInizio||' and t_periodo.anno::integer <='||annoFine||'	
    and d_bil_elem_stato.elem_stato_code=''VA''
    and d_bil_elem_categoria.elem_cat_code	in	(''FPV'',''FPVCC'',''FPVSC'')
    and d_bil_elem_det_tipo.elem_det_tipo_code=''STA''
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
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
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
    and t_movgest.ente_proprietario_id='||p_ente_prop_id||'
    and d_ord_tipo.ord_tipo_code=''P''
    and d_ord_stato.ord_stato_code<>''A''
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code=''A''
	and ((t_movgest.movgest_anno ='||anno1||' and t_movgest.bil_id='||bilId1||') OR
    		(t_movgest.movgest_anno ='||anno2||' and t_movgest.bil_id='||bilId2||') OR
            (t_movgest.movgest_anno ='||anno3||' and t_movgest.bil_id='||bilId3||'))    
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
    and t_movgest.ente_proprietario_id='||p_ente_prop_id||'
    and t_movgest.movgest_anno < t_periodo.anno::integer
    and d_ord_tipo.ord_tipo_code=''P''        
    and d_ord_stato.ord_stato_code<>''A''
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code=''A''
    and t_periodo.anno::integer >='||annoInizio||' and t_periodo.anno::integer <='||annoFine||'
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
     and t_movgest.ente_proprietario_id='||p_ente_prop_id||'
     and t_movgest.movgest_anno < t_periodo.anno::integer
     and d_movgest_tipo.movgest_tipo_code=''I''     
     and d_movgest_stato.movgest_stato_code in (''D'',''N'')  
     and d_movgest_ts_tipo.movgest_ts_tipo_code=''T''      
     and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code=''I''
     and t_periodo.anno::integer >='||annoInizio||' 
     and t_periodo.anno::integer <='||annoFine||'    
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
and t_movgest.ente_proprietario_id='||p_ente_prop_id||'
and ((t_movgest.movgest_anno <'||anno1||' and t_movgest.bil_id='||bilId1||') OR
    		(t_movgest.movgest_anno <'||anno2||' and t_movgest.bil_id='||bilId2||') OR
            (t_movgest.movgest_anno <'||anno3||' and t_movgest.bil_id='||bilId3||')) 
and d_modifica_stato.mod_stato_code=''V''
and d_movgest_tipo.movgest_tipo_code = ''I''
and d_movgest_ts_tipo.movgest_ts_tipo_code  = ''T'' 
and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = ''A'' 
and d_movgest_stato.movgest_stato_code   in (''D'',''N'') 
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
SELECT  strut_bilancio.missione_id::integer id_missione,
		strut_bilancio.missione_code::varchar code_missione, 
		strut_bilancio.missione_desc::varchar desc_missione, 
        strut_bilancio.programma_id::integer id_programma,
        strut_bilancio.programma_code::varchar code_programma,
        strut_bilancio.programma_desc::varchar desc_programma,
        capitoli.anno_bilancio::varchar anno,
        sum(impegni.importo_impegno)::numeric importo_impegnato,     
        sum(fpv.imp_fpv)::numeric importo_fpv,
        sum(pagam_comp.pagamenti_competenza)::numeric importo_pag_comp,
        sum(pagamenti_residui.pagamenti_residui)::numeric importo_pag_residui,
        sum (COALESCE(residui_pass.residui_passivi,0)-
        	COALESCE(pagamenti_residui.pagamenti_residui,0)+
            COALESCE(riacc_residui.riaccertamenti_residui,0)+
            COALESCE(impegni.importo_impegno,0)-
            COALESCE(pagam_comp.pagamenti_competenza,0))::numeric importo_residui_passivi
FROM strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    	AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
    LEFT JOIN impegni on impegni.elem_id = capitoli.elem_id
    LEFT JOIN fpv on fpv.elem_id = capitoli.elem_id
    LEFT JOIN pagam_comp on pagam_comp.elem_id = capitoli.elem_id 
    LEFT JOIN pagamenti_residui on pagamenti_residui.elem_id = capitoli.elem_id        
    LEFT JOIN residui_pass on residui_pass.elem_id = capitoli.elem_id   
    LEFT JOIN riacc_residui on riacc_residui.elem_id = capitoli.elem_id                
GROUP BY id_missione, code_missione, desc_missione, 
		id_programma, code_programma, desc_programma, anno ';
-- aggiungo le 3 UNION seguenti (in base al numero di anni) per fare in modo 
-- che tutti gli anni siano sempre estratti in modo da poter sempre 
-- recuperare le info dalla tabella di configurazione anche se su Contabilia 
-- un anno non esiste.';        
if numeroAnniConfig = 3 then
  strQuery:=strQuery|| '         
UNION
      SELECT missione_id::integer id_missione,
          missione_code::varchar code_missione, 
          missione_desc::varchar desc_missione, 
          programma_id::integer id_programma,
          programma_code::varchar code_programma,
          programma_desc::varchar desc_programma,
          '||anno1||'::varchar anno, 
          NULL importo_impegnato, 
          NULL importo_fpv,
          NULL importo_pag_comp,
          NULL importo_pag_residui,
          NULL importo_residui_passivi
      from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')';
end if;
if numeroAnniConfig >= 2 then
  strQuery:=strQuery|| ' 
UNION
      SELECT missione_id::integer id_missione,
          missione_code::varchar code_missione, 
          missione_desc::varchar desc_missione, 
          programma_id::integer id_programma,
          programma_code::varchar code_programma,
          programma_desc::varchar desc_programma,
          '||anno2||'::varchar anno, 
          NULL importo_impegnato, 
          NULL importo_fpv,
          NULL importo_pag_comp,
          NULL importo_pag_residui,
          NULL importo_residui_passivi
      from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''')';
end if;
if numeroAnniConfig >= 1 then
	strQuery:=strQuery|| ' 
UNION
      SELECT missione_id::integer id_missione,
          missione_code::varchar code_missione, 
          missione_desc::varchar desc_missione, 
          programma_id::integer id_programma,
          programma_code::varchar code_programma,
          programma_desc::varchar desc_programma,
          '||anno3||'::varchar anno, 
          NULL importo_impegnato, 
          NULL importo_fpv,
          NULL importo_pag_comp,
          NULL importo_pag_residui,
          NULL importo_residui_passivi
      from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno_ini_rend||''','''') ';
end if;      
strQuery:=strQuery|| '       
      ),  
importi_tab_config as (
	select * 
    	from siac_t_conf_indicatori_spesa t_conf_indic_spesa
        where t_conf_indic_spesa.ente_proprietario_id='||p_ente_prop_id||'
    		and t_conf_indic_spesa.bil_id='||bilId||') 
SELECT DISTINCT dati_contabilia.id_missione::integer id_missione,
		dati_contabilia.code_missione::varchar code_missione, 
		dati_contabilia.desc_missione::varchar desc_missione, 
        dati_contabilia.id_programma::integer id_programma,
        dati_contabilia.code_programma::varchar code_programma,
        dati_contabilia.desc_programma::varchar desc_programma,
        '||numeroAnni||'::integer num_anni_rend,
        dati_contabilia.anno::varchar anno,
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||'
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_impegni_anno_prec
                ELSE dati_contabilia.importo_impegnato END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_impegni_anno_prec_1
                		ELSE dati_contabilia.importo_impegnato END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_impegni_anno_prec_2
                		ELSE dati_contabilia.importo_impegnato END
                    END
            END importo_impegnato, 
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||'
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_fpv_anno_prec
                ELSE dati_contabilia.importo_fpv END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2 ||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_fpv_anno_prec_1
                		ELSE dati_contabilia.importo_fpv END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_fpv_anno_prec_2
                		ELSE dati_contabilia.importo_fpv END
                    END
            END importo_fpv,      
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||' 
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_pag_comp_anno_prec
                ELSE dati_contabilia.importo_pag_comp END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2 ||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_pag_comp_anno_prec_1
                		ELSE dati_contabilia.importo_pag_comp END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_pag_comp_anno_prec_2
                		ELSE dati_contabilia.importo_pag_comp END
                    END
            END importo_pag_comp,   
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||' 
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_pag_res_anno_prec
                ELSE dati_contabilia.importo_pag_residui END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2 ||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_pag_res_anno_prec_1
                		ELSE dati_contabilia.importo_pag_residui END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_pag_res_anno_prec_2
                		ELSE dati_contabilia.importo_pag_residui END
                    END
            END importo_pag_residui,
        CASE WHEN dati_contabilia.anno::integer = '||anno3 ||' 
        	THEN CASE WHEN '||existAnnoPrec||' = true 
            	THEN importi_tab_config.conf_ind_importo_res_def_anno_prec
                ELSE dati_contabilia.importo_residui_passivi END
            ELSE CASE WHEN dati_contabilia.anno::integer = '||anno2 ||'
            		THEN CASE WHEN '||existAnnoPrec1||' = true 
            			THEN importi_tab_config.conf_ind_importo_res_def_anno_prec_1
                		ELSE dati_contabilia.importo_residui_passivi END
                	ELSE CASE WHEN '||existAnnoPrec2||' = true 
            			THEN importi_tab_config.conf_ind_importo_res_def_anno_prec_2
                		ELSE dati_contabilia.importo_residui_passivi END
                    END
            END importo_residui_passivi,    
        '''||display_error||'''::varchar display_error
FROM    dati_contabilia
			LEFT JOIN importi_tab_config on 
            	(importi_tab_config.classif_id_missione=dati_contabilia.id_missione
                AND  importi_tab_config.classif_id_programma=dati_contabilia.id_programma)                            
WHERE dati_contabilia.anno is not null               
ORDER BY code_missione, code_programma;';

raise notice 'strQuery = %', strQuery;

raise notice 'XXXX existAnnoPrec = %, existAnnoPrec1 = %, existAnnoPrec2 = %',
	existAnnoPrec, existAnnoPrec1, existAnnoPrec2;
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