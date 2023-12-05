/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR169_elenco_ord_pag_firma" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_solo_da_firmare boolean,
  p_data_ord_da date,
  p_data_ord_a date,
  p_stato_ord varchar,
  p_cod_distinta varchar,
  p_num_capitolo varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  code_direz_cap varchar,
  desc_direz_cap varchar,
  code_sett_cap varchar,
  desc_sett_cap varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_desc varchar,
  sub_ord_code varchar,
  sub_ord_desc varchar,
  cod_beneficiario varchar,
  desc_beneficiario varchar,
  importo_ordinativo numeric,
  importo_sub_ordinativo numeric,
  data_emissione_ord date,
  ord_stato_code varchar,
  ord_stato_desc varchar,
  ord_quietanza_data date,
  ord_quietanza_importo numeric,
  data_firma date,
  conto_tesoreria varchar,
  dist_code varchar,
  dist_desc varchar,
  data_pagamento date,
  data_annullamento date,
  tipo_bilancio varchar,
  pdce_finanz_code varchar,
  pdce_finanz_descr varchar,
  tipo_impegno varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  desc_subimpegno varchar,
  importo_impegno numeric,
  anno_liquidazione integer,
  num_liquidazione numeric,
  anno_atto_liq varchar,
  num_atto_liq integer,
  cod_tipo_atto_liq varchar,
  desc_tipo_atto_liq varchar,
  code_direz_provv_liq varchar,
  desc_direz_provv_liq varchar,
  code_sett_provv_liq varchar,
  desc_sett_provv_liq varchar,
  anno_atto_imp varchar,
  num_atto_imp integer,
  cod_tipo_atto_imp varchar,
  desc_tipo_atto_imp varchar,
  code_direz_provv_imp varchar,
  desc_direz_provv_imp varchar,
  code_sett_provv_imp varchar,
  desc_sett_provv_imp varchar,
  code_titolo varchar,
  desc_titolo varchar,
  code_missione varchar,
  desc_missione varchar,
  code_programma varchar,
  desc_programma varchar,
  code_macroagg varchar,
  desc_macroagg varchar,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
contaDate integer;
contaParametri integer;
bilId INTEGER;

BEGIN


bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
pdce_finanz_code:='';
pdce_finanz_descr:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
importo_impegno:=0;
code_missione:='';
desc_missione:='';
anno_competenza_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
contaDate:=0;
contaParametri:=0;

if p_solo_da_firmare = true then
	contaParametri:=contaParametri+1;
end if;

if p_data_ord_da IS NOT NULL then
	contaDate:=contaDate+1;
end if;
if p_data_ord_a IS NOT NULL then
	contaDate:=contaDate+1;
end if;
--raise notice 'contaDate = %, contaParametri = %', contaDate, contaParametri;
if contaDate = 1 then
	display_error:='OCCORRE SPECIFICARE ENTRAMBE LE DATE DELL''INTERVALLO DI EMISSSIONE DELL''ORDINATIVO';
    return next;
    return;
elsif contaDate = 2 then
	contaParametri:=contaParametri+1;
end if;
if p_stato_ord IS NOT NULL then
	contaParametri:=contaParametri+1;
end if;
if p_cod_distinta IS NOT NULL then
	contaParametri:=contaParametri+1;
end if;
if p_num_capitolo IS NOT NULL AND p_num_capitolo <> '' THEN
	contaParametri:=contaParametri+1;
end if;

--raise notice 'contaDate = %, contaParametri = %', contaDate, contaParametri;
if contaParametri = 0 then
	display_error:='SPECIFICARE ALMENO UNO DEI PARAMETRI RICHIESTI';
    return next;
    return;
end if;

SELECT t_bil.bil_id 
	into bilId 
FROM siac_t_bil t_bil,
    siac_t_periodo t_periodo
WHERE t_bil.periodo_id = t_periodo.periodo_id
	AND t_bil.ente_proprietario_id = p_ente_prop_id
    AND t_periodo.anno = p_anno
	AND t_bil.data_cancellazione IS NULL
    AND t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	RTN_MESSAGGIO:= 'Codice del bilancio non trovato';
    raise exception 'Codice del bilancio non trovato per l''anno %', p_anno;
    return;
