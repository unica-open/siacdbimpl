/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5226 - INIZIO - Maurizio

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
  benef_ricecon_codice varchar
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
    soggetto.codice_fiscale,
    soggetto.partita_iva,
    soggetto.soggetto_desc,
    soggetto.soggetto_code,  
    documento.doc_numero,
    anno_eserc.anno,
    richiesta_econ_tipo.ricecon_tipo_code,
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
    	/* 30/03/2017: se questo campo e' NULL la richiesta NON e' pagata tramite
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
    Per questo si e' deciso che, se i due campi sono uguali, la procedura restiuisce
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

-- SIAC-5226 - FINE - Maurizio


-- SIAC-5186 - INIZIO - Maurizio

DROP FUNCTION siac.fnc_bilr085_tab_ordinativi_reversali (ente_proprietario_id_in integer);

CREATE OR REPLACE FUNCTION siac.fnc_bilr085_tab_ordinativi_reversali (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  ord_id_da integer,
  elenco_reversali text,
  split_reverse text,
  onere_tipo_code varchar,
  relaz_tipo_code varchar,
  importo_split numeric,
  importo_imponibile numeric,
  onere_code_irpef varchar,
  importo_irpef_imponibile numeric,
  importo_irpef_imposta numeric,
  importo_inps_imponibile numeric,
  importo_inps_imposta numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
reversale record;
begin 
ord_id_da:=null;
elenco_reversali:='';
split_reverse:='';
onere_code_irpef:='';
importo_split:=0;
importo_irpef_imponibile:=0;
importo_irpef_imposta:=0;
importo_inps_imponibile:=0;
importo_inps_imposta:=0;

RTN_MESSAGGIO:='Errore generico';

/* 14/09/2017: Function modificata per restituire importi diversi per ogni tipologia
	di imposta.
*/
for reversale in 
select 
a.ord_id_da,
b.ord_numero, b.ord_emissione_data,
                    b.ord_id,d.relaz_tipo_code,
                    f.ord_ts_det_importo importo_ord,
                    i.importo_carico_ente, i.importo_imponibile,
              		m.onere_tipo_code, l.onere_code
            from  siac_r_ordinativo a, siac_t_ordinativo b,
                  siac_d_ordinativo_tipo c,
                  siac_d_relaz_tipo d, siac_t_ordinativo_ts e,
                  siac_t_ordinativo_ts_det f, 
                  siac_d_ordinativo_ts_det_tipo g,
                  siac_r_doc_onere_ordinativo_ts h,
             	  siac_r_doc_onere i, siac_d_onere l,
              	  siac_d_onere_tipo  m
                  where 
                  a.ente_proprietario_id=ente_proprietario_id_in  and 
                  b.ord_id=a.ord_id_a
                  	AND c.ord_tipo_id=b.ord_tipo_id
                    AND d.relaz_tipo_id=a.relaz_tipo_id
                    AND e.ord_id=b.ord_id
                    AND f.ord_ts_id=e.ord_ts_id
                    AND g.ord_ts_det_tipo_id=f.ord_ts_det_tipo_id
                    AND h.ord_ts_id=e.ord_ts_id
                  	AND i.doc_onere_id=h.doc_onere_id
                  	AND l.onere_id=i.onere_id
                  	AND m.onere_tipo_id=l.onere_tipo_id
                    AND c.ord_tipo_code ='I'
                    AND g.ord_ts_det_tipo_code='A'
                    --AND m.onere_tipo_code in('SPR','IRPEF','INPS')
                AND d.data_cancellazione IS NULL
                AND b.data_cancellazione IS NULL
                AND a.data_cancellazione IS NULL
                AND c.data_cancellazione IS NULL
                AND e.data_cancellazione IS NULL
                AND f.data_cancellazione IS NULL
                AND g.data_cancellazione IS NULL
                AND h.data_cancellazione IS NULL
                AND i.data_cancellazione IS NULL
                AND l.data_cancellazione IS NULL
                AND m.data_cancellazione IS NULL
                order by 1,2
loop


