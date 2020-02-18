/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR107_mandato_di_pagamento_ABI36" (
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
elencoClass record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
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

cod_cofog VARCHAR;
cod_trans_europea VARCHAR;
cod_v_livello VARCHAR;
cod_programma VARCHAR;
ricorrente_spesa VARCHAR;
perimetro_sanitario VARCHAR;
politiche_reg_unitarie VARCHAR;
cod_siope VARCHAR;

id_liquidazione INTEGER;

tipoGestioneSiope VARCHAR;
paramSiope VARCHAR;
posizione integer;
strApp VARCHAR;
dataVerificaSiopeStr VARCHAR;
dataVerificaSiopeConfronto date;

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
ricorrente_spesa='';
perimetro_sanitario='';
politiche_reg_unitarie='';
cod_siope='';


importoSubDoc=0;

cod_cofog ='';
cod_trans_europea ='';
cod_v_livello ='';
cod_programma ='';
id_liquidazione=0;

tipoGestioneSiope ='';
paramSiope ='';
posizione =0;
strApp ='';
dataVerificaSiopeStr ='';
dataVerificaSiopeConfronto =NULL;

anno_eser_int=p_anno ::INTEGER;

	/* 22/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca */
    /* 11/07/2016: aggiunto il parametro relativo al
        numero distinta */
display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A", "DATA MANDATO DA/A" e "NUMERO DISTINTA".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;


/* 04/01/2017: occorre leggere il parametro flusso_elab_mif_param per capire
	come gestire il codice SIOPE.
    Questo parametro se correttamente configurato sarà del tipo: 
    	SIOPE_SPESA_I|XXXX|2099-01-01|PDC_V
	Il terzo parametro è una data che dovrà essere confrontata con la data del
    mandato.
    Se è la data mandato >= della data configurata allora il codice siope (usato
    per comporre la transaz_elementare) è equivalente al PDC_V senza
    la prima lettera e senza puntini.
    Se è la data mandato < della data configurata il codice siope è quello che
    era estratto in precedenza.
*/
select flusso_elab_mif_param 
INTO paramSiope
from mif_d_flusso_elaborato d
where d.ente_proprietario_id=p_ente_prop_id
and   d.flusso_elab_mif_code='codice_cge'
and   d.flusso_elab_mif_campo='mif_ord_siope_codice_cge'
and   d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and    t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine;
IF NOT FOUND THEN
		/* se il record non esiste imposto una data nel futuro per il
        	confronto. Gestione vecchia */
    dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
ELSE
	raise notice 'paramSiope = %', paramSiope;
    --paramSiope='SIOPE_SPESA_I|XXXX|2016-01-01|PDC_V';
	strApp = paramSiope;
    	-- cerco il primo | e tolgo SIOPE_SPESA_I
    posizione = position ('|' in strApp);
    if posizione > 0 THEN
    	strApp = substr(strApp,posizione+1,char_length(strApp)-1);
        --raise notice 'strApp1 = %', strApp;
        	-- cerco il secondo | e tolgo XXXX
        posizione = position ('|' in strApp);
        if posizione > 0 THEN
        		-- cerco il terzo | e trovo 2099-01-01|PDC_V
        	strApp = substr(strApp,posizione+1,char_length(strApp)-1);
             --raise notice 'strApp2 = %', strApp;
             posizione = position ('|' in strApp);
             if posizione > 0 THEN
             		-- cerco il quarto | ed estraggo la data 2099-01-01
             	dataVerificaSiopeStr = substr(strApp,1,posizione-1);
                --raise notice 'dataVerificaSiopeStr = %', dataVerificaSiopeStr;
                dataVerificaSiopeConfronto = to_date(dataVerificaSiopeStr,'yyyy-mm-dd');
             else -- manca l'ultimo param: imposto una nel futuro x il confronto
             	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
             end if;
        else -- manca la data: imposto una nel futuro x il confronto
        	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
        end if;
    else -- manca il primo param: imposto una nel futuro x il confronto
    	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
    end if;
END IF;

--dataVerificaSiopeConfronto = to_date('2016-01-01','yyyy-mm-dd');
raise notice 'dataVerificaSiopeConfronto = %', dataVerificaSiopeConfronto;


