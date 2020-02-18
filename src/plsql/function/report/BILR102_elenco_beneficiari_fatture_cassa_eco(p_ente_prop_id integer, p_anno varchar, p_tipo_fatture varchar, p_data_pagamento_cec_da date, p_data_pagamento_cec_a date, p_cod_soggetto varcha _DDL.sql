/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR102_elenco_beneficiari_fatture_cassa_eco" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_tipo_fatture varchar,
  p_data_pagamento_cec_da date,
  p_data_pagamento_cec_a date,
  p_cod_soggetto varchar
)
RETURNS TABLE (
  nome_ente varchar,
  cod_soggetto varchar,
  desc_soggetto varchar,
  anno_doc integer,
  numero_doc varchar,
  numero_subdoc integer,
  desc_subdoc varchar,
  flag_pagato boolean,
  numero_movimento integer,
  data_pagamento_cec date,
  anno_bilancio varchar,
  desc_stato_doc varchar
) AS
$body$
DECLARE

 elencoBen record;
 elencoBenFattPag record;
 
BEGIN

nome_ente := '';
cod_soggetto := '';
desc_soggetto := '';
numero_doc := '';
anno_doc := NULL;
numero_subdoc := NULL;
desc_subdoc := '';
--flag_pagato := '';
numero_movimento := NULL;
data_pagamento_cec := NULL;
anno_bilancio := NULL;
desc_stato_doc := NULL;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati dei beneficiari delle fatture pagate in cassa economale';

IF p_tipo_fatture IN ('NP','T') THEN

    FOR elencoBen IN
    SELECT tep.ente_denominazione,
           sts.soggetto_code,
           sts.soggetto_desc,
           td.doc_anno,
           td.doc_numero,
           ts.subdoc_numero,
           ts.subdoc_desc,
           ts.subdoc_pagato_cec,
           ts.subdoc_data_pagamento_cec,
           ts.subdoc_id,
           dds.doc_stato_desc
    FROM       siac_t_soggetto sts
    INNER JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id = sts.ente_proprietario_id    
    LEFT JOIN  siac_r_doc_sog rds ON rds.soggetto_id = sts.soggetto_id AND rds.data_cancellazione IS NULL 
    LEFT JOIN  siac_t_doc td ON td.doc_id = rds.doc_id AND td.data_cancellazione IS NULL
    LEFT JOIN  siac_r_doc_stato srds ON srds.doc_id = td.doc_id  AND srds.data_cancellazione IS NULL  
    LEFT JOIN  siac_d_doc_stato dds ON dds.doc_stato_id = srds.doc_stato_id AND dds.data_cancellazione IS NULL  
    LEFT JOIN  siac_t_subdoc ts ON ts.doc_id = td.doc_id AND ts.data_cancellazione IS NULL 
    WHERE sts.ente_proprietario_id = p_ente_prop_id
    AND   td.doc_collegato_cec = 'TRUE'
    AND  (sts.soggetto_code = COALESCE(p_cod_soggetto, sts.soggetto_code) OR p_cod_soggetto = '')
    AND   ts.subdoc_pagato_cec = 'FALSE'    
    AND   sts.data_cancellazione IS NULL
    AND   tep.data_cancellazione IS NULL      
    ORDER BY sts.soggetto_code, td.doc_numero, ts.subdoc_numero
    
      LOOP
        nome_ente        := elencoBen.ente_denominazione;
        cod_soggetto     := elencoBen.soggetto_code;
        desc_soggetto    := elencoBen.soggetto_desc;
        anno_doc         := elencoBen.doc_anno;
        numero_doc       := elencoBen.doc_numero;
        numero_subdoc    := elencoBen.subdoc_numero;
        desc_subdoc      := elencoBen.subdoc_desc;
        flag_pagato      := elencoBen.subdoc_pagato_cec; 
        desc_stato_doc   := elencoBen.doc_stato_desc;
        
        return next;        
            
        nome_ente := '';
        cod_soggetto := '';
        desc_soggetto := '';
        anno_doc := NULL;
        numero_doc := '';
        numero_subdoc := NULL;
        desc_subdoc := '';
        --flag_pagato := '';
        numero_movimento := NULL;
        anno_bilancio := NULL;  
        data_pagamento_cec := NULL;
        desc_stato_doc := NULL;
                 
      END LOOP;

END IF;
  
