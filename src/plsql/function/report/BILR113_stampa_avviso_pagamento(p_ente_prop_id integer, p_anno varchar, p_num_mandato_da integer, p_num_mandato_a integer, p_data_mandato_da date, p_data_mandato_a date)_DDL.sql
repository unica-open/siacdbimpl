/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR113_stampa_avviso_pagamento" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date
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
  desc_causale varchar,
  desc_provvedimento varchar,
  estremi_provvedimento varchar,
  numero_fattura_completa varchar,
  num_fattura varchar,
  anno_fattura integer,
  importo_documento numeric,
  num_sub_doc_fattura integer,
  importo_fattura numeric,
  data_fattura date,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  benef_indirizzo varchar,
  benef_cap varchar,
  benef_localita varchar,
  benef_provincia varchar,
  desc_mod_pagamento varchar,
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
  cod_tributo varchar,
  resp_amm varchar,
  tit_miss_progr varchar,
  elenco_reversali varchar,
  split_reverse varchar,
  importo_split_reverse numeric,
  anno_primo_impegno varchar,
  display_error varchar,
  cod_stato_mandato varchar,
  banca_cc_bitalia varchar,
  tipo_doc varchar,
  num_doc_ncd varchar,
  importo_da_dedurre_ncd numeric,
  importo_irpeg_inponibile numeric,
  importo_netto_mandato numeric,
  cod_benef_cess_incasso varchar,
  desc_benef_cess_incasso varchar,
  codfisc_benef_cess_incasso varchar
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
lenFatturaApp INTEGER;

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
desc_causale='';
desc_provvedimento='';
estremi_provvedimento='';
num_fattura='';
anno_fattura=0;
importo_fattura =0;
data_fattura=NULL;
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
benef_indirizzo='';
benef_cap='';
benef_localita='';
benef_provincia='';
desc_mod_pagamento='';
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
importo_irpeg_inponibile=0;
cod_tributo='';
resp_amm='';
numero_fattura_completa='';
importo_documento=0;
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
importo_netto_mandato=0;
cod_benef_cess_incasso:='';
desc_benef_cess_incasso:='';
codfisc_benef_cess_incasso:='';


anno_eser_int=p_anno ::INTEGER;

display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A" E "DATA MANDATO DA/A".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;

