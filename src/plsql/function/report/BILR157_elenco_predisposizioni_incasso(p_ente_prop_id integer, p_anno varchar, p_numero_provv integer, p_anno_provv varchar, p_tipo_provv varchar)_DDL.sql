/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR157_elenco_predisposizioni_incasso" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  anno_mov integer,
  numero_mov integer,
  desc_soggetto varchar,
  numero_predisp varchar,
  periodo_comp varchar,
  importo_predisp numeric,
  tipo_predoc varchar,
  doc_anno integer,
  doc_numero varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 

BEGIN

anno_eser_int=p_anno ::INTEGER;


RTN_MESSAGGIO:='Estrazione dei dati delle predisposizioni di incasso ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select t_movgest.movgest_anno::integer anno_mov, 
	t_movgest.movgest_numero::integer numero_mov,
    CASE WHEN COALESCE(t_predoc_anagr.predocan_ragione_sociale,'') = ''
    	THEN trim(COALESCE(t_predoc_anagr.predocan_cognome,'') || ' ' ||
        		COALESCE(t_predoc_anagr.predocan_nome,''))::varchar
        ELSE t_predoc_anagr.predocan_ragione_sociale::varchar end desc_soggetto,
	t_predoc.predoc_numero::varchar numero_predisp, 
    t_predoc.predoc_periodo_competenza::varchar periodo_comp,
    t_predoc.predoc_importo::numeric importo_predisp,    
    d_doc_fam_tipo.doc_fam_tipo_code::varchar tipo_predoc,
    COALESCE(t_doc.doc_anno,0)::integer doc_anno,
    COALESCE(t_doc.doc_numero,'')::varchar doc_numero
from siac_t_predoc t_predoc
			/* 06/06/2017: estratti anche i dati del documento
            	collegato */
		LEFT JOIN siac_r_predoc_subdoc r_predoc_subdoc
        	ON (r_predoc_subdoc.predoc_id=t_predoc.predoc_id
            	AND r_predoc_subdoc.data_cancellazione IS NULL)
        LEFT JOIN siac_t_subdoc t_subdoc
        	ON (t_subdoc.subdoc_id=r_predoc_subdoc.subdoc_id
            	AND t_subdoc.data_cancellazione IS NULL)
        LEFT JOIN siac_t_doc t_doc
        	ON (t_doc.doc_id=t_subdoc.doc_id
            	AND t_doc.data_cancellazione IS NULL)
        LEFT JOIN siac_r_predoc_movgest_ts r_predoc_movgest_ts
        	ON (r_predoc_movgest_ts.predoc_id=t_predoc.predoc_id
            	AND r_predoc_movgest_ts.data_cancellazione IS NULL)
            /* 06/06/2017: messo in LEFT JOIN il collegamento con il
            	movimento in modo da stamapre anche i predoc che non hanno
                un movimento collegato */
    	LEFT JOIN siac_t_movgest_ts t_movgest_ts
			ON (t_movgest_ts.movgest_ts_id=r_predoc_movgest_ts.movgest_ts_id
            	AND t_movgest_ts.data_cancellazione IS NULL)
        LEFT JOIN siac_t_movgest t_movgest
			ON (t_movgest.movgest_id=t_movgest_ts.movgest_id
            	AND t_movgest.data_cancellazione IS NULL),
	siac_r_predoc_atto_amm r_predoc_atto_amm,
    siac_d_doc_fam_tipo d_doc_fam_tipo,    
    siac_r_predoc_stato r_predoc_stato,
    siac_d_predoc_stato d_predoc_stato,
    siac_t_predoc_anagr t_predoc_anagr,
    siac_t_atto_amm t_atto_amm,
    siac_d_atto_amm_tipo d_atto_amm_tipo    
where t_predoc.predoc_id=r_predoc_atto_amm.predoc_id
and t_predoc.doc_fam_tipo_id=d_doc_fam_tipo.doc_fam_tipo_id
and r_predoc_stato.predoc_id=t_predoc.predoc_id
and d_predoc_stato.predoc_stato_id=r_predoc_stato.predoc_stato_id
and t_predoc_anagr.predoc_id=t_predoc.predoc_id
and t_atto_amm.attoamm_id=r_predoc_atto_amm.attoamm_id
and d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
and t_predoc.ente_proprietario_id=p_ente_prop_id
and d_predoc_stato.predoc_stato_code <> 'A'
AND t_atto_amm.attoamm_numero=p_numero_provv
AND t_atto_amm.attoamm_anno=p_anno_provv
AND d_atto_amm_tipo.attoamm_tipo_code=p_tipo_provv
and t_predoc.data_cancellazione is null
and r_predoc_atto_amm.data_cancellazione is null
and d_doc_fam_tipo.data_cancellazione is null
and t_predoc_anagr.data_cancellazione is null
and r_predoc_stato.data_cancellazione is null
and d_predoc_stato.data_cancellazione is null
and t_atto_amm.data_cancellazione is null
and d_atto_amm_tipo.data_cancellazione is null;

RTN_MESSAGGIO:='Estrazione dei dati delle predisposizioni di incasso ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;


exception
	when no_data_found THEN
		raise notice 'Nessuna predisposizioni trovata' ;
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