END IF;

raise notice 'bilId = %',bilId;
     
sqlQuery='select query_totale.* from  (
with ordinativi as (
select t_ord.ord_id, 
	t_ord_ts.ord_ts_id,
	d_ord_tipo.ord_tipo_code, 
    t_ord.ord_anno, 
    t_ord.ord_numero, 
    t_ord.ord_desc,    
	t_ord_ts.ord_ts_code, t_ord_ts.ord_ts_desc, 
    t_ord_ts_det.ord_ts_det_importo,
    t_ord.ord_emissione_data,
    r_ord_bil_elem.elem_id,
    d_ord_stato.ord_stato_code,
    d_ord_stato.ord_stato_desc,    
    r_ord_stato.data_creazione data_creazione_stato,
    r_ord_firma.ord_firma_data,
    COALESCE(d_distinta.dist_code, '''') dist_code,
    COALESCE(d_distinta.dist_desc, '''') dist_desc,
    COALESCE(d_conto_tes.contotes_code, '''') contotes_code,
    COALESCE(d_conto_tes.contotes_desc, '''') contotes_desc--,   
from siac_t_ordinativo t_ord		
        LEFT JOIN siac_r_ordinativo_firma r_ord_firma
        	ON (r_ord_firma.ord_id = t_ord.ord_id
            	AND r_ord_firma.data_cancellazione IS NULL)
        LEFT JOIN siac_d_distinta d_distinta
        	ON (d_distinta.dist_id = t_ord.dist_id
            	AND d_distinta.data_cancellazione IS NULL)
        LEFT JOIN siac_d_contotesoreria d_conto_tes
        	ON (d_conto_tes.contotes_id = t_ord.contotes_id
            	AND d_conto_tes.data_cancellazione IS NULL),       
	siac_d_ordinativo_tipo d_ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato d_ord_stato,
	siac_t_ordinativo_ts t_ord_ts,
    siac_t_ordinativo_ts_det t_ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,         
    siac_r_ordinativo_bil_elem r_ord_bil_elem
where d_ord_tipo.ord_tipo_id = t_ord.ord_tipo_id
	and r_ord_stato.ord_id = t_ord.ord_id
	and d_ord_stato.ord_stato_id = r_ord_stato.ord_stato_id
	and t_ord.ord_id = t_ord_ts.ord_id
	and t_ord_ts_det.ord_ts_id = t_ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id = t_ord_ts_det.ord_ts_det_tipo_id   
    and r_ord_bil_elem.ord_id = t_ord.ord_id    
    and t_ord.bil_id = '||bilId||'
    and t_ord.ente_proprietario_id = '||p_ente_prop_id||'
    and d_ord_tipo.ord_tipo_code =''P''  -- ordinativo di pagamento
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code = ''A''';  --importo attuale      

    IF p_solo_da_firmare = true THEN
    	sqlQuery=sqlQuery|| ' and d_ord_stato.ord_stato_code = ''T'''; -- ordinativo trasmesso
    END IF;

    IF p_data_ord_da IS NOT NULL THEN
    	sqlQuery=sqlQuery|| ' and date_trunc(''day'', t_ord.ord_emissione_data) between '''||p_data_ord_da||''' and '''||p_data_ord_a||''' ';
    END IF;     

    IF p_stato_ord IS NOT NULL THEN
    	sqlQuery=sqlQuery|| ' and d_ord_stato.ord_stato_code = '''||p_stato_ord||''' ';
    END IF;
    
    IF p_cod_distinta IS NOT NULL THEN
    	sqlQuery=sqlQuery|| ' and d_distinta.dist_code = '''||p_cod_distinta||''' ';
    END IF;

    sqlQuery=sqlQuery||'
    and r_ord_stato.validita_fine IS NULL -- prendo solo lo stato attivo
    and t_ord.data_cancellazione IS NULL
    and d_ord_tipo.data_cancellazione IS NULL
    and r_ord_stato.data_cancellazione IS NULL
    and d_ord_stato.data_cancellazione IS NULL    
    and t_ord_ts.data_cancellazione IS NULL
    and t_ord_ts_det.data_cancellazione IS NULL
    and d_ord_ts_det_tipo.data_cancellazione IS NULL    
    and r_ord_bil_elem.data_cancellazione IS NULL),   
importi_quiet_ord as(
	SELECT r_ord_quietanza.ord_id,
    	r_ord_quietanza.ord_quietanza_data,
    	COALESCE(r_ord_quietanza.ord_quietanza_importo, 0) ord_quietanza_importo,
        COALESCE(r_ord_storno.ord_storno_importo, 0) ord_storno_importo
    FROM siac_r_ordinativo_quietanza r_ord_quietanza
    	LEFT JOIN siac_r_ordinativo_storno r_ord_storno
       		ON (r_ord_storno.ord_id = r_ord_quietanza.ord_id
            	AND r_ord_storno.data_cancellazione IS NULL)
    WHERE r_ord_quietanza.ente_proprietario_id = '||p_ente_prop_id||'
     AND r_ord_quietanza.data_cancellazione IS NULL),
importi_tot_ord as (
select t_ord_ts.ord_id, sum(t_ord_ts_det.ord_ts_det_importo) importo_ordinativo
from siac_t_ordinativo_ts t_ord_ts, siac_t_ordinativo_ts_det t_ord_ts_det,
	siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where t_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
and t_ord_ts_det.ord_ts_det_tipo_id=d_ord_ts_det_tipo.ord_ts_det_tipo_id
and t_ord_ts.ente_proprietario_id='||p_ente_prop_id||'
and d_ord_ts_det_tipo.ord_ts_det_tipo_code=''A''
and t_ord_ts.data_cancellazione IS NULL
and t_ord_ts_det.data_cancellazione IS NULL
and d_ord_ts_det_tipo.data_cancellazione IS NULL
group by t_ord_ts.ord_id),    
liquidazioni as (
		SELECT t_liq.liq_id,
        		t_liq.liq_anno,
        		t_liq.liq_numero,
                t_liq.liq_importo,
                r_liq_ord.sord_id,
                r_liq_atto_amm.attoamm_id,
                r_liq_movgest.movgest_ts_id
        	from siac_t_liquidazione t_liq
            LEFT JOIN siac_r_liquidazione_atto_amm r_liq_atto_amm
            	ON (r_liq_atto_amm.liq_id=t_liq.liq_id
                	AND r_liq_atto_amm.data_cancellazione IS NULL),           
            	siac_r_liquidazione_ord r_liq_ord,
                siac_r_liquidazione_movgest r_liq_movgest                
            where t_liq.liq_id = r_liq_ord.liq_id
            	and r_liq_movgest.liq_id = t_liq.liq_id
            	and t_liq.ente_proprietario_id = '||p_ente_prop_id||'
                and t_liq.data_cancellazione IS NULL
                and r_liq_ord.data_cancellazione IS NULL
                and r_liq_movgest.data_cancellazione IS NULL),
atti_liq as (
		SELECT  t_atto_amm.attoamm_id,
        		t_atto_amm.attoamm_anno,
                t_atto_amm.attoamm_numero,
                d_atto_amm_tipo.attoamm_tipo_code,
                d_atto_amm_tipo.attoamm_tipo_desc,
                d_atto_amm_stato.attoamm_stato_code,
                d_atto_amm_stato.attoamm_stato_desc
        	FROM siac_t_atto_amm t_atto_amm,
            	siac_d_atto_amm_tipo d_atto_amm_tipo,
                siac_r_atto_amm_stato r_atto_amm_stato,
                siac_d_atto_amm_stato d_atto_amm_stato            
            WHERE d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
                AND r_atto_amm_stato.attoamm_id=t_atto_amm.attoamm_id
                AND d_atto_amm_stato.attoamm_stato_id=r_atto_amm_stato.attoamm_stato_id
                AND t_atto_amm.ente_proprietario_id = '||p_ente_prop_id||'
                AND d_atto_amm_stato.data_cancellazione IS NULL
                AND r_atto_amm_stato.data_cancellazione IS NULL
                AND d_atto_amm_tipo.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL),   
atti_imp as (
		SELECT  t_atto_amm.attoamm_id,
        		t_atto_amm.attoamm_anno,
                t_atto_amm.attoamm_numero,
                d_atto_amm_tipo.attoamm_tipo_code,
                d_atto_amm_tipo.attoamm_tipo_desc,
                d_atto_amm_stato.attoamm_stato_code,
                d_atto_amm_stato.attoamm_stato_desc
        	FROm siac_t_atto_amm t_atto_amm,
            	siac_d_atto_amm_tipo d_atto_amm_tipo,
                siac_r_atto_amm_stato r_atto_amm_stato,
                siac_d_atto_amm_stato d_atto_amm_stato            
            WHERE d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
                AND r_atto_amm_stato.attoamm_id=t_atto_amm.attoamm_id
                AND d_atto_amm_stato.attoamm_stato_id=r_atto_amm_stato.attoamm_stato_id
                AND t_atto_amm.ente_proprietario_id = '||p_ente_prop_id||'
                AND d_atto_amm_stato.data_cancellazione IS NULL
                AND r_atto_amm_stato.data_cancellazione IS NULL
                AND d_atto_amm_tipo.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL),                                               
soggetti as (
		SELECT r_ord_sogg.ord_id,
        		t_sogg.soggetto_code, 
                t_sogg.soggetto_desc
        	from siac_t_soggetto t_sogg,
            	siac_r_ordinativo_soggetto r_ord_sogg
            where t_sogg.soggetto_id = r_ord_sogg.soggetto_id
            and t_sogg.ente_proprietario_id = '||p_ente_prop_id||'
            and r_ord_sogg.data_cancellazione IS NULL
            and t_sogg.data_cancellazione IS NULL),            
impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = ''T''                 
                    THEN ''IMP''
                    ELSE ''SUB'' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo,
                r_movgest_bil_elem.elem_id,
                r_movgest_ts_atto_amm.attoamm_id,
                t_movgest_ts.movgest_ts_desc desc_subimpegno
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts
                	LEFT JOIN siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm
                    	ON (r_movgest_ts_atto_amm.movgest_ts_id = t_movgest_ts.movgest_ts_id
                        	AND r_movgest_ts_atto_amm.data_cancellazione IS NULL),
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_r_movgest_ts_atto_amm r_movgest_ts_atto,
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato,
                siac_r_movgest_bil_elem r_movgest_bil_elem 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND r_movgest_ts_atto.movgest_ts_id=t_movgest_ts.movgest_ts_id            
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                AND t_movgest.ente_proprietario_id='||p_ente_prop_id||'
                AND t_periodo.anno ='''||p_anno||'''
                --AND t_movgest.movgest_anno ='||anno_competenza_int||'
                AND d_movgest_tipo.movgest_tipo_code=''I''    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code=''A'' -- importo attuale 
                	-- Impegni DEFINITIVI o DEFINITIVI NON LIQUIDABILI
                --AND d_movgest_stato.movgest_stato_code  in (''D'',''N'')                 
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND r_movgest_ts_atto.data_cancellazione IS NULL
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione is null),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        '''||p_anno||''' anno_bilancio,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
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
	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    capitolo.elem_id=	r_capitolo_stato.elem_id							and	
    r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and	
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and    
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and	
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    capitolo.ente_proprietario_id='||p_ente_prop_id||'						and 
    capitolo.bil_id = '||bilId||'											and            
    programma_tipo.classif_tipo_code=''PROGRAMMA''							and	
    macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''						and	
    tipo_elemento.elem_tipo_code = ''CAP-UG''						     	and
    stato_capitolo.elem_stato_code	=''VA''     
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
elenco_pdce_finanz as (        
	SELECT  r_movgest_class.movgest_ts_id,
           COALESCE( t_class.classif_code,'''') pdce_code, 
            COALESCE(t_class.classif_desc,'''') pdce_desc 
        from siac_r_movgest_class r_movgest_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_movgest_class.classif_id
                 and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like ''PDC_%''			
                   and r_movgest_class.ente_proprietario_id='||p_ente_prop_id||'
                   AND r_movgest_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL)  , 
subdoc as (
	SELECT distinct r_subdoc_liq.subdoc_id,r_subdoc_liq.liq_id,
to_date(r_subdoc_attr.testo,''dd/mm/yyyy'') data_esecuzione_pagamento
 FROM   siac_r_subdoc_liquidazione r_subdoc_liq,
 		siac_r_subdoc_attr r_subdoc_attr,
   		siac_t_attr t_attr,  
   		siac_d_attr_tipo d_attr_tipo
 WHERE  r_subdoc_liq.subdoc_id = r_subdoc_attr.subdoc_id
 	AND r_subdoc_attr.attr_id = t_attr.attr_id
    AND t_attr.attr_tipo_id = d_attr_tipo.attr_tipo_id
    AND r_subdoc_liq.ente_proprietario_id='||p_ente_prop_id||' 
    and t_attr.attr_code = ''dataEsecuzionePagamento''
    and r_subdoc_attr.testo IS NOT NULL  
    AND r_subdoc_liq.data_cancellazione IS NULL
    AND r_subdoc_attr.data_cancellazione IS NULL
    AND t_attr.data_cancellazione IS NULL
    AND d_attr_tipo.data_cancellazione IS NULL),                   
strutt_amm_cap as (
		select * 
        	from "fnc_elenco_direzioni_settori_cap"('||p_ente_prop_id||')),
strutt_amm_liq as (
		select * 
        	from "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||')), 
strutt_amm_imp as (
		select * 
        	from "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||')),                                    
strut_bilancio as(
     		select *
            from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno||''',''''))                                  
SELECT COALESCE(capitoli.elem_code,'''')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'''')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'''')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'''')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'''')::varchar bil_ele_code3,
    COALESCE(strutt_amm_cap.cod_direz,'''')::varchar code_direz_cap,
    COALESCE(strutt_amm_cap.desc_direz,'''')::varchar desc_direz_cap,
    COALESCE(strutt_amm_cap.cod_sett,'''')::varchar code_sett_cap,
    COALESCE(strutt_amm_cap.desc_sett,'''')::varchar desc_sett_cap,
    ordinativi.ord_anno::integer ord_anno,
    ordinativi.ord_numero::numeric ord_numero,
    ordinativi.ord_desc::varchar ord_desc,
    ordinativi.ord_ts_code::varchar sub_ord_code,
    ordinativi.ord_ts_desc::varchar sub_ord_desc,
	COALESCE(soggetti.soggetto_code,'''')::varchar cod_beneficiario,
    COALESCE(soggetti.soggetto_desc,'''')::varchar desc_beneficiario,
    importi_tot_ord.importo_ordinativo::numeric importo_ordinativo,  
    ordinativi.ord_ts_det_importo::numeric importo_sub_ordinativo,  
	ordinativi.ord_emissione_data::date  data_emissione_ord,    
    ordinativi.ord_stato_code::varchar ord_stato_code,
    ordinativi.ord_stato_desc::varchar ord_stato_desc,
    importi_quiet_ord.ord_quietanza_data::date ord_quietanza_data,
    COALESCE(importi_quiet_ord.ord_quietanza_importo,0) -
    	COALESCE(importi_quiet_ord.ord_storno_importo,0)::numeric ord_quietanza_importo,
    ordinativi.ord_firma_data::date data_firma,
    ordinativi.contotes_code::varchar conto_tesoreria,
    ordinativi.dist_code::varchar dist_code,
    ordinativi.dist_desc::varchar dist_desc,
    subdoc.data_esecuzione_pagamento::DATE data_pagamento,
    CASE WHEN ordinativi.ord_stato_code =''A''
    	THEN ordinativi.data_creazione_stato::DATE 
        ELSE NULL::DATE end data_annullamento,
    CASE WHEN impegni.movgest_anno ='||anno_competenza_int||'
    	THEN ''C''::varchar
        ELSE ''R''::varchar end tipo_bilancio,
	COALESCE(elenco_pdce_finanz.pdce_code,'''')::varchar pdce_finanz_code,
    COALESCE(elenco_pdce_finanz.pdce_desc,'''')::varchar pdce_finanz_descr,
    impegni.tipo_impegno::varchar tipo_impegno,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
    impegni.desc_subimpegno::varchar desc_subimpegno,
	COALESCE(impegni.movgest_ts_det_importo,0)::numeric importo_impegno,
    liquidazioni.liq_anno::integer anno_liquidazione,
    liquidazioni.liq_numero::numeric num_liquidazione,
    atti_liq.attoamm_anno::varchar anno_atto_liq,
    atti_liq.attoamm_numero::integer num_atto_liq,
    atti_liq.attoamm_tipo_code::varchar cod_tipo_atto_liq,
    atti_liq.attoamm_tipo_desc::varchar desc_tipo_atto_liq,
    COALESCE(strutt_amm_liq.cod_direz,'''')::varchar code_direz_provv_liq,
    COALESCE(strutt_amm_liq.desc_direz,'''')::varchar desc_direz_provv_liq,
    COALESCE(strutt_amm_liq.cod_sett,'''')::varchar code_sett_provv_liq,
    COALESCE(strutt_amm_liq.desc_sett,'''')::varchar desc_sett_provv_liq,
    atti_imp.attoamm_anno::varchar anno_atto_imp,
	atti_imp.attoamm_numero::integer num_atto_imp,
    atti_imp.attoamm_tipo_code::varchar cod_tipo_atto_imp,
    atti_imp.attoamm_tipo_desc::varchar desc_tipo_atto_imp,
	COALESCE(strutt_amm_imp.cod_direz,'''')::varchar code_direz_provv_imp,
	COALESCE(strutt_amm_imp.desc_direz,'''')::varchar desc_direz_provv_imp,
    COALESCE(strutt_amm_imp.cod_sett,'''')::varchar code_sett_provv_imp,
	COALESCE(strutt_amm_imp.desc_sett,'''')::varchar desc_sett_provv_imp,       
    COALESCE(strut_bilancio.titusc_code,'''')::varchar code_titolo,
    COALESCE(strut_bilancio.titusc_desc,'''')::varchar desc_titolo,
    COALESCE(strut_bilancio.missione_code,'''')::varchar code_missione,
    COALESCE(strut_bilancio.missione_desc,'''')::varchar desc_missione,    
    COALESCE(strut_bilancio.programma_code,'''')::varchar code_programma,
    COALESCE(strut_bilancio.programma_desc,'''')::varchar desc_programma,
    COALESCE(strut_bilancio.macroag_code,'''')::varchar code_macroagg,
    COALESCE(strut_bilancio.macroag_desc,''''::varchar) desc_macroagg,
    ''''::varchar display_error   
   FROM ordinativi
   	INNER JOIN importi_tot_ord on importi_tot_ord.ord_id = ordinativi.ord_id
    LEFT JOIN importi_quiet_ord on importi_quiet_ord.ord_id = ordinativi.ord_id
    LEFT JOIN capitoli on capitoli.elem_id = ordinativi.elem_id
    LEFT JOIN strutt_amm_cap on strutt_amm_cap.elem_id = capitoli.elem_id
    LEFT JOIN soggetti on soggetti.ord_id = ordinativi.ord_id    
    LEFT JOIN liquidazioni on liquidazioni.sord_id = ordinativi.ord_ts_id 
    LEFT JOIN impegni on impegni.movgest_ts_id =liquidazioni.movgest_ts_id   
    LEFT JOIN atti_imp on atti_imp.attoamm_id = impegni.attoamm_id
  	LEFT JOIN strutt_amm_imp on strutt_amm_imp.attoamm_id = atti_imp.attoamm_id
    LEFT JOIN atti_liq on atti_liq.attoamm_id = liquidazioni.attoamm_id
    LEFT JOIN strutt_amm_liq on strutt_amm_liq.attoamm_id = atti_liq.attoamm_id
    LEFT JOIN subdoc on subdoc.liq_id = liquidazioni.liq_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
    LEFT JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id) ';
if p_num_capitolo IS NOT NULL AND p_num_capitolo <> '' THEN
 	sqlQuery=sqlQuery||' WHERE capitoli.elem_code = '''||p_num_capitolo||''' ';
end if;
sqlQuery=sqlQuery||' ORDER BY ord_anno, ord_numero, anno_impegno, 
	num_impegno, num_subimpegno) query_totale';

raise notice 'query: %',sqlQuery;

return query execute sqlQuery;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
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