--	I parametri non sono obbligatori ma almeno uno deve essere specificato.
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
        os.mif_ord_bci_conto, os.mif_ord_anag_del, os.mif_ord_codfisc_del,
        os.mif_ord_cin_benef, os.mif_ord_iban_benef, os.mif_ord_swift_benef,
        os.mif_ord_class_codice_cup, os.mif_ord_resp_attoamm,
        os.mif_ord_id,disp_ente.mif_ord_dispe_valore transaz_elementare,
        OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,
        os.mif_ord_siope_codice_cge, os.mif_ord_ord_id,os.mif_ord_codifica_bilancio,
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, t_doc.doc_numero, t_doc.doc_anno, t_doc.doc_importo,
        t_doc.doc_id, 
        t_subdoc.subdoc_numero, t_subdoc.subdoc_importo, d_doc_tipo.doc_tipo_code,
        t_ordinativo.ord_cast_emessi, t_ordinativo_ts.ord_ts_id,flusso_elab.flusso_elab_mif_id,
        flusso_elab.flusso_elab_mif_data, os.mif_ord_codice_funzione,
        flusso_elab_tipo.flusso_elab_mif_tipo_dec, flusso_elab_tipo.flusso_elab_mif_tipo_id,
        os.mif_ord_codice_flusso_oil
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
          		/* 11/07/2016: aggiunto il parametro relativo al
                	numero distinta */
        	 AND ((p_numero_distinta IS NULL OR p_numero_distinta ='') OR
            	(p_numero_distinta IS NOT NULL 
           		AND	 os.mif_ord_codice_flusso_oil = p_numero_distinta))                    
                /* estraggo tutti i record con qualsiasi stato ma
                	prendo solo quello con la massima data di elaborazione
                    sulla tabella mif_t_flusso_elaborato, perchè potrei avere
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
        		/* 28/01/2016: non è necessario testare la data di
                	fine validita del flusso perchè è sempre valorizzata */
            --AND flusso_elab.validita_fine IS NULL          
            order by os.mif_ord_numero, os.mif_ord_data, t_doc.doc_numero, t_subdoc.subdoc_numero
loop
contaRecord=contaRecord+1;
/*  controllo il flag flusso_elab_mif_tipo_dec:
	se è false la stampa non può essere effettuata */
--raise notice 'Flusso: %, id_tipo_flusso: %, tipo_dec = %', elencoMandati.flusso_elab_mif_id,elencoMandati.flusso_elab_mif_tipo_id, elencoMandati.flusso_elab_mif_tipo_dec;
if elencoMandati.flusso_elab_mif_tipo_dec = false AND contaRecord=1 THEN
	display_error='Stampa giornaliera dei mandati di pagamento ABI36 (BILR107): STAMPA NON UTILIZZABILE.';
    return next;
    return;
end if;

--raise notice 'Distinta = %', elencoMandati.mif_ord_codice_flusso_oil;
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
   /* 04/01/2017: controllo se la data del mandato è >= della data di confronto
   		letta da parametro.
        Se lo è la gestione è di tipo NUOVO, altrimenti è di tipo VECCHIO */
	if data_mandato >= dataVerificaSiopeConfronto THEN
    	tipoGestioneSiope ='NEW';
    ELSE 
    	tipoGestioneSiope ='OLD';
    END IF;
    --raise notice 'tipoGestioneSiope = %', tipoGestioneSiope;
    
    importo_lordo_mandato= COALESCE(elencoMandati.mif_ord_importo ::numeric,0) ;
    importo_stanz_cassa= COALESCE(elencoMandati.mif_ord_prev ::numeric,0);

        /* prendo gli importi EMESSI e DOPO EMISSIONE
            dall'ordinativo invece che dal MIF */
    --importo_tot_mandati_dopo_emiss= COALESCE(elencoMandati.mif_ord_mandati_prev ::numeric,0) / 100;
    --importo_tot_mandati_emessi=importo_tot_mandati_dopo_emiss-importo_lordo_mandato;

    importo_tot_mandati_emessi=COALESCE(elencoMandati.ord_cast_emessi,0);
    importo_tot_mandati_dopo_emiss=importo_tot_mandati_emessi+importo_lordo_mandato;
    importo_dispon= COALESCE(elencoMandati.mif_ord_disp_cassa ::numeric,0);

    nome_tesoriere=COALESCE(elencoMandati.ente_oil_tes_desc,'');

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

		-- 20/06/2016: cambiato il campo relativo al quietanzante.
        --	concatenato anche l'eventuale CF.
    --quietanzante=COALESCE(elencoMandati.mif_ord_anag_quiet,'');
    quietanzante=COALESCE(elencoMandati.mif_ord_codfisc_del,'');
    if quietanzante <> '' THEN
    	quietanzante=quietanzante||' - ' ||COALESCE(elencoMandati.mif_ord_anag_del,'');
    else
    	quietanzante=COALESCE(elencoMandati.mif_ord_anag_del,'');
    end if;
    
    resp_sett_amm=COALESCE(elencoMandati.ente_oil_resp_ord,'');
    resp_amm=COALESCE(elencoMandati.ente_oil_resp_amm,'');


        /* cerco il codice del tipo atto amministrativo */
    appStr = elencoMandati.mif_ord_estremi_attoamm;
    posizione = position (' ' in appStr);
    if posizione > 0 THEN
        cod_atto_amm = substr(appStr,1, posizione-1);
        estremi_provvedimento = substr(appStr,posizione+1, char_length(appStr)-posizione);
        BEGIN
            SELECT COALESCE(atto.attoamm_tipo_desc,'')
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
        estremi_provvedimento=COALESCE(elencoMandati.mif_ord_estremi_attoamm,'');
    END IF;
    
	/* cerco gli impegni */