IF p_tipo_fatture IN ('SP','T') THEN

    FOR elencoBenFattPag IN
    SELECT tep.ente_denominazione,
           sts.soggetto_code,
           sts.soggetto_desc,
           td.doc_anno,
           td.doc_numero,
           ts.subdoc_numero,
           ts.subdoc_desc,
           ts.subdoc_pagato_cec,
           tm.movt_numero,
           ts.subdoc_data_pagamento_cec,
           tp.anno,
           dds.doc_stato_desc
    FROM       siac_t_movimento tm
    INNER JOIN siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tm.ente_proprietario_id    
    INNER JOIN siac_t_richiesta_econ tre ON tre.ricecon_id = tm.ricecon_id
    INNER JOIN siac_t_bil tb ON tb.bil_id = tre.bil_id
    INNER JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
    LEFT JOIN  siac_d_richiesta_econ_tipo dret ON dret.ricecon_tipo_id = tre.ricecon_tipo_id AND dret.data_cancellazione IS NULL 
    LEFT JOIN  siac_r_richiesta_econ_subdoc rres ON rres.ricecon_id = tre.ricecon_id AND rres.data_cancellazione IS NULL 
    LEFT JOIN  siac_t_subdoc ts ON ts.subdoc_id = rres.subdoc_id AND ts.data_cancellazione IS NULL 
    LEFT JOIN  siac_t_doc td ON td.doc_id = ts.doc_id AND td.data_cancellazione IS NULL 
    LEFT JOIN  siac_r_doc_stato srds ON srds.doc_id = td.doc_id  AND srds.data_cancellazione IS NULL  
    LEFT JOIN  siac_d_doc_stato dds ON dds.doc_stato_id = srds.doc_stato_id AND dds.data_cancellazione IS NULL 
    LEFT JOIN  siac_r_doc_sog rds ON rds.doc_id = td.doc_id AND rds.data_cancellazione IS NULL 
    LEFT JOIN  siac_t_soggetto sts ON sts.soggetto_id = rds.soggetto_id AND sts.data_cancellazione IS NULL 
    WHERE tm.ente_proprietario_id = p_ente_prop_id
    AND  (tp.anno = COALESCE(p_anno, tp.anno) OR p_anno = '')
    AND   td.doc_collegato_cec = 'TRUE'
    AND   dret.ricecon_tipo_code = 'PAGAMENTO_FATTURE'
    AND   ts.subdoc_pagato_cec = 'TRUE'
    AND  (sts.soggetto_code = COALESCE(p_cod_soggetto, sts.soggetto_code) OR p_cod_soggetto = '')
    AND   to_date(to_char(ts.subdoc_data_pagamento_cec ,'dd/mm/yyyy') ,'dd/mm/yyyy') BETWEEN COALESCE(p_data_pagamento_cec_da, to_date(to_char(ts.subdoc_data_pagamento_cec ,'dd/mm/yyyy') ,'dd/mm/yyyy')) AND COALESCE(p_data_pagamento_cec_a, to_date(to_char(ts.subdoc_data_pagamento_cec ,'dd/mm/yyyy') ,'dd/mm/yyyy'))
    AND tm.data_cancellazione IS NULL
    AND tep.data_cancellazione IS NULL
    AND tre.data_cancellazione IS NULL
    AND tb.data_cancellazione IS NULL
    AND tp.data_cancellazione IS NULL        
    ORDER BY tp.anno, sts.soggetto_code, td.doc_numero, ts.subdoc_numero, tm.movt_numero
    
      LOOP
      
        nome_ente        := elencoBenFattPag.ente_denominazione;
        cod_soggetto     := elencoBenFattPag.soggetto_code;
        desc_soggetto    := elencoBenFattPag.soggetto_desc;
        anno_doc         := elencoBenFattPag.doc_anno;
        numero_doc       := elencoBenFattPag.doc_numero;
        numero_subdoc    := elencoBenFattPag.subdoc_numero;
        desc_subdoc      := elencoBenFattPag.subdoc_desc;
        flag_pagato      := elencoBenFattPag.subdoc_pagato_cec;
        numero_movimento := elencoBenFattPag.movt_numero;
        data_pagamento_cec := elencoBenFattPag.subdoc_data_pagamento_cec;
        anno_bilancio := elencoBenFattPag.anno; 
        desc_stato_doc := elencoBenFattPag.doc_stato_desc;
                  
        return next;        
           
        nome_ente = '';
        cod_soggetto = '';
        desc_soggetto = '';
        anno_doc := NULL;
        numero_doc = '';
        numero_subdoc = NULL;
        desc_subdoc = '';
        --flag_pagato = '';
        numero_movimento = NULL;
        anno_bilancio := NULL;  
        data_pagamento_cec := NULL;
        desc_stato_doc := NULL;

      END LOOP;

END IF; 

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati dei beneficiari delle fatture pagate in cassa economale non trovati.' ;
		--return next;
	when others  THEN
		
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'BENEFICIARI FATTURE PAGATE CASSA ECONOMALE',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;