/*
	I parametri non sono obbligatori ma almeno uno deve essere specificato.
*/
contaRecord=0;
for elencoMandati in
select 	distinct os.mif_ord_desc_ente, ep.codice_fiscale cod_fisc_ente, os.mif_ord_anno_esercizio,
		os.mif_ord_anno,  os.mif_ord_articolo,
        os.mif_ord_numero_imp, os.mif_ord_numero_subimp, os.mif_ord_importo,
        os.mif_ord_numero, os.mif_ord_data, os.mif_ord_disp_cassa,os.mif_ord_prev,
        os.mif_ord_mandati_prev, os.mif_ord_mandati_stanz, os.mif_ord_disponibilita,
        os.mif_ord_info_tesoriere, os.mif_ord_pagam_causale, 
        os.mif_ord_estremi_attoamm, os.mif_ord_codfisc_benef, os.mif_ord_partiva_benef,
        os.mif_ord_anag_benef, os.mif_ord_indir_benef, os.mif_ord_cap_benef,
        os.mif_ord_localita_benef, os.mif_ord_prov_benef, os.mif_ord_pagam_tipo,
        os.mif_ord_denom_banca_benef, os.mif_ord_abi_benef, os.mif_ord_cab_benef,
        os.mif_ord_cc_benef, os.mif_ord_cc_benef_estero, os.mif_ord_cc_postale_benef,
        os.mif_ord_bci_conto,
        os.mif_ord_cin_benef, os.mif_ord_iban_benef, os.mif_ord_swift_benef,
        os.mif_ord_anag_quiet, os.mif_ord_class_codice_cup, os.mif_ord_resp_attoamm,
         os.mif_ord_id,disp_ente.mif_ord_dispe_valore transaz_elementare,
        OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,
        os.mif_ord_siope_codice_cge, os.mif_ord_ord_id,os.mif_ord_codifica_bilancio,
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, t_doc.doc_numero, t_doc.doc_anno, t_doc.doc_importo,
        t_doc.doc_id, t_doc.doc_data_emissione data_fattura,
        t_subdoc.subdoc_numero, t_subdoc.subdoc_importo, d_doc_tipo.doc_tipo_code,
        t_ordinativo.ord_cast_emessi, t_ordinativo_ts.ord_ts_id,flusso_elab.flusso_elab_mif_id,
        flusso_elab.flusso_elab_mif_data, os.mif_ord_codice_funzione,
        flusso_elab_tipo.flusso_elab_mif_tipo_dec, flusso_elab_tipo.flusso_elab_mif_tipo_id
		FROM  	siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL,
                siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
				siac_t_bil_elem t_bil_elem,    
                siac_t_ordinativo t_ordinativo,   
                siac_d_ordinativo_tipo d_ordinativo_tipo, 
                mif_t_flusso_elaborato flusso_elab,	
                mif_d_flusso_elaborato_tipo flusso_elab_tipo,
        	mif_t_ordinativo_spesa    	os        	  
            LEFT JOIN mif_t_ordinativo_spesa_disp_ente disp_ente
            	ON (disp_ente.mif_ord_id=os.mif_ord_id   
            		AND disp_ente.mif_ord_dispe_nome='Transazione Elementare'  
                    AND  disp_ente.data_cancellazione IS NULL),                  
 			siac_t_ordinativo_ts t_ordinativo_ts
            LEFT JOIN  siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts   
            	ON  (r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id 
                	 AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL) 
            LEFT JOIN  siac_t_subdoc t_subdoc
            	ON  (t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                	 AND t_subdoc.data_cancellazione IS NULL)   
            LEFT JOIN  siac_t_doc 	t_doc
            	ON (t_doc.doc_id=  t_subdoc.doc_id
                	AND t_doc.data_cancellazione IS NULL)   
            LEFT JOIN siac_d_doc_tipo d_doc_tipo
            	ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                	AND d_doc_tipo.data_cancellazione IS NULL)                                                       
        WHERE  os.ente_proprietario_id=ep.ente_proprietario_id
        	AND OL.ente_proprietario_id=ep.ente_proprietario_id
            AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id 
            AND flusso_elab.flusso_elab_mif_id=os.mif_ord_flusso_elab_mif_id                               	
            AND  r_ordinativo_bil_elem.ord_id=os.mif_ord_ord_id
            AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
            AND t_ordinativo.ente_proprietario_id=os.ente_proprietario_id
            AND t_ordinativo_ts.ord_id=t_ordinativo.ord_id 
            AND t_ordinativo.ord_id=os.mif_ord_ord_id
            and flusso_elab_tipo.flusso_elab_mif_tipo_id=flusso_elab.flusso_elab_mif_tipo_id
            AND os.ente_proprietario_id= p_ente_prop_id                                           
            AND t_ordinativo.ord_anno=anno_eser_int 
            AND d_ordinativo_tipo.ord_tipo_code='P' /* PAGAMENTO */
            	 AND flusso_elab.flusso_elab_mif_esito='OK'
            AND ((p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
            		AND (os.mif_ord_numero ::INTEGER between  p_num_mandato_da 
                    AND p_num_mandato_a))
            	 OR (p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL)
            	 OR (p_num_mandato_a IS  NULL AND p_num_mandato_da IS NOT NULL
                	AND p_num_mandato_da=os.mif_ord_numero ::INTEGER )
                 OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS NOT NULL
                	AND p_num_mandato_a=os.mif_ord_numero ::INTEGER )) 
            AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL 
            	AND (to_date(os.mif_ord_data,'yyyy/MM/dd') between  p_data_mandato_da AND
                	p_data_mandato_a ))    
                OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
                OR (p_data_mandato_a IS NULL AND p_data_mandato_da IS NOT NULL
                	AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_mandato_da)
                OR (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL
                	AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_mandato_a))
                /* 22/02/2016: estraggo tutti i record con qualsiasi stato ma
                	prendo solo quello con la massima data di elaborazione
                    sulla tabella mif_t_flusso_elaborato, perche' potrei avere
                    un mandato con stato 'I' in un flusso e poi in stato 'A'
                    nel flusso successivo; in questo caso il record deve
                    essere escluso */        	
        	--AND os.mif_ord_codice_funzione ='I'  
            AND  flusso_elab.flusso_elab_mif_data = (select max(flusso_elab1.flusso_elab_mif_data)
            		FROM  mif_t_ordinativo_spesa    	os1,   
       					mif_t_flusso_elaborato flusso_elab1    
                    WHERE flusso_elab1.flusso_elab_mif_id=os1.mif_ord_flusso_elab_mif_id
                        AND os1.ente_proprietario_id = p_ente_prop_id
                        AND os1.mif_ord_numero= os.mif_ord_numero
                        AND os1.mif_ord_data=os.mif_ord_data          
                          AND flusso_elab.flusso_elab_mif_esito='OK'
                        AND os1.data_cancellazione IS NULL
                        AND flusso_elab1.data_cancellazione IS NULL)                                         
			AND os.data_cancellazione IS NULL
            AND ep.data_cancellazione IS NULL
            AND OL.data_cancellazione IS NULL
            AND r_ordinativo_bil_elem.data_cancellazione IS NULL
            AND t_bil_elem.data_cancellazione IS NULL
            AND t_ordinativo.data_cancellazione IS NULL      
            AND d_ordinativo_tipo.data_cancellazione IS NULL 
            AND t_ordinativo_ts.data_cancellazione IS NULL   
            AND flusso_elab.data_cancellazione IS NULL   
            AND flusso_elab_tipo.data_cancellazione IS NULL 
        		/* 28/01/2016: non e' necessario testare la data di
                	fine validita del flusso perche' e' sempre valorizzata */
            --AND flusso_elab.validita_fine IS NULL          
            order by os.mif_ord_numero, os.mif_ord_data, t_doc.doc_numero, t_subdoc.subdoc_numero