numImpegno='';
--raise notice 'NUM_MANDATO = %, ORD_ID = %',numero_mandato, elencoMandati.mif_ord_ord_id;
for elencoImpegni in	
 select d_ord_tipo.ord_tipo_code, t_ord_ts.ord_id, t_ord.ord_numero, t_ord.ord_anno,
                t_ord.ord_desc, 
                t_movgest.movgest_numero NUM_IMPEGNO, 
                t_movgest.movgest_anno ANNO_COMP_IMPEGNO,
                t_movgest_ts.movgest_ts_code NUM_SUBIMPEGNO
             FROM  siac_t_ordinativo t_ord,           
             siac_t_ordinativo_ts t_ord_ts,
              siac_d_ordinativo_tipo d_ord_tipo,
              siac_t_movgest t_movgest,
             siac_t_movgest_ts t_movgest_ts,                                      
              siac_r_liquidazione_ord r_liq_ord,
              siac_r_liquidazione_movgest r_liq_movgest
             where r_liq_ord.sord_id=t_ord_ts.ord_ts_id
             	and r_liq_movgest.movgest_ts_id= t_movgest_ts.movgest_ts_id
                AND r_liq_movgest.liq_id=r_liq_ord.liq_id
                and t_movgest.movgest_id=t_movgest_ts.movgest_id
                and t_ord.ord_id=t_ord_ts.ord_id
                and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                and t_ord_ts.ord_id = elencoMandati.mif_ord_ord_id
             	AND t_ord.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND d_ord_tipo.data_cancellazione IS NULL
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL
                AND r_liq_movgest.data_cancellazione IS NULL                  
		loop

        	if anno_primo_impegno='' THEN
            	anno_primo_impegno= elencoImpegni.ANNO_COMP_IMPEGNO;               
            end if;
            if numImpegno = '' THEN
            	numImpegno=elencoImpegni.ANNO_COMP_IMPEGNO||'/'||elencoImpegni.NUM_IMPEGNO;
            else
            	numImpegno=numImpegno||', '||elencoImpegni.ANNO_COMP_IMPEGNO||'/'||elencoImpegni.NUM_IMPEGNO;
            end if;
            if COALESCE(elencoImpegni.NUM_SUBIMPEGNO,'') <> COALESCE(elencoImpegni.NUM_IMPEGNO,0) ::VARCHAR THEN
				numImpegno = numImpegno||'/'||COALESCE(elencoImpegni.NUM_SUBIMPEGNO,'');
            end if;        
        end loop;
        num_impegno =numImpegno;


    IF COALESCE(elencoMandati.doc_numero,'') != '' THEN
      num_fattura=COALESCE(elencoMandati.doc_numero,'')||'/'||elencoMandati.subdoc_numero;  
    ELSE
      num_fattura='';
    END IF;
    		
	tipo_doc=COALESCE(elencoMandati.doc_tipo_code,'');
    anno_fattura=COALESCE(elencoMandati.doc_anno,0);
    importo_fattura =COALESCE(elencoMandati.subdoc_importo,0);   
    importoSubDoc= COALESCE(elencoMandati.subdoc_importo,0);
    importo_documento=COALESCE(elencoMandati.doc_importo,0);  
    num_sub_doc_fattura=COALESCE(elencoMandati.subdoc_numero,0);

		/* Cerco le note di credito.
        	L'importo è preso come somma del campo subdoc_importo_da_dedurre relativo
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
            	num_doc_ncd=elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_tipo_code||' - '||elencoNoteCredito.doc_numero;               
            else 
            	num_doc_ncd=num_doc_ncd||', '||elencoNoteCredito.doc_anno ||' - '||elencoNoteCredito.doc_tipo_code||' - '||elencoNoteCredito.doc_numero;               
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
            /* cerco il codice del bollo */
        BEGIN
            SELECT cod_bollo.codbollo_desc
            INTO bollo
            FROM siac_t_ordinativo ord
            FULL  join siac_d_codicebollo cod_bollo
                    on (cod_bollo.codbollo_id =ord.codbollo_id AND  cod_bollo.data_cancellazione IS NULL)   
            WHERE ord.ord_id = elencoMandati.mif_ord_ord_id
                AND ord.ente_proprietario_id = p_ente_prop_id
                AND cod_bollo.data_cancellazione IS NULL;
            IF NOT FOUND THEN
                bollo='';
            ELSIF bollo IS NULL OR bollo='' THEN
                bollo ='ESENTE BOLLO';
            END IF;
        END;
        
        /* 16/02/2016: prima si prendeva l'iban dal MIF che però lo valorizzava solo
            nel caso di bonifici esteri.
            Quindi l'IBAN deve essere estratto dalle modalità di pagamento,
            sia per bonifici italiani che esteri */
            
        --banca_iban=COALESCE(elencoMandati.mif_ord_iban_benef,'');
            /* cerco le modalità di pagamento */
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
                		
