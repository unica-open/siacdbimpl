/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR144_Stampa_giorn_mandati_pagamento_emessi" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_numero_distinta varchar,
  p_stato_mandato varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  cod_gestione varchar,
  num_impegno varchar,
  num_subimpegno varchar,
  importo_lordo_mandato numeric,
  numero_mandato integer,
  data_mandato date,
  importo_stanz_cassa numeric,
  importo_tot_mandati_emessi numeric,
  importo_tot_mandati_dopo_emiss numeric,
  importo_dispon numeric,
  nome_tesoriere varchar,
  desc_causale varchar,
  desc_provvedimento varchar,
  estremi_provvedimento varchar,
  numero_fattura_completa varchar,
  num_fattura varchar,
  anno_fattura integer,
  importo_documento numeric,
  num_sub_doc_fattura integer,
  importo_fattura numeric,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  benef_indirizzo varchar,
  benef_cap varchar,
  benef_localita varchar,
  benef_provincia varchar,
  desc_mod_pagamento varchar,
  bollo varchar,
  banca_appoggio varchar,
  banca_abi varchar,
  banca_cab varchar,
  banca_cc varchar,
  banca_cc_estero varchar,
  banca_cc_posta varchar,
  banca_cin varchar,
  banca_iban varchar,
  banca_bic varchar,
  quietanzante varchar,
  importo_irpef_imponibile numeric,
  importo_imposta numeric,
  importo_inps_inponibile numeric,
  importo_ritenuta numeric,
  importo_netto numeric,
  cup varchar,
  cig varchar,
  resp_sett_amm varchar,
  cod_tributo varchar,
  resp_amm varchar,
  tit_miss_progr varchar,
  transaz_elementare varchar,
  elenco_reversali varchar,
  split_reverse varchar,
  importo_split_reverse numeric,
  anno_primo_impegno varchar,
  display_error varchar,
  cod_stato_mandato varchar,
  banca_cc_bitalia varchar,
  tipo_doc varchar,
  num_doc_ncd varchar,
  importo_da_dedurre_ncd numeric
) AS
$body$
DECLARE
elencoMandati record;
elencoImpegni record;
elencoLiquidazioni record;
elencoOneri	record;
elencoReversali record;
elencoNoteCredito record;
elencoClass record;
elencoAttr record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
posizione integer;
cod_atto_amm VARCHAR;
appStr VARCHAR;
annoImpegno VARCHAR;
numImpegno VARCHAR;
numSubImpegno VARCHAR;
dataMandatoStr VARCHAR;
numImpegnoApp VARCHAR;
numSubImpegnoApp VARCHAR;
cod_tipo_onere VARCHAR;
subDocumento VARCHAR;
numFatturaApp VARCHAR;
ImportoApp numeric;
anno_eser_int INTEGER;
conta_mandati_succ INTEGER;
max_data_flusso TIMESTAMP;
contaReversali INTEGER;
importoReversale NUMERIC;
importoSubDoc NUMERIC;
contaRecord INTEGER;
importoDaDedurre NUMERIC;
cod_programma VARCHAR;
cod_cofog VARCHAR;
cod_trans_europea VARCHAR;
cod_v_livello VARCHAR;
ricorrente_spesa VARCHAR;
perimetro_sanitario VARCHAR;
politiche_reg_unitarie VARCHAR;
cod_siope VARCHAR;
cod_titolo VARCHAR;
cod_missione VARCHAR;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
user_table	varchar;
sqlQuery varchar;
            
BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
cod_gestione='';
num_impegno='';
num_subimpegno='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
importo_stanz_cassa=0;
importo_tot_mandati_emessi=0;
importo_tot_mandati_dopo_emiss=0;
importo_dispon=0;
nome_tesoriere='';
desc_causale='';
desc_provvedimento='';
estremi_provvedimento='';
num_fattura='';
anno_fattura=0;
importo_fattura =0;
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
benef_indirizzo='';
benef_cap='';
benef_localita='';
benef_provincia='';
desc_mod_pagamento='';
bollo='';
banca_appoggio='';
banca_abi='';
banca_cab='';
banca_cc='';
banca_cc_estero='';
banca_cc_posta='';
banca_cc_bitalia='';
banca_cin='';
banca_iban='';
banca_bic='';
quietanzante='';
importo_irpef_imponibile=0;
importo_imposta=0;
importo_inps_inponibile=0;
importo_ritenuta=0;
importo_netto=0;
cup='';
cig='';
resp_sett_amm='';
cod_tributo='';
resp_amm='';
numero_fattura_completa='';
importo_documento=0;
transaz_elementare='';
num_sub_doc_fattura=0;
tit_miss_progr='';
cod_stato_mandato='';
tipo_doc='';
num_doc_ncd='';
importo_da_dedurre_ncd=0;