loop
contaRecord=contaRecord+1;
/* 18/03/2016: aggiunto il controllo sul flag flusso_elab_mif_tipo_dec:
	se e' true la stampa non puo' essere effettuata */
--raise notice 'Flusso: %, id_tipo_flusso: %, tipo_dec = %', elencoMandati.flusso_elab_mif_id,elencoMandati.flusso_elab_mif_tipo_id, elencoMandati.flusso_elab_mif_tipo_dec;
if elencoMandati.flusso_elab_mif_tipo_dec = true AND contaRecord=1 THEN
	display_error='Stampa avviso di pagamento (BILR113): STAMPA NON UTILIZZABILE.';
    return next;
    return;
end if;

--raise notice 'numero mandato %, mif_ord_id = % ',elencoMandati.mif_ord_numero, elencoMandati.mif_ord_id;


--raise notice 'mif_ord_ord_id = %, ord_ts_id = %, FLUSSO_ID= %, max_data= %, data_mandato = % ', elencoMandati.mif_ord_ord_id, elencoMandati.ord_ts_id, elencoMandati.flusso_elab_mif_id,elencoMandati.flusso_elab_mif_data,elencoMandati.mif_ord_data  ;

	 /* ci sono enti per cui lo stato non e' "I" ma "INSERIMENTO".
        Pertanto estraggo il primo carattere del campo mif_ord_codice_funzione
        per capire quali sono i record da inviare.
       la procedura restituisce solo i mandati validi  */