--raise notice 'ID MAND=%, NUM MAND=%',  elencoMandati.mif_ord_ord_id, numero_mandato;        
            -- cerco l'eventuale REVERSALE ASSOCIATA              
            -- le reversali possono essere più di 1 
        BEGIN
          contaReversali=0;
          for elencoReversali in     
            select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord,
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
                        -- cerco tutte le tipologie di relazione,non solo RIT_ORD
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
            contaReversali=contaReversali+1;
            importoReversale=elencoReversali.importo_ord;
                /* se il tipo di relazione è SPR, è SPLIT/REVERSE, carico l'importo */            
            if upper(elencoReversali.relaz_tipo_code)='SPR' THEN
                importo_split_reverse=importo_split_reverse+elencoReversali.importo_ord;
                if split_reverse = '' THEN
                    split_reverse=elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                else
                    split_reverse=split_reverse||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                end if;
            end if;
             /*  anche split/reverse è una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti (possono essere più di 1) */
              if elenco_reversali = '' THEN
                  elenco_reversali = elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              else
                  elenco_reversali = elenco_reversali||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              end if;
              /*  utilizzando il legame con la tabella siac_r_doc_onere_ordinativo_ts
              	si può capire se la reversale ha un onere INPS/IRPEF e recuperarne
                gli importi */
              IF upper(elencoReversali.onere_tipo_code) = 'IRPEF' THEN
              	cod_tributo=elencoReversali.onere_code;
              	importo_irpef_imponibile= elencoReversali.importo_imponibile;
                importo_imposta=elencoReversali.importo_ord;
              elsif upper(elencoReversali.onere_tipo_code) = 'INPS' THEN
              	importo_inps_inponibile=elencoReversali.importo_imponibile;
                importo_ritenuta=elencoReversali.importo_ord;
              END IF;
          end loop; 
        END;
               
         /* dall'importo NETTO devo togliere anche 
            l'importo di SPLIT/REVERSE */
    importo_netto=importo_lordo_mandato-importo_ritenuta-importo_imposta-importo_split_reverse;
            
        -- BEGIN
            cig ='';
            cup ='';
                /* cerco le liquidazioni per prendere i reltivi CIG e CUP*/
            for elencoLiquidazioni IN
                SELECT t_attr.attr_code, r_liquidazione_attr.testo  ,
                          liquidazione.liq_id
                FROM siac_t_liquidazione	liquidazione, 
                    siac_r_liquidazione_ord r_liqu_ord,
                    siac_r_liquidazione_attr r_liquidazione_attr,
                    siac_t_attr t_attr                                                
                WHERE liquidazione.liq_id=r_liqu_ord.liq_id
                    AND r_liquidazione_attr.liq_id=liquidazione.liq_id
                    AND t_attr.attr_id=r_liquidazione_attr.attr_id                                
                    AND upper(t_attr.attr_code) in ('CIG','CUP')   
                   AND r_liqu_ord.sord_id=   elencoMandati.ord_ts_id   
                   AND  liquidazione.data_cancellazione IS NULL   
                   AND  r_liquidazione_attr.data_cancellazione IS NULL 
                   AND  t_attr.data_cancellazione IS NULL 
            loop 
                if upper(elencoLiquidazioni.attr_code) = 'CIG' THEN
                    if cig ='' THEN
                        cig=elencoLiquidazioni.testo;
                    else
                        cig=cig||', ' || elencoLiquidazioni.testo;
                    end if;
                else /* CUP */
                    if cup ='' THEN
                        cup=elencoLiquidazioni.testo;
                    else
                        cup=cup||', ' || elencoLiquidazioni.testo;
                    end if;          
                end if;  
            end loop;
         --END;
    else 
        bollo='';
        desc_mod_pagamento='';
        cup='';
        cig='';
    END IF; --if elencoMandati.mif_ord_ord_id IS NOT NULL THEN

   -- transaz_elementare=COALESCE(elencoMandati.transaz_elementare,'');
   
   	/* cerco i dati della transazione elementare */
    /* x il PROGRAMMA accedo x ID capitolo */
   	for elencoClass in 
          select distinct d_class_tipo.classif_tipo_code, t_class.classif_code
          from siac_t_class t_class,
           		siac_d_class_tipo d_class_tipo,
           		siac_r_bil_elem_class r_bil_elem_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_bil_elem_class.classif_id=t_class.classif_id
              and r_bil_elem_class.elem_id=elencoMandati.elem_id
              and d_class_tipo.classif_tipo_code IN ('PROGRAMMA')
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and r_bil_elem_class.data_cancellazione IS NULL
        loop
          if elencoClass.classif_tipo_code ='PROGRAMMA' THEN
          	cod_programma=elencoClass.classif_code;
          	--raise notice 'CAP_ID = % CAP % - PROGRAMMA = %', elencoMandati.elem_id, cod_capitolo, elencoClass.classif_code;          
          end if;
    end loop;
         
    /* x COFOG/TRANSAZIONE_EU/PDC_V accedo x ID ordinativo */
	for elencoClass in 
          select distinct d_class_tipo.*, t_class.*
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_ordinativo_class r_ordinativo_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_ordinativo_class.classif_id=t_class.classif_id
              and r_ordinativo_class.ord_id = elencoMandati.mif_ord_ord_id
              --and d_class_tipo.classif_tipo_code IN ('GRUPPO_COFOG',
              --	'TRANSAZIONE_UE_SPESA',  'PDC_V')
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and r_ordinativo_class.data_cancellazione IS NULL
        loop
          IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
          	cod_cofog=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' THEN
          	cod_trans_europea=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='PDC_V' THEN
          	cod_v_livello=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' THEN
          	ricorrente_spesa=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' THEN
          	perimetro_sanitario=elencoClass.classif_code;            
          elsif elencoClass.classif_tipo_code ='POLITICHE_REGIONALI_UNITARIE' THEN
          	politiche_reg_unitarie=elencoClass.classif_code;   
          elsif substr(elencoClass.classif_tipo_code,1,11) ='SIOPE_SPESA' THEN
            cod_siope=elencoClass.classif_code;                                   
          end if;                  
        end loop;
        
        /* 04/01/2017: se la gestione è di tipo NUOVO il codice SIOPE per la
        	transazione elementare equivale al PDC_V senza la prima lettera e
            senza puntini */
        if tipoGestioneSiope = 'NEW' THEN        	
            if cod_v_livello <> '' THEN
        		cod_siope =  replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');
            else
            	cod_siope = ''; 
            end if;
        end if;
        --raise notice 'SIOPE_SPESA1 = %, PDC_V1 = %', cod_siope,cod_v_livello;
        
