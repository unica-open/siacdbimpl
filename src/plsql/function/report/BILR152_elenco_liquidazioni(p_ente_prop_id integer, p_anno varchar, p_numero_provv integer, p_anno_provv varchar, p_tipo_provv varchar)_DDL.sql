/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_liquidazioni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  cup varchar,
  cig varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  tipo varchar,
  tipo_finanz varchar,
  conto_dare varchar,
  conto_avere varchar,
  importo_liquidazione numeric,
  code_cofog varchar,
  code_programma varchar,
  anno_mandato integer,
  numero_mandato numeric,
  code_stato_mandato varchar,
  desc_stato_mandato varchar,
  code_soggetto_mandato varchar,
  desc_soggetto_mandato varchar,
  code_modpag_mandato varchar,
  desc_modpag_mandato varchar,
  importo_mandato numeric,
  pdce_v varchar,
  trans_eu varchar,
  ricorrente varchar,
  desc_motiv_assenza_siope varchar,
  code_motiv_assenza_siope varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
sqlQuery varchar;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
num_liquidazione:='';
anno_liquidazione:=0;
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
code_soggetto:='';
desc_soggetto:=0;
tipo:='';
tipo_finanz:='';
conto_dare:='';
conto_avere:='';
importo_liquidazione:=0;
code_programma:='';
code_cofog:='';
cup:='';
cig:='';
anno_mandato:=0;
numero_mandato:=0;
code_stato_mandato:='';
desc_stato_mandato:='';
code_soggetto_mandato:='';
desc_soggetto_mandato:='';
code_modpag_mandato:='';
desc_modpag_mandato:='';
importo_mandato:=0;
pdce_v:='';
trans_eu:='';
ricorrente :='';

