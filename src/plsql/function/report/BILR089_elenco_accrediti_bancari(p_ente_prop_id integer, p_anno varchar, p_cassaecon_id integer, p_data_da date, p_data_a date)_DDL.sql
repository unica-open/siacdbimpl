/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR089_elenco_accrediti_bancari" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cassaecon_id integer,
  p_data_da date,
  p_data_a date
)
RETURNS TABLE (
  nome_ente varchar,
  anno_ese_finanz integer,
  benef_matricola varchar,
  benef_cognome varchar,
  benef_nome varchar,
  banca_iban varchar,
  num_sospeso integer,
  data_sospeso date,
  importo numeric,
  benef_fattura varchar,
  benef_cod_fisc_fattura varchar,
  benef_partita_iva_fattura varchar,
  benef_codice_fattura varchar,
  num_fattura varchar,
  tipo_richiesta_econ varchar,
  benef_ricecon_codice varchar,
  ricecon_tipo_desc varchar,
  num_movimento integer
) AS
$body$
DECLARE
elencoAccrediti record;
dati_giustif record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

anno_eser_int INTEGER;



BEGIN

nome_ente='';
anno_ese_finanz=0;
benef_matricola ='';
benef_cognome='';
benef_nome='';
banca_iban='';
num_sospeso=NULL;
data_sospeso=NULL;
importo=0;
benef_fattura='';
benef_cod_fisc_fattura='';
benef_partita_iva_fattura='';
benef_codice_fattura='';
num_fattura='';
tipo_richiesta_econ='';
benef_ricecon_codice:='';
ricecon_tipo_desc:='';
num_movimento:=0;

RTN_MESSAGGIO:='Estrazione dei dati degli accrediti bancari ''.';

raise notice 'Estrazione dei dati degli accrediti bancari';
raise notice 'ora: % ',clock_timestamp()::varchar;

anno_eser_int=p_anno :: INTEGER;


for elencoAccrediti in
select ente_prop.ente_denominazione,
	richiesta_econ.ricecon_codice_beneficiario,
	richiesta_econ.ricecon_codice_fiscale,
    richiesta_econ.ricecon_cognome,
    richiesta_econ.ricecon_nome,
    richiesta_econ.ricecon_matricola,
    richiesta_econ.ricecon_importo,
    richiesta_econ.ricecon_codice_beneficiario,
    richiesta_econ_sospesa.ricecons_numero num_sospeso,
    documento.doc_numero,
    documento.doc_anno,
    sub_documento.subdoc_numero,
    movimento.iban ,
    movimento.movt_pagamento_dettaglio,
    movimento.movt_data,
    movimento.gst_id,
    movimento.movt_numero,
    soggetto.codice_fiscale,
    soggetto.partita_iva,
    soggetto.soggetto_desc,
    soggetto.soggetto_code,  
    documento.doc_numero,
    anno_eserc.anno,
    richiesta_econ_tipo.ricecon_tipo_code,
    richiesta_econ_tipo.ricecon_tipo_desc,
    r_acc_tipo_cassa.cec_accredito_tipo_id
from siac_t_ente_proprietario				ente_prop,
	siac_t_movimento						movimento
    /* 30/03/2017: aggiunto il join con la tabella siac_r_accredito_tipo_cassa_econ
    	per filtrare le richieste che non sono pagate tramite assegno */
    	left join siac_r_accredito_tipo_cassa_econ r_acc_tipo_cassa
        	on (r_acc_tipo_cassa.cec_r_accredito_tipo_id=movimento.cec_r_accredito_tipo_id
            	and r_acc_tipo_cassa.data_cancellazione is null),
	siac_r_richiesta_econ_stato				r_richiesta_stato,
 	siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
	siac_d_richiesta_econ_stato				richiesta_stato,
    siac_t_periodo 							anno_eserc,
    siac_t_bil 								bilancio,
    siac_d_cassa_econ_modpag_tipo   		mod_pag_tipo,
	siac_t_richiesta_econ richiesta_econ
	 FULL join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            	AND richiesta_econ_sospesa.data_cancellazione IS NULL)
     FULL join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc    			
            on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id            	
            	AND r_richiesta_econ_subdoc.data_cancellazione IS NULL)            
      LEFT join 			siac_t_subdoc	sub_documento
            on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
            	AND sub_documento.data_cancellazione IS NULL)
	 LEFT join siac_t_doc				documento
            on (sub_documento.doc_id=documento.doc_id
            	AND documento.data_cancellazione IS NULL)  
     /* 29/02/2016: il soggetto deve essere quello della fattura e non
     	quello del subdoc */                          
     -- LEFT join 			siac_r_subdoc_sog	sub_doc_sog
      --      on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
     --       	AND sub_doc_sog.data_cancellazione IS NULL)
      --LEFT join 			siac_t_soggetto	soggetto
     --       on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
     --       	AND soggetto.data_cancellazione IS NULL)   
     LEFT join 			siac_r_doc_sog	r_doc_sog
            on (documento.doc_id=r_doc_sog.doc_id
            	AND r_doc_sog.data_cancellazione IS NULL)
     LEFT join 			siac_t_soggetto	soggetto
            on (r_doc_sog.soggetto_id=soggetto.soggetto_id
            	AND soggetto.data_cancellazione IS NULL)  