--raise notice 'COFOG = %, UE_SPESE = %, PDC_V = %', cod_cofog, cod_trans_europea,cod_v_livello;
--raise notice 'RICORRENTE_SPESA = %, PERIM_SANIT = %, POLI_REG = %, SIOPE_SPESA = %', ricorrente_spesa, perimetro_sanitario,politiche_reg_unitarie, cod_siope;
        /* se uno degli elementi della transazione non è valorizzato
        	 per l'ordinativo devo estrarre quelli della liquidazione */
    if cod_cofog='' OR cod_trans_europea='' OR cod_v_livello = '' OR
    	ricorrente_spesa='' OR perimetro_sanitario ='' OR
        politiche_reg_unitarie='' OR cod_siope= '' THEN
		for elencoClass in 
          select distinct d_class_tipo.*, t_class.*
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_liquidazione_class r_liquidazione_class,
            siac_r_liquidazione_ord r_liq_ord 
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_liquidazione_class.classif_id=t_class.classif_id
              and r_liq_ord.liq_id=r_liquidazione_class.liq_id
              and r_liq_ord.liq_ord_id = elencoMandati.mif_ord_ord_id
             -- and d_class_tipo.classif_tipo_code IN ('PDC_V')
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and r_liquidazione_class.data_cancellazione IS NULL
              and r_liq_ord.data_cancellazione IS NULL
        	loop
              IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' AND 
              		cod_cofog = '' THEN
                cod_cofog=elencoClass.classif_code;
              elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' AND
              		cod_trans_europea = '' THEN
                cod_trans_europea=elencoClass.classif_code;
              elsif elencoClass.classif_tipo_code ='PDC_V' AND 
              		cod_v_livello = '' THEN
                cod_v_livello=elencoClass.classif_code;
              elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' AND
              		ricorrente_spesa = '' THEN
                ricorrente_spesa=elencoClass.classif_code;
              elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' AND 
              		perimetro_sanitario = '' THEN
                perimetro_sanitario=elencoClass.classif_code;            
              elsif elencoClass.classif_tipo_code ='POLITICHE_REGIONALI_UNITARIE' AND
              		politiche_reg_unitarie = ''  THEN
                politiche_reg_unitarie=elencoClass.classif_code;   
              elsif substr(elencoClass.classif_tipo_code,1,11) ='SIOPE_SPESA' AND
              		cod_siope = '' THEN
                cod_siope=elencoClass.classif_code;    
          	  end if;        
	        end loop;
          /* 04/01/2017: se la gestione è di tipo NUOVO il codice SIOPE per la
        	transazione elementare equivale al PDC_V senza la prima lettera e
            senza puntini */
            if tipoGestioneSiope = 'NEW' THEN
            	if cod_v_livello <> '' THEN
        			cod_siope =  replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');
                else
            		cod_siope = ''; 
            	end if;
        	end if;
            --raise notice 'SIOPE_SPESA2 = %, PDC_V2 = %', cod_siope,cod_v_livello;
        end if; 