IF upper(substr(elencoMandati.mif_ord_codice_funzione,1,1))='I' THEN 
	cod_stato_mandato=upper(substr(elencoMandati.mif_ord_codice_funzione,1,1));
    tit_miss_progr=COALESCE(elencoMandati.mif_ord_codifica_bilancio,'');
    nome_ente=elencoMandati.mif_ord_desc_ente;
    partita_iva_ente=elencoMandati.cod_fisc_ente;
    anno_ese_finanz=elencoMandati.mif_ord_anno_esercizio;
    anno_capitolo=elencoMandati.mif_ord_anno;

    cod_capitolo=elencoMandati.cod_cap;
    cod_articolo=elencoMandati.cod_art;
    cod_gestione=COALESCE(elencoMandati.mif_ord_siope_codice_cge,''); 

    numero_mandato=elencoMandati.mif_ord_numero ::INTEGER;
    data_mandato=to_date(elencoMandati.mif_ord_data,'yyyy/MM/dd');

        /* tutti gli importi sono dei VARCHAR che devono quindi essere convertiti 
            NUMERIC e contengono le 2 cifre decimali.
            Pertanto i valori devono essere divisi per 100 */
    importo_lordo_mandato= COALESCE(elencoMandati.mif_ord_importo ::numeric,0) / 100;
    importo_stanz_cassa= COALESCE(elencoMandati.mif_ord_prev ::numeric,0) / 100;

        /* prendo gli importi EMESSI e DOPO EMISSIONE
            dall'ordinativo invece che dal MIF */
    --importo_tot_mandati_dopo_emiss= COALESCE(elencoMandati.mif_ord_mandati_prev ::numeric,0) / 100;
    --importo_tot_mandati_emessi=importo_tot_mandati_dopo_emiss-importo_lordo_mandato;

    importo_tot_mandati_emessi=COALESCE(elencoMandati.ord_cast_emessi,0);
    importo_tot_mandati_dopo_emiss=importo_tot_mandati_emessi+importo_lordo_mandato;
    importo_dispon= COALESCE(elencoMandati.mif_ord_disp_cassa ::numeric,0) / 100;

    desc_causale=COALESCE(elencoMandati.mif_ord_pagam_causale,'');

    benef_cod_fiscale=COALESCE(elencoMandati.mif_ord_codfisc_benef,'');
    benef_partita_iva=COALESCE(elencoMandati.mif_ord_partiva_benef,'');
    benef_nome=COALESCE(elencoMandati.mif_ord_anag_benef,'');
    benef_indirizzo=COALESCE(elencoMandati.mif_ord_indir_benef,'');
    benef_cap=COALESCE(elencoMandati.mif_ord_cap_benef,'');
    benef_localita=COALESCE(elencoMandati.mif_ord_localita_benef,'');
    benef_provincia=COALESCE(elencoMandati.mif_ord_prov_benef,'');

    banca_appoggio=COALESCE(elencoMandati.mif_ord_denom_banca_benef,'');
    banca_abi=COALESCE(elencoMandati.mif_ord_abi_benef,'');
    banca_cab=COALESCE(elencoMandati.mif_ord_cab_benef,'');
    banca_cc=COALESCE(elencoMandati.mif_ord_cc_benef,'');
    banca_cc_estero=COALESCE(elencoMandati.mif_ord_cc_benef_estero,'');
    banca_cc_posta=COALESCE(elencoMandati.mif_ord_cc_postale_benef,'');    	
    banca_cc_bitalia=COALESCE(elencoMandati.mif_ord_bci_conto,'');
    banca_cin=COALESCE(elencoMandati.mif_ord_cin_benef,'');

    banca_bic=COALESCE(elencoMandati.mif_ord_swift_benef,'');

    quietanzante=COALESCE(elencoMandati.mif_ord_anag_quiet,'');
    resp_amm=COALESCE(elencoMandati.ente_oil_resp_amm,'');


        /* cerco il codice del tipo atto amministrativo */
    appStr = elencoMandati.mif_ord_estremi_attoamm;
    posizione = position (' ' in appStr);
    if posizione > 0 THEN
        cod_atto_amm = substr(appStr,1, posizione-1);
        estremi_provvedimento = substr(appStr,posizione+1, char_length(appStr)-posizione);
        BEGIN
            SELECT atto.attoamm_tipo_desc
            INTO desc_provvedimento
            FROM siac_d_atto_amm_tipo atto
            WHERE atto.attoamm_tipo_code = cod_atto_amm
                AND atto.ente_proprietario_id = p_ente_prop_id
                AND atto.data_cancellazione IS NULL;
            IF NOT FOUND THEN
                desc_provvedimento='';
            END IF;
        END;
    else 
        desc_provvedimento='';
        estremi_provvedimento=elencoMandati.mif_ord_estremi_attoamm;
    END IF;

    --raise notice 'cerco impegni';
    /* cerco impegno e sub-impegno: potrebbero essere piu' di uno, quindi
        li cerco con un ciclo e li concateno. */
        BEGIN
        appStr='';
        numImpegnoApp='';
        numSubImpegnoApp='';
        numImpegno='';
        for elencoImpegni in
            SELECT disp_ente.mif_ord_dispe_valore    
            FROM mif_t_ordinativo_spesa_disp_ente disp_ente
            WHERE disp_ente.mif_ord_id= elencoMandati.mif_ord_id
                AND disp_ente.mif_ord_dispe_nome='Impegno quota mandato'
                AND disp_ente.ente_proprietario_id=p_ente_prop_id  
        loop
        
            appStr = elencoImpegni.mif_ord_dispe_valore;           
            posizione = position ('-' in appStr);
            if posizione > 0 THEN
                annoImpegno = substr(appStr,1, posizione-1);
                /* 11/02/2015: devo restituire l'anno dell'impegno perche' sulla stampa
                    devo distinguere tra COMPETENZA/RESIDUI.
                    Se ci sono piu' impegni restituisco solo il primo */
                if anno_primo_impegno='' THEN
                    anno_primo_impegno= annoImpegno;               
                end if;
              
                appStr = substr(appStr,posizione+1, char_length(appStr)-posizione);
              
                posizione = position ('-' in appStr);
                if posizione > 0 THEN
                    numImpegnoApp = substr(appStr,1, posizione-1);
                    numSubImpegnoApp = substr(appStr,posizione+1, char_length(appStr)-posizione);
                    if numImpegno = '' THEN
                        numImpegno=annoImpegno||'/'||numImpegnoApp||'/'||numSubImpegnoApp;
                    else
                        numImpegno=numImpegno||', '||annoImpegno||'/'||numImpegnoApp||'/'||numSubImpegnoApp;
                    end if;
                else
                    numImpegnoApp= appStr;
                    numSubImpegnoApp ='';
                    if numImpegno = '' THEN
                        numImpegno=annoImpegno||'/'||appStr;
                    else
                         numImpegno=numImpegno||', '||annoImpegno||'/'||appStr;
                    end if;
                END IF;
            ELSE
                numImpegnoApp='';
                numSubImpegnoApp='';
                --numImpegno='';
            END IF;
       
        numImpegnoApp='';  
        numSubImpegnoApp='';   
        
        end loop;
        
        END;        
    num_impegno =numImpegno;
    appStr='';

  /*  IF COALESCE(elencoMandati.doc_numero,'') != '' THEN
      num_fattura=COALESCE(elencoMandati.doc_numero,'');
      if COALESCE(elencoMandati.subdoc_numero,0) != 0 THEN
      	 num_fattura=num_fattura||'/'||elencoMandati.subdoc_numero;  
      end if;
      
    ELSE
      num_fattura='';
    END IF;*/
    
     IF COALESCE(elencoMandati.doc_numero,'') != '' THEN     	
    	numFatturaApp = COALESCE(elencoMandati.doc_numero,'');
        /* 26/10/2016: per problemi di visualizzazione nel report, nel caso 
           il numero fattura sia troppo lungo inserisco degli spazi
           in modo che il report possa portare a capo e non tagliare.
           GLi spazi sono inseriti solo se la stringa non contiene gia'
           spazi o / perche' in questo caso il report e' in grado di mettere
           a capo la stringa.  */
        IF position ('/' in numFatturaApp) = 0 AND
        	position(' ' in numFatturaApp) = 0  THEN
        
            raise notice 'num_fattura_orig = %',numFatturaApp;
            raise notice '/= %', position ('/' in numFatturaApp);
            --numFatturaApp ='1';
            lenFatturaApp = length(numFatturaApp);
            num_fattura='';                
            while lenFatturaApp > 0 loop
                if lenFatturaApp > 16 THEN
               -- raise notice 'SPEZZO';
                  --raise notice 'num_fattura_orig = %',numFatturaApp;
                  num_fattura=num_fattura||LEFT(numFatturaApp,16)|| ' ';
                  numFatturaApp = RIGHT(numFatturaApp,lenFatturaApp-16);
                  lenFatturaApp = length(numFatturaApp);
                  --raise notice 'num_fattura = %, lunghezza = %', num_fattura, length(num_fattura);
                  --raise notice 'numFatturaApp = %, lunghezza = %', numFatturaApp, lenFatturaApp;
                else
                    num_fattura=num_fattura||numFatturaApp;
                    lenFatturaApp=0;
                   -- raise notice 'num_fattura3 = %, lunghezza = %', num_fattura, length(num_fattura);
                    --raise notice 'numFatturaApp3 = %, lunghezza = %', numFatturaApp, lenFatturaApp;
                        
                end if;
            end loop;
        ELSE
        	 num_fattura=numFatturaApp;
        END IF;

      raise notice 'num_fattura = %',num_fattura;
      if COALESCE(elencoMandati.subdoc_numero,0) != 0 THEN
      	 num_fattura=num_fattura||'/'||elencoMandati.subdoc_numero; 
         raise notice 'num_fattura_quota = %',num_fattura; 
      end if;
		raise notice ' ';
      
    ELSE
      num_fattura='';
    END IF;
    
    
    
		/* 29/03/2016: aggiunto il tipo documento */
	tipo_doc=COALESCE(elencoMandati.doc_tipo_code,'');
    anno_fattura=COALESCE(elencoMandati.doc_anno,0);
    importo_fattura =COALESCE(elencoMandati.subdoc_importo,0);   
    importoSubDoc= COALESCE(elencoMandati.subdoc_importo,0);
    importo_documento=COALESCE(elencoMandati.doc_importo,0);  
    num_sub_doc_fattura=COALESCE(elencoMandati.subdoc_numero,0);
    data_fattura =COALESCE(elencoMandati.data_fattura, NULL);

		/* 29/03/2016: cerco le note di credito.
        	L'importo e' preso come somma del campo subdoc_importo_da_dedurre relativo
            a tutte le quote associate al mandato. */
	num_doc_ncd='';
	if elencoMandati.doc_id IS NOT NULL THEN
    	for elencoNoteCredito IN
        	SELECT r_doc.doc_id_a ,d_relaz_tipo.relaz_tipo_code,t_doc.doc_anno,
            	t_doc.doc_numero, t_doc.doc_importo, d_doc_tipo.doc_tipo_code
            FROM siac_r_doc r_doc, 
            		siac_d_relaz_tipo d_relaz_tipo,
                    siac_t_doc t_doc,
                    siac_d_doc_tipo d_doc_tipo
            WHERE r_doc.relaz_tipo_id=d_relaz_tipo.relaz_tipo_id
            	AND t_doc.doc_id=r_doc.doc_id_a
                AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                AND r_doc.doc_id_da = elencoMandati.doc_id
                AND d_relaz_tipo.relaz_tipo_code='NCD' -- note di credito
                AND r_doc.data_cancellazione IS NULL
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_doc.data_cancellazione IS NULL
                AND d_doc_tipo.data_cancellazione IS NULL
        loop
        	--raise notice '    NCD_ID = %', elencoNoteCredito.doc_id_a;
            if num_doc_ncd = '' THEN
            	num_doc_ncd=elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_numero;               
            else 
            	num_doc_ncd=num_doc_ncd||', '||elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_numero;               
            END IF;          
        end loop;
        if num_doc_ncd <> '' THEN             
            importo_da_dedurre_ncd=0;
            select  sum(t_subdoc.subdoc_importo_da_dedurre)
            INTO importo_da_dedurre_ncd
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
                siac_t_subdoc t_subdoc            
            where r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id
            AND t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            and t_ordinativo_ts.ord_id=elencoMandati.mif_ord_ord_id 
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL                                 
            group by t_ordinativo_ts.ord_id;
            IF NOT FOUND THEN
            	importo_da_dedurre_ncd=0;
            END IF;            
        end if;
    END IF;
    
    if elencoMandati.mif_ord_ord_id IS NOT NULL THEN
        
        /* L'IBAN deve essere estratto dalle modalita' di pagamento (non dal MIF),
            sia per bonifici italiani che esteri.            
            Cerco le modalita' di pagamento e IBAN*/
        BEGIN
            select d_accredito_tipo.accredito_tipo_desc, COALESCE(t_modpag.iban,'')
            INTO desc_mod_pagamento, banca_iban
            from siac_r_ordinativo_modpag r_ordinativo_modpag,
                siac_t_modpag t_modpag,
                siac_d_accredito_tipo d_accredito_tipo
            where r_ordinativo_modpag.modpag_id=t_modpag.modpag_id
              AND t_modpag.accredito_tipo_id=d_accredito_tipo.accredito_tipo_id
              AND r_ordinativo_modpag.ord_id= elencoMandati.mif_ord_ord_id
              AND t_modpag.ente_proprietario_id = p_ente_prop_id
              AND t_modpag.data_cancellazione IS NULL
              AND d_accredito_tipo.data_cancellazione IS NULL
              AND r_ordinativo_modpag.data_cancellazione IS NULL;
            IF NOT FOUND THEN
                desc_mod_pagamento='';    
                banca_iban='';    
            END IF;          
        END;    
                		        
			/* In caso di cessione di incasso su siac_r_ordinativo_modpag
            	non e' valorizzata la modalita' di pagamento.
                Devo cercare quella del soggetto a cui e' stato ceduto l'incasso. */
            /* 25/06/2018: SIAC-6217.
            	Aggiunti anche i dati del soggetto per valorizzare sul report
                il campo Beneficiario Amministrativo */
		IF desc_mod_pagamento='' THEN
        	--raise notice 'ORD_ID= %; IBAN: %',elencoMandati.mif_ord_ord_id, banca_iban;            
        	select d_accredito_tipo.accredito_tipo_desc, 
            COALESCE(t_modpag.iban,''),
            COALESCE(t_sogg.soggetto_code,''),
            COALESCE(t_sogg.soggetto_desc,''),
			COALESCE(t_sogg.codice_fiscale,'')
            INTO desc_mod_pagamento, banca_iban,
            	cod_benef_cess_incasso, desc_benef_cess_incasso,
				codfisc_benef_cess_incasso
            from siac_r_ordinativo_modpag r_ordinativo_modpag,
                siac_t_modpag t_modpag,
                siac_d_accredito_tipo d_accredito_tipo,
                siac_r_soggrel_modpag r_sogg_modpag,
                siac_r_soggetto_relaz r_sogg_relaz, 
                siac_t_soggetto t_sogg
            where r_ordinativo_modpag.soggetto_relaz_id=r_sogg_modpag.soggetto_relaz_id
              AND r_sogg_modpag.modpag_id=t_modpag.modpag_id
              AND t_modpag.accredito_tipo_id=d_accredito_tipo.accredito_tipo_id
              AND r_ordinativo_modpag.ord_id= elencoMandati.mif_ord_ord_id
              AND r_sogg_modpag.soggetto_relaz_id = r_sogg_relaz.soggetto_relaz_id
              AND t_sogg.soggetto_id = r_sogg_relaz.soggetto_id_a
              AND t_modpag.ente_proprietario_id = p_ente_prop_id
              AND t_modpag.data_cancellazione IS NULL
              AND d_accredito_tipo.data_cancellazione IS NULL
              AND r_ordinativo_modpag.data_cancellazione IS NULL
              AND r_sogg_modpag.data_cancellazione IS NULL;
            IF NOT FOUND THEN
                desc_mod_pagamento:='';    
                banca_iban:='';    
                cod_benef_cess_incasso:=''; 
                desc_benef_cess_incasso:=''; 
				codfisc_benef_cess_incasso:=''; 
            END IF; 
        END IF;        
        
        