--raise notice 'ord_id_da: %  ord_id_da_cursore: %',ord_id_da::varchar, reversale.ord_id_da::varchar ;
     if ord_id_da<>reversale.ord_id_da THEN
        return next;
        elenco_reversali:='';
        split_reverse:='';
        onere_code_irpef:='';
        importo_split:=0;
        importo_irpef_imponibile:=0;
        importo_irpef_imposta:=0;
        importo_inps_imponibile:=0;
        importo_inps_imposta:=0;
     end if;

    ord_id_da:=reversale.ord_id_da;
    onere_tipo_code:=reversale.onere_tipo_code;

    relaz_tipo_code:=reversale.relaz_tipo_code;


    importo_imponibile:=reversale.importo_imponibile;



      if elenco_reversali = '' THEN
        elenco_reversali = reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
     -- raise notice 'elenco_reversali: %',elenco_reversali ;
      else
        elenco_reversali = elenco_reversali||', '||reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
      end if;
      
    if reversale.relaz_tipo_code='SPR' then 
        importo_split:=importo_split+reversale.importo_ord;
      if split_reverse = '' THEN	
        split_reverse=reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
     --    raise notice 'split_reverse: %',split_reverse ;
      else
        split_reverse=split_reverse||', '||reversale.ord_numero ::VARCHAR ||' del '|| to_char(reversale.ord_emissione_data,'dd/mm/yyyy');
      end if;
    elsif upper(onere_tipo_code) = 'IRPEF' THEN  
        importo_irpef_imponibile:=importo_irpef_imponibile+reversale.importo_imponibile;
        importo_irpef_imposta:=importo_irpef_imposta+reversale.importo_ord;
        onere_code_irpef:=reversale.onere_code;
    elsif upper(onere_tipo_code) = 'INPS' THEN
        importo_inps_imponibile:=importo_inps_imponibile+reversale.importo_imponibile;
        importo_inps_imposta:=importo_inps_imposta+reversale.importo_ord;
    end if;

end loop;

return next;
exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
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

CREATE OR REPLACE FUNCTION siac."BILR085_mandato_di_pagamento" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_numero_distinta varchar
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

querytxt text;

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

importoSubDoc=0;

anno_eser_int=p_anno ::INTEGER;

--	 22/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
--    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca 
--     11/07/2016: aggiunto il parametro relativo al
--        numero distinta 
display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND 
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A", "DATA MANDATO DA/A" e "NUMERO DISTINTA".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';


-- 22/12/2015: gestiti i parametri numero mandato da/a e data mandato da/a 
--	al posto della sola data mandato.
--		AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_mandato.
--	I parametri non sono obbligatori ma almeno uno deve essere specificato.

contaRecord=0;