--raise notice 'COFOG1 = %, UE_SPESE = %, PDC_V = %', cod_cofog, cod_trans_europea,cod_v_livello;
--raise notice 'RICORRENTE_SPESA1 = %, PERIM_SANIT = %, POLI_REG = %, SIOPE_SPESA = %', ricorrente_spesa, perimetro_sanitario,politiche_reg_unitarie, cod_siope;
        
       --transaz_elementare=cod_programma||'-'||cod_v_livello||'-'||cod_trans_europea||'-' ||cod_cofog;
		
        transaz_elementare=cod_programma;
        if cod_v_livello <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||cod_v_livello;
            else
            	transaz_elementare=cod_v_livello;
            end if;
        end if;
        if cod_cofog <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||cod_cofog;
            else
            	transaz_elementare=cod_cofog;
            end if;
        end if;
        if cod_trans_europea <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||cod_trans_europea;
            else
            	transaz_elementare=cod_trans_europea;
            end if;
        end if;
        if cod_siope <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||cod_siope;
            else
            	transaz_elementare=cod_siope;
            end if;
        end if;     
        if cup <> '' THEN -- è quello estratto dagli attributi della liquidazione
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||cup;
            else
            	transaz_elementare=cup;
            end if;
        end if;      
        if ricorrente_spesa <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||ricorrente_spesa;
            else
            	transaz_elementare=ricorrente_spesa;
            end if;
        end if;       
        if perimetro_sanitario <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||perimetro_sanitario;
            else
            	transaz_elementare=perimetro_sanitario;
            end if;
        end if;     
        if politiche_reg_unitarie <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||politiche_reg_unitarie;
            else
            	transaz_elementare=politiche_reg_unitarie;
            end if;
        end if;     
                                  
    return next;

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
num_sub_doc_fattura=0;
numFatturaApp='';
transaz_elementare='';
elenco_reversali='';
split_reverse='';
importo_split_reverse=0;
anno_primo_impegno='';
cod_stato_mandato='';
tipo_doc='';
num_doc_ncd='';
importo_da_dedurre_ncd=0;

importoSubDoc=0;

cod_cofog ='';
cod_trans_europea ='';
cod_v_livello ='';
cod_programma ='';

ricorrente_spesa='';
perimetro_sanitario='';
politiche_reg_unitarie='';
cod_siope='';

id_liquidazione=0;
tipoGestioneSiope ='';

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