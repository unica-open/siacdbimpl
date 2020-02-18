/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR098_elenco_fatture_elettroniche" (
  p_ente_prop_id integer,
  p_cod_tipo_documento varchar,
  p_cod_ufficio varchar,
  p_stato_acq varchar
)
RETURNS TABLE (
  nome_ente varchar,
  cod_fornitore varchar,
  desc_fornitore varchar,
  data_emissione date,
  data_ricezione date,
  num_documento varchar,
  cod_tipo_documento varchar,
  desc_tipo_documento varchar,
  data_acquisizione date,
  stato_acquisizione varchar,
  importo_lordo numeric,
  note varchar,
  pccuff_code varchar,
  pccuff_desc varchar
) AS
$body$
DECLARE
 elencoFattElett record;
 
BEGIN
 
nome_ente='';
cod_fornitore='';
desc_fornitore='';
data_emissione=NULL;
data_ricezione=NULL;
num_documento='';
cod_tipo_documento='';
desc_tipo_documento='';
data_acquisizione=NULL;
stato_acquisizione='';
importo_lordo=0;
note='';
pccuff_code='';
pccuff_desc='';

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati delle fatture elettroniche ';

    for elencoFattElett IN
        SELECT  t_ente_proprietario.ente_denominazione,
                COALESCE(d_tipo_documento.codice,'') COD_TIPO_DOC,
                COALESCE(d_tipo_documento.descrizione,'') DESC_TIPO_DOC,
                COALESCE(t_prestatore.codice_prestatore,'') COD_FORNITORE,
                COALESCE(t_prestatore.denominazione_prestatore,'') DESC_FORNITORE,
                t_fattura.numero NUM_FATTURA,
                t_fattura.data DATA_EMISSIONE,
                t_fattura.data_caricamento DATA_ACQUISIZIONE,
                COALESCE(t_fattura.note,'') note,
                t_fattura.importo_totale_documento IMPORTO_LORDO,
                COALESCE(t_fattura.stato_fattura,'') stato_fattura,
                t_portale_fatture.data_ricezione DATA_RICEZIONE,
                COALESCE(d_pcc_ufficio.pccuff_code,'') pccuff_code,
                COALESCE(d_pcc_ufficio.pccuff_desc,'') pccuff_desc
            FROM 
                sirfel_d_tipo_documento d_tipo_documento,
                sirfel_t_prestatore t_prestatore,
                siac_t_ente_proprietario t_ente_proprietario,                                
                sirfel_t_fattura t_fattura
            LEFT JOIN sirfel_t_portale_fatture t_portale_fatture 
            	ON (t_portale_fatture.id_fattura = t_fattura.id_fattura
                	AND t_portale_fatture.ente_proprietario_id = t_fattura.ente_proprietario_id)
            LEFT JOIN siac_d_pcc_ufficio  d_pcc_ufficio
            	ON (d_pcc_ufficio.pccuff_code=t_fattura.codice_destinatario
                	AND d_pcc_ufficio.ente_proprietario_id=t_fattura.ente_proprietario_id
                	AND d_pcc_ufficio.data_cancellazione IS NULL)
            WHERE d_tipo_documento.codice = t_fattura.tipo_documento
              AND d_tipo_documento.ente_proprietario_id = t_fattura.ente_proprietario_id
              AND t_prestatore.id_prestatore = t_fattura.id_prestatore
              AND t_prestatore.ente_proprietario_id = t_fattura.ente_proprietario_id
              AND t_ente_proprietario.ente_proprietario_id = t_fattura.ente_proprietario_id              
              AND t_fattura.ente_proprietario_id = p_ente_prop_id
              AND (d_tipo_documento.codice = p_cod_tipo_documento 
                   OR p_cod_tipo_documento = 'T'
                  )   
              AND (t_fattura.codice_destinatario = p_cod_ufficio
                   OR p_cod_ufficio = 'T'
                  ) 
              AND (t_fattura.stato_fattura = p_stato_acq
                   OR p_stato_acq = 'T'
                  )                                                    
              AND t_ente_proprietario.data_cancellazione IS NULL
            ORDER BY d_tipo_documento.codice, t_fattura.numero
    loop
        nome_ente=elencoFattElett.ente_denominazione;
        cod_fornitore=elencoFattElett.COD_FORNITORE;
        desc_fornitore=elencoFattElett.DESC_FORNITORE;
        data_emissione=elencoFattElett.DATA_EMISSIONE;
        data_ricezione=elencoFattElett.DATA_RICEZIONE;
        num_documento=elencoFattElett.NUM_FATTURA;
        cod_tipo_documento=elencoFattElett.COD_TIPO_DOC;
        desc_tipo_documento=elencoFattElett.DESC_TIPO_DOC;
        data_acquisizione=elencoFattElett.DATA_ACQUISIZIONE;
        
        IF elencoFattElett.stato_fattura = 'S' THEN
           stato_acquisizione := 'importata';
        ELSIF elencoFattElett.stato_fattura = 'N' THEN
           stato_acquisizione := 'da acquisire';   
        ELSIF elencoFattElett.stato_fattura = 'A' THEN
           stato_acquisizione := 'sospesa'; 
        ELSE
           stato_acquisizione=elencoFattElett.stato_fattura;
        END IF;    
                 
        importo_lordo=elencoFattElett.importo_lordo;
        note=COALESCE(elencoFattElett.note,'');
        pccuff_code=COALESCE(elencoFattElett.pccuff_code,'');
		pccuff_desc=COALESCE(elencoFattElett.pccuff_desc,'');

return next;        
        
nome_ente='';
cod_fornitore='';
desc_fornitore='';
data_emissione=NULL;
data_ricezione=NULL;
num_documento='';
cod_tipo_documento='';
desc_tipo_documento='';
data_acquisizione=NULL;
stato_acquisizione='';
importo_lordo=0;
note='';
pccuff_code='';
pccuff_desc='';

end loop;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati delle fatture elettroniche non trovati.' ;
		--return next;
	when others  THEN
		
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'FATTURE ELETTRONICHE',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;