WHERE  ente_prop.ente_proprietario_id=richiesta_econ.ente_proprietario_id
	AND movimento.ricecon_id=richiesta_econ.ricecon_id
    AND richiesta_econ_tipo.ricecon_tipo_id=richiesta_econ.ricecon_tipo_id
    AND mod_pag_tipo.cassamodpag_tipo_id=movimento.cassamodpag_tipo_id
	AND richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
	AND r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id    
    AND richiesta_econ.bil_id=bilancio.bil_id
    AND bilancio.periodo_id=anno_eserc.periodo_id
    AND richiesta_econ.ente_proprietario_id=p_ente_prop_id
    AND richiesta_econ.cassaecon_id=p_cassaecon_id
    AND anno_eserc.anno=p_anno
    AND movimento.movt_data between p_data_da AND p_data_a
    AND richiesta_stato.ricecon_stato_code<>'AN' -- Annullati
    AND mod_pag_tipo.cassamodpag_tipo_code ='CC' -- Conto Corrente 
    	/* 30/03/2017: se questo campo è NULL la richiesta NON è pagata tramite
        	assegno */
    AND r_acc_tipo_cassa.cec_accredito_tipo_id IS NULL
    AND ente_prop.data_cancellazione IS NULL
    AND  movimento.data_cancellazione is null
    AND richiesta_econ.data_cancellazione IS NULL 
    AND r_richiesta_stato.data_cancellazione IS NULL 
    AND richiesta_econ_tipo.data_cancellazione IS NULL 
    AND richiesta_stato.data_cancellazione IS NULL  
    AND bilancio.data_cancellazione IS NULL
    AND anno_eserc.data_cancellazione IS NULL          
loop
raise notice 'mov = %, cec_accredito_tipo_id =%', elencoAccrediti.movt_pagamento_dettaglio,
elencoAccrediti.cec_accredito_tipo_id;

nome_ente=COALESCE(elencoAccrediti.ente_denominazione,'');
anno_ese_finanz=elencoAccrediti.anno ::INTEGER;
benef_matricola =COALESCE(elencoAccrediti.ricecon_matricola,'');

benef_cognome=COALESCE(elencoAccrediti.ricecon_cognome,'');
benef_nome=COALESCE(elencoAccrediti.ricecon_nome,'');

/* 12/09/2017: jira SIAC-5226.
	Ci sono casi in cui i campi ricecon_cognome e ricecon_nome contengono entrambi
    sia il nome che il cognome, di conseguenza il report raddoppia l'informazione.
    Per questo si è deciso che, se i due campi sono uguali, la procedura restiuisce
    solo uno dei due. */
if benef_cognome = benef_nome THEN
	benef_nome:='';
end if;

	--27/04/2017: aggiunto il codice del beneficiario
benef_ricecon_codice=COALESCE(elencoAccrediti.ricecon_codice_beneficiario,'');

IF elencoAccrediti.iban IS NULL THEN
	banca_iban=COALESCE(elencoAccrediti.movt_pagamento_dettaglio,'');	
else
	banca_iban=elencoAccrediti.iban;	
END IF;
num_sospeso=elencoAccrediti.num_sospeso;
	/* come data sospeso usiamo la data del movimento */
data_sospeso=elencoAccrediti.movt_data;

if elencoAccrediti.gst_id is not NULL THEN                       
    SELECT rend_importo_restituito, rend_importo_integrato
      INTO dati_giustif
      FROM siac_t_giustificativo
      WHERE gst_id = elencoAccrediti.gst_id;
      IF NOT FOUND THEN
          RAISE EXCEPTION 'Non esiste il giustificativo %', elenco_movimenti.gst_id;
          return;
      ELSE
                      /* se esiste un importo restituito prendo questo con segno negativo */
      	if dati_giustif.rend_importo_restituito > 0 THEN                  
        	importo = -dati_giustif.rend_importo_restituito;
        elsif dati_giustif.rend_importo_integrato > 0 THEN
        	importo = dati_giustif.rend_importo_integrato;
        else 
        	importo=0;
        end if;
    END IF;   
else
	importo=COALESCE(elencoAccrediti.ricecon_importo,0);    
end if;

--importo=COALESCE(elencoAccrediti.ricecon_importo,0);
benef_fattura=COALESCE(elencoAccrediti.soggetto_desc,'');
benef_cod_fisc_fattura=COALESCE(elencoAccrediti.codice_fiscale,'');
benef_partita_iva_fattura=COALESCE(elencoAccrediti.partita_iva,'');
benef_codice_fattura=COALESCE(elencoAccrediti.soggetto_code,'');
num_fattura=COALESCE(elencoAccrediti.doc_numero,'');
tipo_richiesta_econ=elencoAccrediti.ricecon_tipo_code;     

/* 04/10/2017: SIAC-5255 CR-982
	Aggiunti la descrizione della richiesta ed il numero
	del movimento */
ricecon_tipo_desc:=COALESCE(elencoAccrediti.ricecon_tipo_desc, ''); 
num_movimento:=elencoAccrediti.movt_numero;

return next;


nome_ente='';
anno_ese_finanz=0;
benef_matricola ='';
benef_cognome='';
benef_nome='';
banca_iban='';
num_sospeso=NULL;
data_sospeso=NULL;
importo=0;
benef_fattura='';
benef_cod_fisc_fattura='';
benef_partita_iva_fattura='';
benef_codice_fattura='';
num_fattura='';
tipo_richiesta_econ='';
ricecon_tipo_desc:='';
num_movimento:=0;

end loop;

raise notice 'fine estrazione dei dati';  
raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'nessun dato trovato' ;
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