anno_eser_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
	-- 14/12/2017: SIAC-5656.
    --	Aggiunte tabelle per testare lo stato della liquidazione in modo
    --	da escludere quelle annullate.
 with liquidazioni as (
 			  select t_liquidazione.liq_anno,
              t_liquidazione.liq_numero,
              t_liquidazione.liq_id,       
              t_liquidazione.liq_importo,
              d_siope_ass_motiv.siope_assenza_motivazione_desc,
              d_siope_ass_motiv.siope_assenza_motivazione_code
           from  siac_t_liquidazione t_liquidazione
           			LEFT JOIN siac_d_siope_assenza_motivazione d_siope_ass_motiv
                      ON (d_siope_ass_motiv.siope_assenza_motivazione_id =t_liquidazione.siope_assenza_motivazione_id
                          AND d_siope_ass_motiv.data_cancellazione IS NULL),     
           		siac_r_liquidazione_atto_amm r_liq_atto_amm ,    
                siac_t_atto_amm t_atto_amm  ,
                siac_d_atto_amm_tipo	tipo_atto,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_r_liquidazione_stato r_liq_stato,
                siac_d_liquidazione_stato d_liq_stato
          where t_liquidazione.liq_id=   r_liq_atto_amm.liq_id
          		AND t_atto_amm.attoamm_id=r_liq_atto_amm.attoamm_id
                AND t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
                AND t_bil.bil_id=t_liquidazione.bil_id
                AND t_periodo.periodo_id=t_bil.periodo_id
                AND r_liq_stato.liq_id = t_liquidazione.liq_id
                AND r_liq_stato.liq_stato_id=d_liq_stato.liq_stato_id
               	AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               	AND t_atto_amm.attoamm_numero=p_numero_provv
                AND t_atto_amm.attoamm_anno=p_anno_provv
                AND tipo_atto.attoamm_tipo_code=p_tipo_provv
                AND t_periodo.anno=p_anno
                AND d_liq_stato.liq_stato_code <> 'A'
                AND r_liq_stato.validita_fine IS NULL
                AND t_liquidazione.data_cancellazione IS NULL
                AND r_liq_atto_amm.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL
                AND tipo_atto.data_cancellazione IS NULL
                AND t_bil.data_cancellazione IS NULL
                AND t_periodo.data_cancellazione IS NULL
                AND r_liq_stato.data_cancellazione IS NULL
                AND d_liq_stato.data_cancellazione IS NULL),
 impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		r_liq_movgest_ts.liq_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,        
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato ,
                siac_r_liquidazione_movgest r_liq_movgest_ts
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	               
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_liq_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_liq_movgest_ts.data_cancellazione IS NULL),
	soggetto_liq as (
    		SELECT r_liq_sog.liq_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_liquidazione_soggetto r_liq_sog,
                siac_t_soggetto t_soggetto
            WHERE r_liq_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_liq_sog.data_cancellazione IS NULL) ,         	 
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL),
elenco_pdce_finanz as (        
SELECT  r_bil_elem_class.elem_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                 and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,
        elenco_attrib as(
        	select * from "fnc_bilr152_tab_attrib"(p_ente_prop_id))  ,
        programma as (
        	select t_programma.programma_code,
            	r_movgest_ts_prog.movgest_ts_id
            from siac_r_movgest_ts_programma     r_movgest_ts_prog,
            	siac_t_programma t_programma
            where r_movgest_ts_prog.programma_id= t_programma.programma_id
            	and r_movgest_ts_prog.ente_proprietario_id=p_ente_prop_id
            	and t_programma.data_cancellazione is null
                and r_movgest_ts_prog.data_cancellazione is null) ,
        tipo_finanz_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='TIPO_FINANZIAMENTO' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),
        cofog_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='GRUPPO_COFOG' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ), 
        programma_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='PROGRAMMA' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),                                        
  elencocig as (
  				select  t_attr.attr_code attr_code_cig, 
                  r_liq_attr.testo testo_cig,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                    siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                    and t_attr.ente_proprietario_id=p_ente_prop_id        
                	AND upper(t_attr.attr_code) = 'CIG'          
                    and r_liq_attr.data_cancellazione IS NULL
                    and t_attr.data_cancellazione IS NULL),
    elencocup as (
    			select  t_attr.attr_code attr_code_cup, 
                  r_liq_attr.testo testo_cup,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                       siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                        and t_attr.ente_proprietario_id=p_ente_prop_id  
                        AND upper(t_attr.attr_code) = 'CUP'          
                        and r_liq_attr.data_cancellazione IS NULL
                        and t_attr.data_cancellazione IS NULL),
  	elenco_mandati as (    			
        SELECT r_liq_ord.liq_id,
        	t_ord.ord_anno, t_ord.ord_numero,
            d_ord_stato.ord_stato_code, d_ord_stato.ord_stato_desc,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_code,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_code,'') end code_pagamento,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_desc,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_desc,'') end desc_pagamento,
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,
            t_ord_ts_det.ord_ts_det_importo
        FROM siac_r_liquidazione_ord r_liq_ord,
            siac_t_ordinativo_ts t_ord_ts,
            siac_t_ordinativo_ts_det t_ord_ts_det,
            siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
            siac_t_ordinativo t_ord,
            siac_r_ordinativo_stato r_ord_stato,
            siac_d_ordinativo_stato d_ord_stato,
            siac_r_ordinativo_modpag r_ord_modpag
            LEFT JOIN siac_t_modpag t_modpag 
                    ON (t_modpag.modpag_id=r_ord_modpag.modpag_id
                        AND t_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo 
              ON (d_accredito_tipo.accredito_tipo_id=t_modpag.accredito_tipo_id
                  AND d_accredito_tipo.data_cancellazione IS NULL) 
            /* in caso di cessione di incasso su siac_r_ordinativo_modpag
            non e' valorizzata la modalita' di pagamento.
            Devo cercare quella del soggetto a cui e' stato ceduto l'incasso. */
            LEFT JOIN  siac_r_soggrel_modpag r_sogg_modpag
                ON (r_ord_modpag.soggetto_relaz_id=r_sogg_modpag.soggetto_relaz_id
                    AND r_sogg_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_t_modpag t_modpag1 
                ON (t_modpag1.modpag_id=r_sogg_modpag.modpag_id
                    AND t_modpag1.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo1 
                ON (d_accredito_tipo1.accredito_tipo_id=t_modpag1.accredito_tipo_id
                    AND d_accredito_tipo1.data_cancellazione IS NULL),
            siac_d_ordinativo_tipo d_ord_tipo ,
            siac_r_ordinativo_soggetto r_ord_soggetto,
            siac_t_soggetto t_soggetto
        WHERE r_liq_ord.sord_id=t_ord_ts.ord_ts_id
            AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
            AND t_ord.ord_id=t_ord_ts.ord_id
            AND r_ord_stato.ord_id=t_ord.ord_id
            AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND r_ord_modpag.ord_id=t_ord.ord_id
            AND d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
            AND r_ord_soggetto.ord_id=t_ord.ord_id
            AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
            AND r_liq_ord.ente_proprietario_id=p_ente_prop_id
            AND d_ord_tipo.ord_tipo_code='P' --Pagamento
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_code='A' -- importo Attuale
            AND d_ord_stato.ord_stato_code <> 'A' --Annullato
            AND r_liq_ord.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND d_ord_ts_det_tipo.data_cancellazione IS NULL
            AND t_ord.data_cancellazione IS NULL
            AND r_ord_modpag.data_cancellazione IS NULL 
            AND d_ord_tipo.data_cancellazione IS NULL
            AND r_ord_soggetto.data_cancellazione IS NULL
            AND t_soggetto.data_cancellazione IS NULL
            AND r_ord_stato.data_cancellazione IS NULL
            AND d_ord_stato.data_cancellazione IS NULL
            AND r_ord_stato.validita_fine IS NULL)   ,
conto_integrato as (    	
      select distinct t_liq.liq_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_liquidazione t_liq,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_liq.liq_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_liq.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='L' --Liquidazione 
          and r_ev_reg_movfin.data_cancellazione is null
          and t_liq.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null ) ,
      /* 12/06/2017: aggiunta la gestione delle classificazioni dell
      	liquidazioni */
	elenco_class_liq as (select *
    			from "fnc_bilr152_tab_class_liquid"(p_ente_prop_id))                                                   
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    liquidazioni.liq_numero::varchar num_liquidazione,
    liquidazioni.liq_anno::integer anno_liquidazione,
    COALESCE(impegni.movgest_numero,0)::numeric num_impegno,
    COALESCE(impegni.movgest_anno,0)::integer anno_impegno,
    COALESCE(impegni.movgest_ts_code,'')::varchar num_subimpegno,
    COALESCE(elencocup.testo_cup,'')::varchar cup,
    COALESCE(elencocig.testo_cig,'')::varchar cig,
    COALESCE(soggetto_liq.soggetto_code,'')::varchar code_soggetto,
	COALESCE(soggetto_liq.soggetto_desc,'')::varchar desc_soggetto,
   -- CASE WHEN upper(COALESCE(elenco_attrib.flag_prenotazione,'')) = 'S'
    --	THEN 'PR'::varchar 
     --   ELSE impegni.tipo_impegno::varchar  end tipo,
    'LIQ'::varchar tipo,
    COALESCE(tipo_finanz_cap.classif_code,'')::varchar tipo_finanz,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
	liquidazioni.liq_importo::numeric importo_liquidazione,
    COALESCE(cofog_cap.classif_code,'')::varchar code_cofog,
    COALESCE(programma_cap.classif_code,'')::varchar code_programma,
    COALESCE(elenco_mandati.ord_anno,0)::integer anno_mandato,
    COALESCE(elenco_mandati.ord_numero,0)::numeric numero_mandato,
	COALESCE(elenco_mandati.ord_stato_code,'')::varchar code_stato_mandato,
	COALESCE(elenco_mandati.ord_stato_desc,'')::varchar desc_stato_mandato,
	COALESCE(elenco_mandati.soggetto_code,'')::varchar code_soggetto_mandato,
    COALESCE(elenco_mandati.soggetto_desc,'')::varchar desc_soggetto_mandato,
	COALESCE(elenco_mandati.code_pagamento,'')::varchar code_modpag_mandato,
    COALESCE(elenco_mandati.desc_pagamento,'')::varchar desc_modpag_mandato,
	COALESCE(elenco_mandati.ord_ts_det_importo,0)::numeric importo_mandato,
    COALESCE(elenco_class_liq.pdc_v,'')::varchar pdce_v,
    COALESCE(elenco_class_liq.code_transaz_ue,'')::varchar trans_eu,
    COALESCE(elenco_class_liq.ricorrente_spesa,'')::varchar ricorrente,
    COALESCE(liquidazioni.siope_assenza_motivazione_desc)::varchar desc_motiv_assenza_siope,
    COALESCE(liquidazioni.siope_assenza_motivazione_code)::varchar code_motiv_assenza_siope
FROM liquidazioni
	LEFT JOIN impegni on impegni.liq_id=liquidazioni.liq_id
	LEFT JOIN soggetto_liq on soggetto_liq.liq_id=liquidazioni.liq_id
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.elem_id = capitoli.elem_id 
    LEFT join elenco_attrib on elenco_attrib.movgest_ts_id = impegni.movgest_ts_id
    LEFT join programma on programma.movgest_ts_id = impegni.movgest_ts_id
    LEFT join tipo_finanz_cap on tipo_finanz_cap.elem_id = capitoli.elem_id 
    LEFT join elencocig on elencocig.liq_id=liquidazioni.liq_id  
    LEFT join elencocup on elencocup.liq_id=liquidazioni.liq_id  
    LEFT join cofog_cap on cofog_cap.elem_id = capitoli.elem_id
    LEFT join programma_cap on programma_cap.elem_id = capitoli.elem_id 
    LEFT JOIN elenco_mandati on elenco_mandati.liq_id=liquidazioni.liq_id 
    LEFT JOIN conto_integrato on conto_integrato.liq_id=liquidazioni.liq_id   
    LEFT JOIN elenco_class_liq on elenco_class_liq.liquid_id=liquidazioni.liq_id                 
ORDER BY anno_impegno, num_impegno, tipo, num_subimpegno) query_totale;

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