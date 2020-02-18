/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR100_elenco_documenti_non_contabilizzati" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_tipologia_doc varchar,
  p_cod_tipo_doc_e varchar,
  p_cod_tipo_doc_s varchar,
  p_stato_doc varchar,
  p_num_doc varchar,
  p_data_da date,
  p_data_a date,
  p_cod_soggetto varchar
)
RETURNS TABLE (
  nome_ente varchar,
  anno_documento integer,
  numero_documento varchar,
  tipo_documento varchar,
  descrizione_documento varchar,
  data_emissione timestamp,
  stato_documento varchar,
  stato_documento_desc varchar,
  tipologia_documento varchar,
  tipologia_documento_desc varchar,
  soggetto varchar,
  soggetto_desc varchar,
  importo numeric
) AS
$body$
DECLARE

 elencoDocE record;
 elencoDocS record;

BEGIN

nome_ente := '';
anno_documento := NULL;
numero_documento := '';
tipo_documento := '';
descrizione_documento := '';
data_emissione := NULL;
stato_documento := '';
stato_documento_desc := ''; 
tipologia_documento := ''; 
tipologia_documento_desc := ''; 
soggetto := '';
soggetto_desc := '';
importo := 0;
  
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati dei documenti non contabilizzati ';

 IF p_tipologia_doc IN ('E','T') THEN
    for elencoDocE IN
    SELECT tep.ente_denominazione,
           td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_data_emissione,
           dds.doc_stato_code, dds.doc_stato_desc,
           ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, 
           ddt.doc_tipo_code, 
           ts.soggetto_code, ts.soggetto_desc
    FROM siac.siac_t_doc td
    INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                                 AND tep.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                       AND ddt.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id                                             
                                            AND ddft.data_cancellazione IS NULL                                                                                   
    /* 06/10/2016: aggiunto legame con la tabella degli attributi per filtrare 
    	quelli con flagAttivaGEN valorizzato */
    INNER JOIN siac.siac_r_doc_tipo_attr r_doc_fam_tipo ON (r_doc_fam_tipo.doc_tipo_id=ddt.doc_tipo_id
    										AND r_doc_fam_tipo.boolean = 'S'
    										AND r_doc_fam_tipo.data_cancellazione IS NULL)
    INNER JOIN  siac.siac_t_attr     t_attr ON (t_attr.attr_id   =r_doc_fam_tipo.attr_id                             
    										AND t_attr.attr_code='flagAttivaGEN' 
    										AND t_attr.data_cancellazione IS NULL)
    LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id                                        
                                        AND rds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id                                        
                                        AND dds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id                                       
                                       AND srds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id                                      
                                      AND ts.data_cancellazione IS NULL
    WHERE tep.ente_proprietario_id = p_ente_prop_id
    AND td.doc_anno = p_anno::integer
    --AND (ddft.doc_fam_tipo_code = 'E' OR p_tipologia_doc = 'T')
    AND ddft.doc_fam_tipo_code = 'E'
    AND dds.doc_stato_code <> 'A'
    AND td.doc_contabilizza_genpcc = 'FALSE' 
    AND (ddt.doc_tipo_code = p_cod_tipo_doc_e OR p_cod_tipo_doc_e  = 'T')
    AND (dds.doc_stato_code = p_stato_doc OR p_stato_doc = 'T')    
    AND (td.doc_numero = COALESCE(p_num_doc, td.doc_numero) OR p_num_doc = '')
    AND (ts.soggetto_code = COALESCE(p_cod_soggetto, ts.soggetto_code) OR p_cod_soggetto = '')
    AND to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy') BETWEEN COALESCE(p_data_da, to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy')) AND COALESCE(p_data_a, to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy'))
    AND td.data_cancellazione IS NULL    
    
    LOOP

        nome_ente := elencoDocE.ente_denominazione;
        anno_documento := elencoDocE.doc_anno;
        numero_documento := elencoDocE.doc_numero;
        tipo_documento := elencoDocE.doc_tipo_code;
        descrizione_documento := elencoDocE.doc_desc;
        data_emissione := elencoDocE.doc_data_emissione;
        stato_documento := elencoDocE.doc_stato_code;
        stato_documento_desc := elencoDocE.doc_stato_desc;
        tipologia_documento := elencoDocE.doc_fam_tipo_code; 
        tipologia_documento_desc := elencoDocE.doc_fam_tipo_desc;        
        soggetto := elencoDocE.soggetto_code;
        soggetto_desc := elencoDocE.soggetto_desc;
        importo := elencoDocE.doc_importo;
        
        return next;        
                
        nome_ente := '';
        anno_documento := NULL;
        numero_documento := '';
        tipo_documento := '';
        descrizione_documento := '';
        data_emissione := NULL;
        stato_documento := '';
        stato_documento_desc := ''; 
        tipologia_documento := ''; 
        tipologia_documento_desc := ''; 
        soggetto := '';
        soggetto_desc := '';
        importo := 0;

	END LOOP;
END IF;

 IF p_tipologia_doc IN ('S','T') THEN
    for elencoDocS IN
    SELECT tep.ente_denominazione,
           td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_data_emissione,
           dds.doc_stato_code, dds.doc_stato_desc,
           ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, 
           ddt.doc_tipo_code, 
           ts.soggetto_code, ts.soggetto_desc
    FROM siac.siac_t_doc td
    INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                                 AND tep.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                       AND ddt.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id                                             
                                            AND ddft.data_cancellazione IS NULL                                                                                   
        /* 06/10/2016: aggiunto legame con la tabella degli attributi per filtrare 
    	quelli con flagAttivaGEN valorizzato */
	INNER JOIN siac.siac_r_doc_tipo_attr r_doc_fam_tipo ON (r_doc_fam_tipo.doc_tipo_id=ddt.doc_tipo_id
    										AND r_doc_fam_tipo.boolean = 'S'
    										AND r_doc_fam_tipo.data_cancellazione IS NULL)
    INNER JOIN  siac.siac_t_attr     t_attr ON (t_attr.attr_id   =r_doc_fam_tipo.attr_id  
    										AND t_attr.attr_code='flagAttivaGEN'                           
    										AND t_attr.data_cancellazione IS NULL)                                            
    LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id                                        
                                        AND rds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id                                        
                                        AND dds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id                                       
                                       AND srds.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id                                      
                                      AND ts.data_cancellazione IS NULL
    WHERE tep.ente_proprietario_id = p_ente_prop_id
    AND td.doc_anno = p_anno::integer
    --AND (ddft.doc_fam_tipo_code = 'S' OR p_tipologia_doc = 'T')
    AND ddft.doc_fam_tipo_code = 'S'
    AND dds.doc_stato_code <> 'A'
    AND td.doc_contabilizza_genpcc = 'FALSE' 
    AND (ddt.doc_tipo_code = p_cod_tipo_doc_s OR p_cod_tipo_doc_s  = 'T')
    AND (dds.doc_stato_code = p_stato_doc OR p_stato_doc = 'T')    
    AND (td.doc_numero = COALESCE(p_num_doc, td.doc_numero) OR p_num_doc = '')
    AND (ts.soggetto_code = COALESCE(p_cod_soggetto, ts.soggetto_code) OR p_cod_soggetto = '')
    AND to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy') BETWEEN COALESCE(p_data_da, to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy')) AND COALESCE(p_data_a, to_date(to_char(td.doc_data_emissione ,'dd/mm/yyyy') ,'dd/mm/yyyy'))
    AND td.data_cancellazione IS NULL    
    
    LOOP

        nome_ente := elencoDocS.ente_denominazione;
        anno_documento := elencoDocS.doc_anno;
        numero_documento := elencoDocS.doc_numero;
        tipo_documento := elencoDocS.doc_tipo_code;
        descrizione_documento := elencoDocS.doc_desc;
        data_emissione := elencoDocS.doc_data_emissione;
        stato_documento := elencoDocS.doc_stato_code;
        stato_documento_desc := elencoDocS.doc_stato_desc;
        tipologia_documento := elencoDocS.doc_fam_tipo_code; 
        tipologia_documento_desc := elencoDocS.doc_fam_tipo_desc;        
        soggetto := elencoDocS.soggetto_code;
        soggetto_desc := elencoDocS.soggetto_desc;
        importo := elencoDocS.doc_importo;
        
        return next;        
                
        nome_ente := '';
        anno_documento := NULL;
        numero_documento := '';
        tipo_documento := '';
        descrizione_documento := '';
        data_emissione := NULL;
        stato_documento := '';
        stato_documento_desc := ''; 
        tipologia_documento := ''; 
        tipologia_documento_desc := ''; 
        soggetto := '';
        soggetto_desc := '';
        importo := 0;

	END LOOP;
END IF;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati dei documenti non contabilizzati non trovati.' ;
		--return next;
	when others  THEN
		
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'DOCUMENTI NON CONTABILIZZATI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;