elenco_reversali='';
split_reverse='';
importo_split_reverse=0;
anno_primo_impegno='';
cod_programma='';
cod_cofog='';
cod_trans_europea='';
cod_v_livello='';
ricorrente_spesa='';
perimetro_sanitario='';
politiche_reg_unitarie='';
cod_siope='';

importoSubDoc=0;

anno_eser_int=p_anno ::INTEGER;

display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND 
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A", "DATA MANDATO DA/A" e "NUMERO DISTINTA".';
    return next;
    return;
end if;

select fnc_siac_random_user()
into	user_table;

contaRecord=0;

sqlQuery='with ord as (
	select  t_ordinativo.ord_id, 
		t_ordinativo_ts.ord_ts_id ,
		t_ordinativo.ente_proprietario_id,
		t_ordinativo.ord_anno, 
        COALESCE(t_ordinativo.ord_desc,'''') ord_desc,      
          -- se l''ordinativo è annullato l''importo è 0
        case when d_ord_stato.ord_stato_code <>''A''
        	then COALESCE(t_ord_ts_det.ord_ts_det_importo,0) 
            else 0 end ord_ts_det_importo,
        t_periodo.anno anno_eser,
        t_ordinativo.ord_numero,
        t_ordinativo.ord_emissione_data,
        COALESCE(t_ordinativo.ord_cast_emessi,0) ord_cast_emessi,
        d_ord_stato.ord_stato_code,
        COALESCE(cod_bollo.codbollo_code,'''') codbollo_code, 
        case when COALESCE(cod_bollo.codbollo_desc,'''') = '''' 
        	then ''ESENTE BOLLO'' 
            ELSE  cod_bollo.codbollo_desc end codbollo_desc,
        d_distinta.dist_code
from  siac_t_bil t_bil,
    siac_t_periodo t_periodo ,
    siac_t_ordinativo_ts t_ordinativo_ts,
	siac_t_ordinativo_ts_det t_ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_d_ordinativo_tipo d_ordinativo_tipo,
	siac_t_ordinativo t_ordinativo
    	LEFT  join siac_d_codicebollo cod_bollo
            on (cod_bollo.codbollo_id =t_ordinativo.codbollo_id 
                AND cod_bollo.data_cancellazione IS NULL)
        LEFT JOIN siac_d_distinta d_distinta
                	ON (d_distinta.dist_id=t_ordinativo.dist_id
                    	AND d_distinta.data_cancellazione IS NULL),
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato d_ord_stato
       /* LEFT JOIN siac_r_ordinativo_stato r_ord_stato
            ON (r_ord_stato.ord_id=t_ordinativo.ord_id
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ord_stato.validita_fine IS NULL)
        LEFT JOIN siac_d_ordinativo_stato d_ord_stato
            ON (d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                AND d_ord_stato.data_cancellazione IS NULL)*/
where  t_bil.bil_id=t_ordinativo.bil_id
	AND t_periodo.periodo_id= t_bil.periodo_id   
	and t_ordinativo_ts.ord_id=t_ordinativo.ord_id
	and t_ord_ts_det.ord_ts_id=t_ordinativo_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id= t_ord_ts_det.ord_ts_det_tipo_id    
    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
    and r_ord_stato.ord_id=t_ordinativo.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
	and t_ordinativo.ente_proprietario_id ='||p_ente_prop_id;
    sqlQuery=sqlQuery|| ' AND t_ordinativo.ord_anno='||anno_eser_int;
    sqlQuery=sqlQuery|| ' and t_periodo.anno='''||p_anno||'''';
    if p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero between '||p_num_mandato_da;
        sqlQuery=sqlQuery|| ' and ' ||p_num_mandato_a;   
    elsif p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS  NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_mandato_da;
    elsif p_num_mandato_da IS  NULL AND p_num_mandato_a IS NOT NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_mandato_a;
    end if;  
    
    if p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') between to_timestamp('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')' || ' and to_timestamp(''' ||p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')';    	
    elsif  p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')';    
 	elsif  p_data_mandato_da IS  NULL AND p_data_mandato_a IS NOT NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')';    	        	
    end if;
    
    if p_numero_distinta IS NOT NULL AND  p_numero_distinta <>'' then 
    	sqlQuery=sqlQuery|| ' and d_distinta.dist_code='''||p_numero_distinta||'''';
    end if;
    if p_stato_mandato <> 'TT' then
    	sqlQuery=sqlQuery|| ' and d_ord_stato.ord_stato_code='''||p_stato_mandato||'''';
    end if;
    
    sqlQuery=sqlQuery|| ' AND d_ordinativo_tipo.ord_tipo_code=''P'' /* PAGAMENTO */
    AND d_ord_ts_det_tipo.ord_ts_det_tipo_code =''A'' -- Importo Attuale
    AND t_periodo.data_cancellazione IS NULL 
    AND t_bil.data_cancellazione IS NULL 
    and t_ordinativo.data_cancellazione IS NULL   
    and t_ordinativo_ts.data_cancellazione IS NULL
    and t_ord_ts_det.data_cancellazione IS NULL
    and d_ord_ts_det_tipo.data_cancellazione IS NULL
    and d_ordinativo_tipo.data_cancellazione IS NULL
    AND r_ord_stato.data_cancellazione IS NULL
    AND r_ord_stato.validita_fine IS NULL
    AND d_ord_stato.data_cancellazione IS NULL),
strut_bil as (
  select *  
      from fnc_bilr_struttura_cap_bilancio_spese ('||p_ente_prop_id||',
      		'''||p_anno||''','''||user_table||''')  ) ,
ele_cap as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code=''PROGRAMMA'' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id='||p_ente_prop_id||' 						and
   	anno_eserc.anno='''|| p_anno||'''										and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = ''CAP-UG''						     		and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	''VA''								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		--and    	
	--cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
cap as (
	select r_ordinativo_bil_elem.ord_id,
		COALESCE(a.elem_code,'''') elem_code,
        COALESCE(b.missione_code,'''') missione_code, 
        COALESCE(b.programma_code,'''') programma_code,
        COALESCE(b.titusc_code,'''') titusc_code,
        COALESCE(t_bil_elem.elem_code,'''') cod_cap, 
        COALESCE(t_bil_elem.elem_code2,'''') cod_art,
        t_bil_elem.elem_id
	from siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
        siac_t_bil_elem t_bil_elem  
        left join ele_cap a
          ON (a.elem_id=t_bil_elem.elem_id)             
      LEFT JOIN strut_bil   b 
          ON (b.programma_id = a.programma_id    
          and	b.macroag_id	= a.macroaggregato_id
          and b.ente_proprietario_id='||p_ente_prop_id;
          sqlQuery=sqlQuery|| ' and	b.ente_proprietario_id	=a.ente_proprietario_id          
          and b.utente='''|| user_table||''')';              
    sqlQuery=sqlQuery|| ' where r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id 
    	and r_ordinativo_bil_elem.ente_proprietario_id ='||p_ente_prop_id;
    	sqlQuery=sqlQuery|| ' and r_ordinativo_bil_elem.data_cancellazione IS NULL
        and t_bil_elem.data_cancellazione IS NULL),
ente as (
	select  COALESCE(OL.ente_oil_resp_ord,'''') ente_oil_resp_ord, 
        COALESCE(OL.ente_oil_tes_desc,'''') ente_oil_tes_desc, 
        COALESCE(OL.ente_oil_resp_amm,'''') ente_oil_resp_amm,  
        ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente,
        ep.ente_proprietario_id
		from siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL
    where  ep.ente_proprietario_id =OL.ente_proprietario_id
        and ep.ente_proprietario_id='||p_ente_prop_id;
        sqlQuery=sqlQuery|| ' and ep.data_cancellazione IS NULL
        and ol.data_cancellazione IS NULL) ,
doc as (
      select r_subdoc_ordinativo_ts.ord_ts_id,
          COALESCE(t_doc.doc_numero,'''') doc_numero, 
          COALESCE(t_doc.doc_anno,0) doc_anno, 
          COALESCE(t_doc.doc_importo,0) doc_importo,
          t_doc.doc_id, t_subdoc.subdoc_id,
          COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
          COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
          COALESCE(d_doc_tipo.doc_tipo_code,'''') doc_tipo_code
    from siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
            siac_t_subdoc t_subdoc,
            siac_t_doc 	t_doc
            LEFT JOIN siac_d_doc_tipo d_doc_tipo
                ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                    AND d_doc_tipo.data_cancellazione IS NULL)
    where t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
        AND t_doc.doc_id=  t_subdoc.doc_id
        and r_subdoc_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id;   
        sqlQuery=sqlQuery|| ' AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
        AND t_subdoc.data_cancellazione IS NULL
        AND t_doc.data_cancellazione IS NULL),
sogg as (
	select r_ord_soggetto.ord_id,
        COALESCE(t_soggetto.codice_fiscale,'''') codice_fiscale,
        COALESCE(t_soggetto.partita_iva,'''') partita_iva, 
        COALESCE(t_soggetto.soggetto_desc,'''') soggetto_desc,                 
        COALESCE(d_via_tipo.via_tipo_desc,'''') via_tipo_desc, COALESCE(t_ind_soggetto.toponimo,'''') toponimo, 
        COALESCE(t_ind_soggetto.numero_civico,'''') numero_civico,
        COALESCE(t_ind_soggetto.zip_code,'''') zip_code, COALESCE(t_comune.comune_desc,'''') comune_desc, 
        COALESCE(t_provincia.sigla_automobilistica,'''') sigla_automobilistica
    from  siac_r_ordinativo_soggetto r_ord_soggetto,
          siac_t_soggetto t_soggetto
            LEFT JOIN siac_t_indirizzo_soggetto t_ind_soggetto
                ON (t_ind_soggetto.soggetto_id=t_soggetto.soggetto_id
                    AND t_ind_soggetto.principale=''S''
                    AND t_ind_soggetto.data_cancellazione IS NULL)
            LEFT JOIN siac_d_via_tipo d_via_tipo
                ON (d_via_tipo.via_tipo_id=t_ind_soggetto.via_tipo_id
                    AND d_via_tipo.data_cancellazione IS NULL)
            LEFT JOIN siac_t_comune t_comune
                ON (t_comune.comune_id=t_ind_soggetto.comune_id
                    AND t_comune.data_cancellazione IS NULL)
            LEFT JOIN siac_r_comune_provincia r_comune_provincia
                ON (r_comune_provincia.comune_id=t_comune.comune_id
                    AND r_comune_provincia.data_cancellazione IS NULL)
            LEFT JOIN siac_t_provincia t_provincia
                ON (t_provincia.provincia_id=r_comune_provincia.provincia_id
                    AND t_provincia.data_cancellazione IS NULL)   
    where t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
    	and r_ord_soggetto.ente_proprietario_id='||p_ente_prop_id;                  	
        sqlQuery=sqlQuery|| ' AND t_soggetto.data_cancellazione IS NULL 
        and r_ord_soggetto.data_cancellazione IS NULL ),
attoamm as (
	select r_liquid_ord.sord_id, r_liquid_ord.liq_id,
    	t_atto_amm.attoamm_numero,t_atto_amm.attoamm_anno,
        t_atto_amm.attoamm_note attoamm_note,
    	t_atto_amm1.attoamm_numero attoamm_numero_movgest,
        t_atto_amm1.attoamm_anno attoamm_anno_movgest,
        t_atto_amm1.attoamm_note attoamm_note,
        COALESCE(t_class.classif_code,'''') strut_amm_resp,
        COALESCE(t_class1.classif_code,'''') strut_amm_resp_movgest,
        COALESCE(d_atto_amm_tipo.attoamm_tipo_code,'''') attoamm_tipo_code,
        COALESCE(d_atto_amm_tipo.attoamm_tipo_desc,'''') attoamm_tipo_desc,
        COALESCE(d_atto_amm_tipo1.attoamm_tipo_code,'''') attoamm_tipo_code_movgest,
        COALESCE(d_atto_amm_tipo1.attoamm_tipo_desc,'''') attoamm_tipo_desc_movgest
    from siac_r_liquidazione_ord r_liquid_ord                	
          LEFT JOIN siac_r_liquidazione_atto_amm r_liquid_att_amm
              ON (r_liquid_att_amm.liq_id= r_liquid_ord.liq_id
                  AND r_liquid_att_amm.data_cancellazione IS NULL)
          LEFT JOIN siac_t_atto_amm t_atto_amm
              ON (t_atto_amm.attoamm_id=r_liquid_att_amm.attoamm_id
                  AND t_atto_amm.data_cancellazione IS NULL)
          LEFT JOIN siac_d_atto_amm_tipo d_atto_amm_tipo
              ON (d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
                  AND d_atto_amm_tipo.data_cancellazione IS NULL)
          LEFT JOIN siac_r_atto_amm_class r_atto_amm_class
              ON (r_atto_amm_class.attoamm_id=t_atto_amm.attoamm_id
                  AND r_atto_amm_class.data_cancellazione IS NULL)
          LEFT JOIN siac_t_class t_class
              ON (t_class.classif_id= r_atto_amm_class.classif_id
                  AND t_class.data_cancellazione IS NULL)
          LEFT JOIN siac_d_class_tipo d_class_tipo
              ON (d_class_tipo.classif_tipo_id= t_class.classif_tipo_id
                  AND d_class_tipo.data_cancellazione IS NULL)       
          LEFT JOIN siac_r_liquidazione_movgest r_liq_movgest
              ON (r_liq_movgest.liq_id=r_liquid_ord.liq_id
                  AND  r_liq_movgest.data_cancellazione IS NULL)                                
          LEFT JOIN siac_r_movgest_ts_atto_amm  r_movgest_ts_atto_amm
              ON (r_movgest_ts_atto_amm.movgest_ts_id=r_liq_movgest.movgest_ts_id                                         
                  AND r_movgest_ts_atto_amm.data_cancellazione IS NULL) 
          LEFT JOIN siac_t_atto_amm t_atto_amm1
              ON (t_atto_amm1.attoamm_id=r_movgest_ts_atto_amm.attoamm_id
                  AND t_atto_amm1.data_cancellazione IS NULL)
          LEFT JOIN siac_d_atto_amm_tipo d_atto_amm_tipo1
              ON (d_atto_amm_tipo1.attoamm_tipo_id=t_atto_amm1.attoamm_tipo_id
                  AND d_atto_amm_tipo1.data_cancellazione IS NULL)
          LEFT JOIN siac_r_atto_amm_class r_atto_amm_class1
              ON (r_atto_amm_class1.attoamm_id=t_atto_amm1.attoamm_id
                  AND r_atto_amm_class1.data_cancellazione IS NULL)
          LEFT JOIN siac_t_class t_class1
              ON (t_class1.classif_id= r_atto_amm_class1.classif_id
                  AND t_class1.data_cancellazione IS NULL)
          LEFT JOIN siac_d_class_tipo d_class_tipo1
              ON (d_class_tipo1.classif_tipo_id= t_class1.classif_tipo_id
                  AND d_class_tipo1.data_cancellazione IS NULL) 
	where r_liquid_ord.ente_proprietario_id ='||p_ente_prop_id;
sqlQuery=sqlQuery|| ' and r_liquid_ord.data_cancellazione IS NULL),
cigord as (
		select  t_attr.attr_code attr_code_cig_ord, 
        		r_ordinativo_attr.testo testo_cig_ord,
				r_ordinativo_attr.ord_id
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id          
                  and t_attr.ente_proprietario_id='||p_ente_prop_id;         
             sqlQuery=sqlQuery|| ' AND upper(t_attr.attr_code) = ''CIG''           
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL),
cupord as (
		select  t_attr.attr_code attr_code_cup_ord, 
        		r_ordinativo_attr.testo testo_cup_ord,
				r_ordinativo_attr.ord_id
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id          
                  and t_attr.ente_proprietario_id='||p_ente_prop_id;         
             sqlQuery=sqlQuery|| ' AND upper(t_attr.attr_code) = ''CUP''            
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL),
cigliq as ( 
			SELECT t_attr.attr_code attr_code_cig_liq, 
            	r_liquidazione_attr.testo testo_cig_liq,
                r_liqu_ord.sord_id           
            FROM siac_t_liquidazione	liquidazione, 
                    siac_r_liquidazione_ord r_liqu_ord,
                    siac_r_liquidazione_attr r_liquidazione_attr,
                    siac_t_attr t_attr                                                
            WHERE liquidazione.liq_id=r_liqu_ord.liq_id
                    AND r_liquidazione_attr.liq_id=liquidazione.liq_id
                    AND t_attr.attr_id=r_liquidazione_attr.attr_id                                
                    AND upper(t_attr.attr_code) = ''CIG''  
                    /* Da usare l''ID della testata dell''ordinativo e 
                          non quello dell''ordinativo */ 
                   AND   r_liqu_ord.ente_proprietario_id='||p_ente_prop_id;  
  sqlQuery=sqlQuery|| ' AND  liquidazione.data_cancellazione IS NULL   
                   AND  r_liquidazione_attr.data_cancellazione IS NULL 
                   AND  t_attr.data_cancellazione IS NULL),
cupliq as ( 
			SELECT t_attr.attr_code attr_code_cup_liq, 
            	r_liquidazione_attr.testo testo_cup_liq,
                r_liqu_ord.sord_id           
            FROM siac_t_liquidazione	liquidazione, 
                    siac_r_liquidazione_ord r_liqu_ord,
                    siac_r_liquidazione_attr r_liquidazione_attr,
                    siac_t_attr t_attr                                                
            WHERE liquidazione.liq_id=r_liqu_ord.liq_id
                    AND r_liquidazione_attr.liq_id=liquidazione.liq_id
                    AND t_attr.attr_id=r_liquidazione_attr.attr_id                                
                    AND upper(t_attr.attr_code) = ''CUP''  
                    /* Da usare l''ID della testata dell''ordinativo e 
                          non quello dell''ordinativo */ 
                   AND   r_liqu_ord.ente_proprietario_id='||p_ente_prop_id;  
  sqlQuery=sqlQuery|| ' AND  liquidazione.data_cancellazione IS NULL   
                   AND  r_liquidazione_attr.data_cancellazione IS NULL 
                   AND  t_attr.data_cancellazione IS NULL),
  impegni as (
  	select  *
    	from fnc_bilr144_tab_impegni ('||p_ente_prop_id||')  ),
  ncd as ( 
  	select *  
    from fnc_bilr144_tab_reversali  ('||p_ente_prop_id||')  ) ,
  classif as ( 
  	select *  
    from fnc_bilr144_tab_classif  ('||p_ente_prop_id||')  )  ,
  elenco_ncd as ( 
  	select *  
    from fnc_bilr144_tab_ncd  ('||p_ente_prop_id||')  )  , 
  modpag as ( 
  	select *  
    from fnc_bilr144_tab_modpag  ('||p_ente_prop_id||')  )  ,            
importo_ncd as (
select  t_ordinativo_ts.ord_id, 
		sum(COALESCE(t_subdoc.subdoc_importo_da_dedurre,0)) 
        		subdoc_importo_da_dedurre            
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
                siac_t_subdoc t_subdoc            
            where r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id
            AND t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id             
            AND r_subdoc_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id; 
sqlQuery=sqlQuery|| ' AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL                                 
            group by t_ordinativo_ts.ord_id)                                                               			          
select 
	ente.ente_denominazione::varchar nome_ente ,
	ente.cod_fisc_ente::varchar partita_iva_ente ,
  	ord.anno_eser::integer anno_ese_finanz ,
  	ord.ord_anno::integer anno_capitolo ,
    cap.cod_cap::varchar cod_capitolo ,
    cap.cod_art::varchar cod_articolo ,
  	classif.cod_gestione::varchar ,
  	impegni.num_impegno::varchar ,
  	''''::varchar num_subimpegno ,
    ord.ord_ts_det_importo::numeric importo_lordo_mandato ,
    ord.ord_numero::integer numero_mandato ,
    ord.ord_emissione_data::date data_mandato ,
  	0::numeric importo_stanz_cassa ,
  	ord.ord_cast_emessi::numeric importo_tot_mandati_emessi ,
    (ord.ord_cast_emessi+ord.ord_ts_det_importo)::numeric importo_tot_mandati_dopo_emiss,
  	0::numeric importo_dispon ,
  	ente.ente_oil_tes_desc::varchar nome_tesoriere ,
    -- il campo desc_causale nel report è concatenato con CUP e CIG se esistenti.
  	ord.ord_desc::varchar desc_causale ,  
  case when attoamm.attoamm_tipo_code not in (''ALG'', ''SPR'')
  		then attoamm.attoamm_tipo_desc::varchar
        else attoamm.attoamm_tipo_desc_movgest::varchar end desc_provvedimento,
  case when attoamm.attoamm_tipo_code not in (''ALG'', ''SPR'')
  		then trim(attoamm.strut_amm_resp||'' N.''||attoamm.attoamm_numero||
        	'' DEL ''||attoamm.attoamm_anno)::varchar
        else trim(attoamm.strut_amm_resp_movgest||'' N.''||attoamm.attoamm_numero_movgest||
        	'' DEL ''||attoamm.attoamm_anno_movgest)::varchar end estremi_provvedimento,     
 ''''::varchar  numero_fattura_completa ,
  case when doc.doc_numero <>'''' 
  		then  (doc.doc_numero||''/''||doc.subdoc_numero)::varchar 
		else ''''::varchar  end num_fattura ,
  COALESCE(doc.doc_anno::integer,0)::integer anno_fattura ,
  COALESCE(doc.doc_importo,0)::numeric importo_documento  ,
  COALESCE(doc.subdoc_numero::integer,0)::integer  num_sub_doc_fattura,
  COALESCE(doc.subdoc_importo,0)::numeric importo_fattura ,
  	 -- carico il codice fiscale solo se non esiste la partita iva
  case when COALESCE(sogg.partita_iva,'''')=''''
  		then sogg.codice_fiscale::varchar
        else ''''::varchar end benef_cod_fiscale,        
   sogg.partita_iva::varchar benef_partita_iva,
   sogg.soggetto_desc::varchar benef_nome ,
     upper(sogg.via_tipo_desc||'' ''||sogg.toponimo||'' ''||
    		sogg.numero_civico)::varchar benef_indirizzo     ,
    sogg.zip_code::varchar benef_cap ,        
    sogg.comune_desc::varchar benef_localita,
    sogg.sigla_automobilistica::varchar benef_provincia,  
  	modpag.desc_mod_pagamento::varchar ,
    ord.codbollo_desc::varchar bollo ,
   	''''::varchar banca_appoggio ,
    modpag.banca_abi::varchar ,
    modpag.banca_cab::varchar ,
    modpag.banca_cc::varchar ,
    modpag.banca_cc_estero::varchar ,
    modpag.banca_cc_posta::varchar ,
    modpag.banca_cin::varchar ,
    modpag.banca_iban::varchar ,
    modpag.banca_bic::varchar ,
  	 case when modpag.quietanziante_codice_fiscale=''''
     		then modpag.quietanziante::varchar
            else (modpag.quietanziante_codice_fiscale||
      	'' - '' ||modpag.quietanziante)::varchar end quietanzante ,      
  COALESCE(ncd.importo_irpef_imponibile,0)::numeric importo_irpef_imponibile ,
  COALESCE(ncd.importo_imposta,0)::numeric importo_imposta ,
  COALESCE(ncd.importo_inps_inponibile,0)::numeric importo_inps_inponibile ,
  COALESCE(ncd.importo_ritenuta,0::numeric) importo_ritenuta ,
  (COALESCE(ord.ord_ts_det_importo,0)-
    	COALESCE(ncd.importo_ritenuta,0)-
        COALESCE(ncd.importo_imposta,0)-
        COALESCE(ncd.importo_split_reverse,0))::numeric importo_netto,    
  case when COALESCE(cupord.attr_code_cup_ord,'''')='''' or COALESCE(cupord.testo_cup_ord,'''')=''''  
        	then COALESCE(cupliq.testo_cup_liq,'''')::varchar
            else cupord.testo_cup_ord::varchar end cup , 
  case when COALESCE(cigord.attr_code_cig_ord,'''')='''' or COALESCE(cigord.testo_cig_ord,'''')='''' 
        	then COALESCE(cigliq.testo_cig_liq,'''')::varchar 
            else cigord.testo_cig_ord::varchar end cig,
  ente.ente_oil_resp_ord::varchar resp_sett_amm ,
  COALESCE(ncd.cod_tributo,'''')::varchar cod_tributo,
  ente.ente_oil_resp_amm::varchar resp_amm ,
  (cap.programma_code||cap.titusc_code)::varchar tit_miss_progr ,
  case when COALESCE(cupord.attr_code_cup_ord,'''')='''' or COALESCE(cupord.testo_cup_ord,'''')=''''  
        	then (cap.programma_code||classif.cod_v_livello||classif.cod_cofog||
  	classif.cod_trans_europea||classif.cod_siope||COALESCE(cupliq.testo_cup_liq,'''')
    	||classif.ricorrente_spesa||classif.perimetro_sanitario
        ||classif.politiche_reg_unitarie)::varchar
            else (cap.programma_code||classif.cod_v_livello||classif.cod_cofog||
  	classif.cod_trans_europea||classif.cod_siope||COALESCE(cupord.testo_cup_ord,'''')
    	||classif.ricorrente_spesa||classif.perimetro_sanitario
        ||classif.politiche_reg_unitarie)::varchar
    	end   transaz_elementare ,
  COALESCE(ncd.elenco_reversali,'''')::varchar elenco_reversali,
  COALESCE(ncd.split_reverse,'''')::varchar split_reverse ,
  COALESCE(ncd.importo_split_reverse,0)::numeric importo_split_reverse , 
  COALESCE(impegni.anno_primo_impegno,'''')::varchar  anno_primo_impegno ,
  ''''::varchar display_error ,
  upper(ord.ord_stato_code)::varchar cod_stato_mandato,
  modpag.banca_cc_bitalia::varchar ,
  COALESCE(doc.doc_tipo_code,'''')::varchar tipo_doc ,
  COALESCE(elenco_ncd.num_doc_ncd,'''')::varchar num_doc_ncd,   
  COALESCE(importo_ncd.subdoc_importo_da_dedurre,0)::numeric importo_da_dedurre_ncd    
	from ord
        left join doc on ord.ord_ts_id=doc.ord_ts_id
        left join elenco_ncd on doc.doc_id=elenco_ncd.doc_id        
        left join sogg on ord.ord_id=sogg.ord_id       
        left join attoamm on ord.ord_ts_id= attoamm.sord_id
        left join cigord on ord.ord_id= cigord.ord_id
        left join cupord on ord.ord_id= cupord.ord_id
        left join cigliq on ord.ord_ts_id= cigliq.sord_id
        left join cupliq on ord.ord_ts_id= cupliq.sord_id
        left join impegni on ord.ord_id= impegni.ord_id 
        left join ncd on ord.ord_id= ncd.ord_id 
        left join classif on ord.ord_id= classif.ord_id
        left join importo_ncd on ord.ord_id= importo_ncd.ord_id 
        left join modpag on ord.ord_id= modpag.ord_id ,
        cap, ente
where ord.ord_id=cap.ord_id
	and ord.ente_proprietario_id=ente.ente_proprietario_id
order by ord.ord_numero, ord.ord_emissione_data, 
doc_numero, subdoc_numero';

raise notice 'Query = %', sqlQuery;

return query execute sqlQuery;


exception
	when no_data_found THEN
		raise notice 'Nessun mandato trovato' ;
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