--raise notice 'ID MAND=%, NUM MAND=%',  elencoMandati.mif_ord_ord_id, numero_mandato;        
            /* cerco l'eventuale REVERSALE ASSOCIATA */               
            /* 20/01/2016: le reversali possono essere piu' di 1 */
        BEGIN
          contaReversali=0;
          for elencoReversali in     
            select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord, r_doc_onere.doc_id,
                    r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
              		d_onere_tipo.onere_tipo_code, d_onere.onere_code
            from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                  siac_d_ordinativo_tipo d_ordinativo_tipo,
                  siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det, 
                  siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                  siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
             	  siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
              	  siac_d_onere_tipo  d_onere_tipo
                  where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                  	AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                  	AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                  	AND d_onere.onere_id=r_doc_onere.onere_id
                  	AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                    AND d_ordinativo_tipo.ord_tipo_code ='I'
                    AND ts_det_tipo.ord_ts_det_tipo_code='A'
                    --devo prendere solo quelli del doc???
                    AND r_doc_onere.doc_id= elencoMandati.doc_id
                        /* 29/01/2016: cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
               -- AND d_relaz_tipo.relaz_tipo_code='RIT_ORD'
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.mif_ord_ord_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
          loop
--raise notice 'Tipo rev=%, Importo rev=%, Imponibile=%' , elencoReversali.onere_tipo_code, elencoReversali.importo_ord, elencoReversali.importo_imponibile;          
            
            --raise notice 'Num mandato = % - ord_id =%; DOC_ID = %; DOC_ID_revers = %',elencoMandati.mif_ord_numero, elencoMandati.mif_ord_ord_id, elencoMandati.doc_id, elencoReversali.doc_id;
            contaReversali=contaReversali+1;
            importoReversale=elencoReversali.importo_ord;
                /* se il tipo di relazione e' SPR, e' SPLIT/REVERSE, carico l'importo */            
            if upper(elencoReversali.relaz_tipo_code)='SPR' THEN
                importo_split_reverse=importo_split_reverse+elencoReversali.importo_ord;
                if split_reverse = '' THEN
                    split_reverse=elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                else
                    split_reverse=split_reverse||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                end if;
            end if;
             /* 08/02/2016: anche split/reverse e' una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti (possono essere piu' di 1) */
              if elenco_reversali = '' THEN
                  elenco_reversali = elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              else
                  elenco_reversali = elenco_reversali||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              end if;
              /* 15/03/2016: utilizzando il legame con la tabella siac_r_doc_onere_ordinativo_ts
              	si puo' capire se la reversale ha un onere INPS/IRPEF e recuperarne
                gli importi */
              IF upper(elencoReversali.onere_tipo_code) = 'IRPEF' THEN
              	cod_tributo=elencoReversali.onere_code;
              	importo_irpef_imponibile= importo_irpef_imponibile+elencoReversali.importo_imponibile;
                importo_imposta=importo_imposta+elencoReversali.importo_ord;                
              elsif upper(elencoReversali.onere_tipo_code) = 'INPS' THEN
              	importo_inps_inponibile=importo_inps_inponibile+elencoReversali.importo_imponibile;
                importo_ritenuta=importo_ritenuta+elencoReversali.importo_ord;                
              elsif upper(elencoReversali.onere_tipo_code) = 'IRPEG' THEN
              	importo_irpeg_inponibile=importo_irpeg_inponibile+elencoReversali.importo_imponibile;
              END IF;
          end loop; 
        END;

		importo_netto=importo_fattura-importo_ritenuta-importo_imposta-importo_split_reverse;              
            

    --importo_ritenuta=COALESCE(elencoMandati.mif_ord_rit_importo ::numeric, 0); 
         /* dall'importo NETTO devo togliere anche 
            l'importo di SPLIT/REVERSE */
    importo_netto_mandato=importo_lordo_mandato-importo_ritenuta-importo_imposta-importo_split_reverse;
            
        
    END IF; --if elencoMandati.mif_ord_ord_id IS NOT NULL THEN

    return next;
    
end if; /* IF elencoMandati.mif_ord_codice_funzione='I' THEN */

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
desc_causale='';
desc_provvedimento='';
estremi_provvedimento='';
num_fattura='';
anno_fattura=0;
importo_fattura =0;
data_fattura=NULL;
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
benef_indirizzo='';
benef_cap='';
benef_localita='';
benef_provincia='';
desc_mod_pagamento='';
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
cod_tributo='';
resp_amm='';
numero_fattura_completa='';
importo_documento=0;
num_sub_doc_fattura=0;
numFatturaApp='';
elenco_reversali='';
split_reverse='';
importo_split_reverse=0;
anno_primo_impegno='';
cod_stato_mandato='';
tipo_doc='';
num_doc_ncd='';
importo_da_dedurre_ncd=0;
importo_irpeg_inponibile=0;

importoSubDoc=0;
importo_netto_mandato=0;
cod_benef_cess_incasso:='';
desc_benef_cess_incasso:='';
codfisc_benef_cess_incasso:='';

--raise notice 'fine numero mandato % ',elencoMandati.mif_ord_numero;
end loop;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

 
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