querytxt:='with ord as (
        select 
        a.*,c.elem_id,
        c.elem_code , c.elem_code2 
         from siac_t_ordinativo a
         	LEFT JOIN siac_d_distinta d_distinta
                on (d_distinta.dist_id=a.dist_id
                    AND d_distinta.data_cancellazione IS NULL), 
         siac_r_ordinativo_bil_elem b,
		 siac_t_bil_elem c,
         siac_d_ordinativo_tipo d
         where a.ord_id=b.ord_id
         and c.elem_id=b.elem_id       
         and d.ord_tipo_id=a.ord_tipo_id
         and d.ord_tipo_code=''P''
         and a.ente_proprietario_id='||p_ente_prop_id||
         ' and a.ord_anno='''||anno_eser_int||'''';
         
         --26/04/2017: la distinta e' collegata all'ordinativo
	if  p_numero_distinta is not null and ascii(trim(p_numero_distinta))<>0 then 
      querytxt:=querytxt || ' and d_distinta.dist_code='''||p_numero_distinta||'''';    
   end if;
   
 querytxt:=querytxt || ' and a.data_cancellazione is null
         and b.data_cancellazione is null
         and c.data_cancellazione is null
         and d.data_cancellazione is null
          ),
     mif as (        
          select tb.*,zzz.attoamm_tipo_desc from (
            with mif1 as 
            (        
            select a.*,b.flusso_elab_mif_id,            
        b.flusso_elab_mif_data,    c.flusso_elab_mif_tipo_dec, 
        c.flusso_elab_mif_tipo_id
             from mif_t_ordinativo_spesa a,  
            mif_t_flusso_elaborato b, mif_d_flusso_elaborato_tipo c
            -- 24/04/2017: aggiunte le tabelle ordinativo e distinta
            -- per il test del codice distinta
            --siac_t_ordinativo ord                
             	--LEFT JOIN siac_d_distinta d_distinta
                --	on (d_distinta.dist_id=ord.dist_id
                  --  	AND d_distinta.data_cancellazione IS NULL)   
            where a.ente_proprietario_id='||p_ente_prop_id||'  
            and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
            and c.flusso_elab_mif_tipo_id=b.flusso_elab_mif_tipo_id
            --and ord.ord_id = a.mif_ord_ord_id
            and b.flusso_elab_mif_esito=''OK''
            and a.data_cancellazione is null
             and b.data_cancellazione is null
             and c.data_cancellazione is null';
             --and ord.data_cancellazione is null';
             
   if p_num_mandato_da is not null and p_num_mandato_a is not null THEN
   querytxt:=querytxt || ' and a.mif_ord_numero::integer between '|| p_num_mandato_da ||
   'and ' ||p_num_mandato_a;
   elsif p_num_mandato_da is not null and p_num_mandato_a is null THEN
   
   querytxt:=querytxt || ' and a.mif_ord_numero::integer = '|| p_num_mandato_da;
    elsif p_num_mandato_da is  null and p_num_mandato_a is not null THEN
   querytxt:=querytxt || ' and a.mif_ord_numero::integer = '|| p_num_mandato_a;
   end if;
   
 
 
   if p_data_mandato_da is not null and p_data_mandato_a is not null THEN
   querytxt:=querytxt || ' and to_date(a.mif_ord_data,''yyyy-mm-dd'') between to_date('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')' || ' and to_date(''' ||p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')';
    elsif p_data_mandato_da is not null and p_data_mandato_a is  null THEN
   querytxt:=querytxt || ' and to_date(a.mif_ord_data,''yyyy-mm-dd'') = to_date('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')' ;
    elsif p_data_mandato_da is  null and p_data_mandato_a is not null THEN
   querytxt:=querytxt || ' and to_date(a.mif_ord_data,''yyyy-mm-dd'') = to_date('''|| p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')' ;
   end if;
   
  --   raise notice 'sql:%', querytxt;
   
		--26/04/2017: la distinta e' collegata all'ordinativo
   --if  p_numero_distinta is not null and ascii(trim(p_numero_distinta))<>0 then 
   	--querytxt:=querytxt || ' and a.mif_ord_codice_flusso_oil='''||p_numero_distinta||'''';   
  -- end if;
   
   
   /* 14/09/2017: cambiata la gestione dei dati delle ritenute estratte dalla function
   		fnc_bilr085_tab_ordinativi_reversali che ora restituisce importi diversi per ogni
        tipo di ritenuta.  
        Aggiunta anche la gestione del messaggio di errore nel caso l'ente non sia abilitato
        ad utilizzare questa stampa.
   */
   querytxt:=querytxt||
             ' ) ,
            mifmax as (
             select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
             a.mif_ord_anno,a.mif_ord_numero  
             from mif_t_ordinativo_spesa a,
            mif_t_flusso_elaborato b
            where 
            a.ente_proprietario_id='||p_ente_prop_id||'   
            AND b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id 
            and b.flusso_elab_mif_esito=''OK''
            and a.data_cancellazione is null
         	and b.data_cancellazione is null
            group by a.mif_ord_anno,a.mif_ord_numero
            ),
            miftele as (select * from 
            mif_t_ordinativo_spesa_disp_ente a where 
            a.ente_proprietario_id='||p_ente_prop_id||'  and 
            a.mif_ord_dispe_nome=''Transazione Elementare''
            and a.data_cancellazione is null)
            select mif1.*,miftele.mif_ord_dispe_valore from mif1 
            join mifmax on 
            mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id and
            mif1.mif_ord_anno=mifmax.mif_ord_anno and 
             mif1.mif_ord_numero=mifmax.mif_ord_numero 
            left join miftele on 
            mif1.mif_ord_id=miftele.mif_ord_id) as tb
            left join siac_d_atto_amm_tipo zzz on
            -- 24/04/2017: corretto il join; se mif_ord_estremi_attoamm= stringa vuota
            --  la position restituisce un numero negativo e la substring va 
            --  in errore.
            --substring (tb.mif_ord_estremi_attoamm from 1 for position ('' '' in tb.mif_ord_estremi_attoamm)-1)=zzz.attoamm_tipo_code
            trim(substring (tb.mif_ord_estremi_attoamm from 1 for position ('' '' in tb.mif_ord_estremi_attoamm)))=zzz.attoamm_tipo_code
            and zzz.ente_proprietario_id=tb.ente_proprietario_id
            ),
        ente as (
        select b.*,a.codice_fiscale,a.ente_denominazione  From siac_t_ente_proprietario a, siac_t_ente_oil b
        where a.ente_proprietario_id=b.ente_proprietario_id   
        and a.ente_proprietario_id='||p_ente_prop_id||' 
        and a.data_cancellazione is null
         and b.data_cancellazione is null),
        doc as (   
        with doca as (
        select a.ord_ts_id,
          b.subdoc_numero, b.subdoc_importo,c.*,e.ord_id ,d.doc_tipo_code
        from siac_r_subdoc_ordinativo_ts a, siac_t_subdoc b, 
        siac_t_doc c, siac_d_doc_tipo d,siac_t_ordinativo_ts e
        where a.ente_proprietario_id='||p_ente_prop_id||'  
        and a.subdoc_id=b.subdoc_id
        and b.doc_id=c.doc_id
        and d.doc_tipo_id=c.doc_tipo_id
        and e.ord_ts_id=a.ord_ts_id
        and a.data_cancellazione is null
         and b.data_cancellazione is null
         and c.data_cancellazione is null
         and d.data_cancellazione is null
         and e.data_cancellazione is null)
         , ndc as (select * from fnc_BILR085_note_di_credito('||p_ente_prop_id||'))   
         select doca.*,ndc.num_doc_ncd from doca left join ndc on 
         doca.doc_id=ndc.doc_id
        ) ,
        codbollo as (select a.codbollo_id, a.codbollo_desc bollo From siac_d_codicebollo a where a.ente_proprietario_id='||p_ente_prop_id||' and a.data_cancellazione is null)             
		,modpag as (select a.ord_id,c.accredito_tipo_desc , b.iban 
         from siac_r_ordinativo_modpag a,siac_t_modpag b,siac_d_accredito_tipo c
          where a.modpag_id=b.modpag_id
          AND b.accredito_tipo_id=c.accredito_tipo_id
          AND a.ente_proprietario_id = '||p_ente_prop_id||' 
          AND b.data_cancellazione IS NULL
          AND c.data_cancellazione IS NULL
          AND a.data_cancellazione IS NULL)
        , modpagcess as (
        select a.ord_id,c.accredito_tipo_desc, b.iban 
            from siac_r_ordinativo_modpag a,
                siac_t_modpag b, siac_d_accredito_tipo c,siac_r_soggrel_modpag d
            where a.soggetto_relaz_id=d.soggetto_relaz_id
              AND d.modpag_id=b.modpag_id
              AND b.accredito_tipo_id=c.accredito_tipo_id
              AND a.ente_proprietario_id = '||p_ente_prop_id||' 
              AND b.data_cancellazione IS NULL
              AND c.data_cancellazione IS NULL
              AND a.data_cancellazione IS NULL
              AND d.data_cancellazione IS NULL),
cup as ( SELECT  distinct 
e.ord_id, d.attr_code, c.testo            
                FROM siac_t_liquidazione	a, 
                    siac_r_liquidazione_ord b,
                    siac_r_liquidazione_attr c,
                    siac_t_attr d, siac_t_ordinativo_ts e                                                
                WHERE a.liq_id=b.liq_id
                    AND c.liq_id=a.liq_id
                    AND d.attr_id=c.attr_id                                
                    and e.ord_ts_id=b.sord_id
                    and b.ente_proprietario_id='||p_ente_prop_id||' 
                    and d.attr_code=''cup''
                   AND  a.data_cancellazione IS NULL   
                   AND  b.data_cancellazione IS NULL
                   AND  c.data_cancellazione IS NULL 
                   AND  d.data_cancellazione IS NULL 
                   AND  e.data_cancellazione IS NULL) ,
cig as ( SELECT  distinct 
e.ord_id, d.attr_code, c.testo            
                FROM siac_t_liquidazione	a, 
                    siac_r_liquidazione_ord b,
                    siac_r_liquidazione_attr c,
                    siac_t_attr d, siac_t_ordinativo_ts e                                                
                WHERE a.liq_id=b.liq_id
                    AND c.liq_id=a.liq_id
                    AND d.attr_id=c.attr_id                                
                    and e.ord_ts_id=b.sord_id
                    and b.ente_proprietario_id='||p_ente_prop_id||' 
                    and d.attr_code=''cig''
                   AND  a.data_cancellazione IS NULL   
                   AND  b.data_cancellazione IS NULL
                   AND  c.data_cancellazione IS NULL 
                   AND  d.data_cancellazione IS NULL 
                   AND  e.data_cancellazione IS NULL)    
, reversale as (select * from fnc_BILR085_tab_ordinativi_reversali ('||p_ente_prop_id||')
                ),
imp as (select * from fnc_BILR085_tab_impegni('||p_ente_prop_id||')),
ndcimpded as (  select a.ord_id, sum(c.subdoc_importo_da_dedurre) importo_da_dedurre_ncd 
              from siac_t_ordinativo_ts a,
                siac_r_subdoc_ordinativo_ts b,
                siac_t_subdoc c            
            where 
            a.ente_proprietario_id='||p_ente_prop_id||' and            
            b.ord_ts_id =a.ord_ts_id
            AND c.subdoc_id= b.subdoc_id
             AND b.data_cancellazione IS NULL
            AND a.data_cancellazione IS NULL
            AND c.data_cancellazione IS NULL                                 
            group by a.ord_id)                                                
        select  
        mif.mif_ord_desc_ente::varchar nome_ente, 
        ente.codice_fiscale::varchar partita_iva_ente,
        mif.mif_ord_anno_esercizio::integer anno_ese_finanz,
		mif.mif_ord_anno::integer anno_capitolo,  
        ord.elem_code::varchar cod_capitolo,
		ord.elem_code2::varchar cod_articolo,
        COALESCE(mif.mif_ord_siope_codice_cge,'''')::varchar cod_gestione,
        imp.impegni::varchar num_impegno,
        ''''::varchar num_subimpegno,
        COALESCE(mif.mif_ord_importo::numeric,0::numeric) / 100 ::numeric importo_lordo_mandato,
        COALESCE(mif.mif_ord_numero::integer,0::integer) numero_mandato,
        to_date(mif.mif_ord_data,''yyyy/MM/dd'') data_mandato,
        COALESCE(mif.mif_ord_prev::numeric,0::numeric) / 100::numeric importo_stanz_cassa,
        COALESCE(ord.ord_cast_emessi::numeric,0::numeric) importo_tot_mandati_emessi,
    	COALESCE(ord.ord_cast_emessi::numeric,0::numeric) +COALESCE(mif.mif_ord_importo::numeric ,0::numeric) / 100::numeric importo_tot_mandati_dopo_emiss,
	    COALESCE(mif.mif_ord_disp_cassa::numeric ,0::numeric) / 100::numeric importo_dispon,
        COALESCE(ente.ente_oil_tes_desc,'''')::varchar nome_tesoriere,
        COALESCE(mif.mif_ord_pagam_causale,'''')::varchar desc_causale,
        COALESCE(mif.attoamm_tipo_desc,'''')::varchar desc_provvedimento,
        substring(mif.mif_ord_estremi_attoamm from position('' '' in mif.mif_ord_estremi_attoamm) + 1)::varchar   estremi_provvedimento,
        ''''::varchar numero_fattura_completa,
        case when doc.doc_numero is not null then doc.doc_numero||''/''||doc.subdoc_numero::varchar 	else ''''::varchar end  as num_fattura,
        COALESCE(doc.doc_anno,0)::integer anno_fattura,
        COALESCE(doc.doc_importo,0)::numeric importo_documento, 
        COALESCE(doc.subdoc_numero,0)::integer num_sub_doc_fattura,
        COALESCE(doc.subdoc_importo,0)::numeric importo_fattura,
        COALESCE(mif.mif_ord_codfisc_benef,'''')::varchar benef_cod_fiscale,
        COALESCE(mif.mif_ord_partiva_benef,'''')::varchar benef_partita_iva,
        COALESCE(mif.mif_ord_anag_benef,'''')::varchar benef_nome,
        COALESCE(mif.mif_ord_indir_benef,'''')::varchar benef_indirizzo,
        COALESCE(mif.mif_ord_cap_benef,'''')::varchar benef_cap,
    	COALESCE(mif.mif_ord_localita_benef,'''')::varchar benef_localita,
    	COALESCE(mif.mif_ord_prov_benef,'''')::varchar benef_provincia,
        case when modpag.accredito_tipo_desc is null then 
        COALESCE(modpagcess.accredito_tipo_desc,'''') ::varchar 
        else
        COALESCE(modpag.accredito_tipo_desc,'''')::varchar end desc_mod_pagamento ,
        codbollo.bollo::varchar bollo,
        COALESCE(mif.mif_ord_denom_banca_benef,'''')::varchar banca_appoggio,
        COALESCE(mif.mif_ord_abi_benef,'''')::varchar banca_abi,
        COALESCE(mif.mif_ord_cab_benef,'''')::varchar banca_cab,
        COALESCE(mif.mif_ord_cc_benef,'''')::varchar banca_cc, 
        COALESCE(mif.mif_ord_cc_benef_estero,'''')::varchar banca_cc_estero,
        COALESCE(mif.mif_ord_cc_postale_benef,'''')::varchar banca_cc_posta,
      	COALESCE(mif.mif_ord_cin_benef,'''')::varchar banca_cin,
        case when modpag.accredito_tipo_desc is null then 
        coalesce(modpagcess.iban,'''')::varchar  else coalesce(modpag.iban,'''')::varchar end banca_iban,
        COALESCE(mif.mif_ord_swift_benef,'''')::varchar banca_bic,
        case when   mif.mif_ord_codfisc_del is not null then mif.mif_ord_codfisc_del::varchar||'' - '' ||COALESCE(mif.mif_ord_anag_del,'''')::varchar
        else COALESCE(mif.mif_ord_anag_del,'''')::varchar end  quietanzante,
        --case when reversale.onere_tipo_code=''IRPEF'' then reversale.importo_imponibile::numeric else 0::numeric end
         --importo_irpef_imponibile,
         COALESCE(reversale.importo_irpef_imponibile,0)::numeric importo_irpef_imponibile,
         --case when reversale.onere_tipo_code=''IRPEF'' then reversale.importo_ord::numeric else 0::numeric end
         --importo_imposta,
         COALESCE(reversale.importo_irpef_imposta,0)::numeric importo_imposta,
        --    case when reversale.onere_tipo_code=''INPS'' then reversale.importo_imponibile::numeric else 0::numeric end
         --importo_inps_inponibile,
         COALESCE(reversale.importo_inps_imponibile,0)::numeric importo_inps_inponibile,
         --case when reversale.onere_tipo_code=''INPS'' then reversale.importo_ord::numeric else 0::numeric end
         --importo_ritenuta,
         COALESCE(reversale.importo_inps_imposta,0)::numeric importo_ritenuta,
         --COALESCE(mif.mif_ord_importo::numeric,0::numeric) / 100 ::numeric
		--	- case when reversale.onere_tipo_code=''INPS'' then reversale.importo_ord::numeric else 0::numeric end
		--	-case when reversale.onere_tipo_code=''IRPEF'' then reversale.importo_ord::numeric else 0::numeric end
		--	-case when reversale.relaz_tipo_code=''SPR'' then reversale.importo_ord::numeric else 0::numeric end 
       --  importo_netto,--daimplementare
        COALESCE(mif.mif_ord_importo::numeric,0::numeric) / 100 ::numeric
        	-COALESCE(reversale.importo_irpef_imposta,0)::numeric
            -COALESCE(reversale.importo_inps_imposta,0)::numeric
            -COALESCE(reversale.importo_split,0)::numeric importo_netto,
        COALESCE(cup.testo::varchar,'''')::varchar    cup,
        COALESCE(cig.testo::varchar,'''')::varchar    cig,
        COALESCE( ente.ente_oil_resp_ord,'''')::varchar resp_sett_amm,
        --case when upper(reversale.onere_tipo_code)=''IRPEF'' THEN reversale.onere_code::varchar else ''''::varchar end cod_tributo,  
        COALESCE(reversale.onere_code_irpef,'''')::varchar cod_tributo,
        COALESCE(ente.ente_oil_resp_amm,'''')::varchar resp_amm,
        COALESCE(mif.mif_ord_codifica_bilancio,'''')::varchar tit_miss_progr,
        COALESCE(mif.mif_ord_dispe_valore,'''')::varchar transaz_elementare,
		 COALESCE(reversale.elenco_reversali::varchar,'''')::varchar elenco_reversali,
		 COALESCE(reversale.split_reverse::varchar,'''')::varchar split_reverse,
		--case when reversale.relaz_tipo_code=''SPR'' then reversale.importo_ord::numeric else 0::numeric end importo_split_reverse,
        COALESCE(reversale.importo_split,0)::numeric importo_split_reverse,
        imp.anno_primo_impegno::varchar anno_primo_impegno,   
        case when mif.flusso_elab_mif_tipo_dec = true then ''Stampa giornaliera dei mandati di pagamento (BILR085): STAMPA NON UTILIZZABILE.''::varchar
        else '''||display_error||'''::varchar end display_error,
        COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''')::varchar cod_stato_mandato,
        COALESCE(mif.mif_ord_bci_conto,'''')::varchar banca_cc_bitalia,
        COALESCE(doc.doc_tipo_code,'''')::varchar tipo_doc,
        COALESCE(doc.num_doc_ncd,'''')::varchar num_doc_ncd ,
        COALESCE(ndcimpded.importo_da_dedurre_ncd::numeric,0)::numeric importo_da_dedurre_ncd
        from ord 
        join mif on
        ord.ord_id=mif.mif_ord_ord_id
        join ente on
        ord.ente_proprietario_id=ente.ente_proprietario_id
        left join codbollo on 
        ord.codbollo_id=codbollo.codbollo_id
          left join modpag on 
        ord.ord_id=modpag.ord_id
        left join modpagcess on 
        ord.ord_id=modpagcess.ord_id
        left join doc ON
        ord.ord_id=doc.ord_id
               left join cup ON
        ord.ord_id=cup.ord_id
        left join cig ON
        ord.ord_id=cig.ord_id
               left join reversale ON
        ord.ord_id=reversale.ord_id_da
        left join imp ON
        ord.ord_id=imp.ord_id
        left join ndcimpded ON
        ord.ord_id=ndcimpded.ord_id
          order by mif.mif_ord_numero, mif.mif_ord_data, doc.doc_numero, doc.subdoc_numero
        ';

raise notice 'sql:%', querytxt;

return query execute querytxt;

--raise notice 'ora: % ',clock_timestamp()::varchar;
--raise notice 'fine estrazione dei dati e preparazione dati in output ';  

 
exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
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


-- SIAC-5186 - FINE - Maurizio

-- allineamento CSI INIZIO
--Nuove azioni per adeguamento normativo previsione e rendiconto  

INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP1-BilPrev-2018',
       'Reportistica Bilancio di Previsione 2018 (Enti Locali)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_PREV' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP1-BilPrev-2018' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );


INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP2-BilPrev-2018',
       'Reportistica Bilancio di Previsione 2018 (Regioni)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_PREV' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP2-BilPrev-2018' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );
 

INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP1-BilCons-2016',
       'Reportistica Rendiconto della Gestione 2016 (Enti Locali)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_GES' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP1-BilCons-2016' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );


INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP1-BilCons-2017',
       'Reportistica Rendiconto della Gestione 2017 (Enti Locali)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_GES' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP1-BilCons-2017' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );
 

INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP2-BilCons-2016',
       'Reportistica Gestione 2016 (Regione)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_GES' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP2-BilCons-2016' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );


INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id,
  gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id,
  login_operazione)
select 'OP-GESREP2-BilCons-2017',
       'Reportistica Gestione 2017 (Regione)',
       ta.azione_tipo_id,
       ga.gruppo_azioni_id,
       '/../siacrepapp/azioneRichiesta.do',
       to_timestamp('01/01/2013', 'dd/mm/yyyy'),
       e.ente_proprietario_id,
       'admin'
from siac_d_azione_tipo ta,
     siac_d_gruppo_azioni ga,
     siac_t_ente_proprietario e
where ta.ente_proprietario_id = e.ente_proprietario_id and
      ga.ente_proprietario_id = e.ente_proprietario_id and
      ta.azione_tipo_code = 'ATTIVITA_SINGOLA' and
      ga.gruppo_azioni_code = 'BIL_CAP_GES' and
      not exists (
                   select 1
                   from siac_t_azione z
                   where z.azione_code = 'OP-GESREP2-BilCons-2017' and
                         z.azione_tipo_id = ta.azione_tipo_id and
                         z.gruppo_azioni_id = ga.gruppo_azioni_id
      );
      
-- allineamento CSI FINE

-- SIAC-5216 - INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  segno_importo varchar,
  importo numeric,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  livello integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
    
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

  return query
  select zz.* from (
  with clas as (
  with missione as 
  (select 
  e.classif_tipo_desc missione_tipo_desc,
  a.classif_id missione_id,
  a.classif_code missione_code,
  a.classif_desc missione_desc,
  a.validita_inizio missione_validita_inizio,
  a.validita_fine missione_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , programma as (
  select 
  e.classif_tipo_desc programma_tipo_desc,
  b.classif_id_padre missione_id,
  a.classif_id programma_id,
  a.classif_code programma_code,
  a.classif_desc programma_desc,
  a.validita_inizio programma_validita_inizio,
  a.validita_fine programma_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where 
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  ,
  titusc as (
  select 
  e.classif_tipo_desc titusc_tipo_desc,
  a.classif_id titusc_id,
  a.classif_code titusc_code,
  a.classif_desc titusc_desc,
  a.validita_inizio titusc_validita_inizio,
  a.validita_fine titusc_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
  , macroag as (
  select 
  e.classif_tipo_desc macroag_tipo_desc,
  b.classif_id_padre titusc_id,
  a.classif_id macroag_id,
  a.classif_code macroag_code,
  a.classif_desc macroag_desc,
  a.validita_inizio macroag_validita_inizio,
  a.validita_fine macroag_validita_fine,
  a.ente_proprietario_id
  from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id
  )
  select  missione.missione_tipo_desc,
  missione.missione_id,
  missione.missione_code,
  missione.missione_desc,
  missione.missione_validita_inizio,
  missione.missione_validita_fine,
  programma.programma_tipo_desc,
  programma.programma_id,
  programma.programma_code,
  programma.programma_desc,
  programma.programma_validita_inizio,
  programma.programma_validita_fine,
  titusc.titusc_tipo_desc,
  titusc.titusc_id,
  titusc.titusc_code,
  titusc.titusc_desc,
  titusc.titusc_validita_inizio,
  titusc.titusc_validita_fine,
  macroag.macroag_tipo_desc,
  macroag.macroag_id,
  macroag.macroag_code,
  macroag.macroag_desc,
  macroag.macroag_validita_inizio,
  macroag.macroag_validita_fine,
  missione.ente_proprietario_id
  from missione , programma,titusc, macroag, siac_r_class progmacro
  where programma.missione_id=missione.missione_id
  and titusc.titusc_id=macroag.titusc_id
  AND programma.programma_id = progmacro.classif_a_id
  AND titusc.titusc_id = progmacro.classif_b_id
  and titusc.ente_proprietario_id=missione.ente_proprietario_id
   ),
  capall as (
  with
  cap as (
  select a.elem_id,
  a.elem_code ,
  a.elem_desc ,
  a.elem_code2 ,
  a.elem_desc2 ,
  a.elem_id_padre ,
  a.elem_code3,
  d.classif_id programma_id,d2.classif_id macroag_id
  from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
  siac_r_bil_elem_class c2,
  siac_t_class d,siac_t_class d2,
  siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
  siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.bil_id=bilancio_id
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = 'CAP-UG'
  and c.elem_id=a.elem_id
  and c2.elem_id=a.elem_id
  and d.classif_id=c.classif_id
  and d2.classif_id=c2.classif_id
  and e.classif_tipo_id=d.classif_tipo_id
  and e2.classif_tipo_id=d2.classif_tipo_id
  and e.classif_tipo_code='PROGRAMMA'
  and e2.classif_tipo_code='MACROAGGREGATO'
  and g.elem_cat_id=f.elem_cat_id
  and f.elem_id=a.elem_id
  and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = 'VA'
  and h.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and c2.data_cancellazione is null
  and d.data_cancellazione is null
  and d2.data_cancellazione is null
  and e.data_cancellazione is null
  and e2.data_cancellazione is null
  and f.data_cancellazione is null
  and g.data_cancellazione is null
  and h.data_cancellazione is null
  and i.data_cancellazione is null
  ), 
  dati_prime_note as(
  WITH prime_note AS (
  SELECT d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  n.campo_pk_id,n.campo_pk_id_2,
  q.collegamento_tipo_code,
  b.livello
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_r_evento_reg_movfin n ON n.regmovfin_id = f.regmovfin_id
  INNER JOIN siac_d_evento p ON p.evento_id = n.evento_id
  INNER JOIN siac_d_collegamento_tipo q ON q.collegamento_tipo_id = p.collegamento_tipo_id
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   m.pnota_stato_code = 'D'
  AND   i.anno = p_anno_bilancio
  AND   d.pdce_fam_code in ('CE','RE')
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  AND   n.data_cancellazione IS NULL
  AND   p.data_cancellazione IS NULL
  AND   q.data_cancellazione IS NULL
  ), collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id
  FROM   siac_r_movgest_bil_elem a
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  /* 19/09/2017: SIAC-5216.
  	Si deve testare la data di fine validit? perch? (da mail di Irene):
     "a causa della doppia gestione che purtroppo non ? stata implementata sui documenti!!!! 
     E' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell'anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l'altro vediamo da sistema anche sul 2016).
Per cui l'unica soluzione ? recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non pi? valida."
  */
    --and a.data_cancellazione IS NULL
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id
  FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  ),
  /* 20/09/2017: SIAC-5216..
  	Aggiunto collegamento per estrarre il capitolo nel caso il documento
  	sia una nota di Credito.
    In questo caso occorre prendere l'impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (
  select c.elem_id, a.subdoc_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  --and a.subdoc_id=  54524
  AND b.ente_proprietario_id = p_ente_proprietario_id
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp('31/12/2016','dd/mm/yyyy')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
  -- COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),
  -- collegamento_SS_SE.elem_id,
  -- collegamento_I_A.elem_id,
  -- collegamento_SI_SA.elem_id
  -- collegamento_OP_OI.elem_id
  -- collegamento_L.elem_id
  -- collegamento_RR.elem_id
  -- collegamento_RE.elem_id
  --COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id) elem_id
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id
  FROM   prime_note
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RE'
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = prime_note.campo_pk_id_2
  										AND prime_note.collegamento_tipo_code IN ('SS','SE')                                       
  )                      
  select -- distinct
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,
  dati_prime_note.*
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id  
  )
  select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union all
    select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Avere',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union all
      select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Dare',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  ) as zz; 

  exception
  when no_data_found THEN
  raise notice 'nessun dato trovato per struttura bilancio';
  return;
  when others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
    
    
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5216 - FINE - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null)
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id 
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL    
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec := pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;

    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
    
    END IF;
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;