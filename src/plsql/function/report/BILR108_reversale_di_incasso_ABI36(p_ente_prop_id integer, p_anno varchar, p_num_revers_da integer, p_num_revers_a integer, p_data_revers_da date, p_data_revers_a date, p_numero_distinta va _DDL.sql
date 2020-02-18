/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR108_reversale_di_incasso_ABI36" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_revers_da integer,
  p_num_revers_a integer,
  p_data_revers_da date,
  p_data_revers_a date,
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
  num_accertamento varchar,
  num_subimpegno varchar,
  importo_lordo_reversale numeric,
  numero_reversale integer,
  data_reversale date,
  importo_stanz_cassa numeric,
  importo_tot_reversali_emessi numeric,
  importo_tot_reversali_dopo_emiss numeric,
  importo_dispon numeric,
  nome_tesoriere varchar,
  desc_causale varchar,
  num_fattura varchar,
  anno_fattura integer,
  importo_fattura numeric,
  versante_cod_fiscale varchar,
  versante_partita_iva varchar,
  versante_nome varchar,
  versante_indirizzo varchar,
  versante_cap varchar,
  versante_localita varchar,
  versante_provincia varchar,
  importo_netto numeric,
  resp_sett_amm varchar,
  tit_tipo_categ varchar,
  transaz_elementare varchar,
  resp_amm varchar,
  anno_primo_accertamento varchar,
  display_error varchar,
  cod_stato_reversale varchar
) AS
$body$
DECLARE
elencoReversali record;
elencoAccertamenti record;
elencoOneri record;
elencoClass record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
appStr VARCHAR;
numAccertApp VARCHAR;
numSubAccertApp VARCHAR;
numAccert VARCHAR;
annoAccertamento VARCHAR;
importo_ritenuta NUMERIC;
importo_imposta NUMERIC;
anno_eser_int INTEGER;
contaRecord INTEGER;

cod_cofog VARCHAR;
cod_trans_europea VARCHAR;
cod_v_livello VARCHAR;
cod_trans_elem VARCHAR;
ricorrente_entrata VARCHAR;
perimetro_sanit_entrata VARCHAR;
cod_siope VARCHAR;

tipoGestioneSiope VARCHAR;
paramSiope VARCHAR;
posizione integer;
strApp VARCHAR;
dataVerificaSiopeStr VARCHAR;
dataVerificaSiopeConfronto date;

id_liquidazione INTEGER;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
cod_gestione='';
num_accertamento='';
num_subimpegno='';
importo_lordo_reversale=0;
numero_reversale=0;
data_reversale=NULL;
importo_stanz_cassa=0;
importo_tot_reversali_emessi=0;
importo_tot_reversali_dopo_emiss=0;
importo_dispon=0;
nome_tesoriere='';
desc_causale='';
num_fattura='';
anno_fattura=0;
importo_fattura=0;
versante_cod_fiscale='';
versante_partita_iva='';
versante_nome='';
versante_indirizzo='';
versante_cap='';
versante_localita='';
versante_provincia='';
importo_netto=0;
resp_sett_amm='';
transaz_elementare='';
importo_ritenuta=0;
importo_imposta=0;
resp_amm='';
tit_tipo_categ='';
anno_primo_accertamento='';
cod_stato_reversale='';

cod_cofog ='';
cod_trans_europea ='';
cod_v_livello ='';
cod_trans_elem ='';
ricorrente_entrata='';
perimetro_sanit_entrata='';
cod_siope='';

tipoGestioneSiope ='';
paramSiope ='';
posizione =0;
strApp ='';
dataVerificaSiopeStr ='';
dataVerificaSiopeConfronto =NULL;

id_liquidazione=0;

anno_eser_int=p_anno ::INTEGER;

	/* 22/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca */
    /* 11/07/2016: aggiunto il parametro relativo al
        numero distinta */        
display_error='';
if p_num_revers_da IS NULL AND p_num_revers_a IS NULL AND p_data_revers_da IS NULL AND
	p_data_revers_a IS NULL AND
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO REVERSALE DA/A", "DATA REVERSALE DA/A e "NUMERO DISTINTA".';
    return next;
    return;
end if;


/* 04/01/2017: occorre leggere il parametro flusso_elab_mif_param per capire
	come gestire il codice SIOPE.
    Questo parametro se correttamente configurato sarà del tipo: 
    	SIOPE_SPESA_I|XXXX|2099-01-01|PDC_V
	Il terzo parametro è una data che dovrà essere confrontata con la data 
    della reversale.
    Se è la data reversale >= della data configurata allora il codice siope 
    (usato per comporre la transaz_elementare) è equivalente al PDC_V senza
    la prima lettera e senza puntini.
    Se è la data reversale < della data configurata il codice siope è quello 
    che era estratto in precedenza.
    I record potrebbero essere più di 1, ma il contenuto del campo 
    flusso_elab_mif_param sarà identico.
*/
select flusso_elab_mif_param 
INTO paramSiope
from mif_d_flusso_elaborato_tipo  t, mif_d_flusso_elaborato d
where d.ente_proprietario_id=p_ente_prop_id
and   t.flusso_elab_mif_tipo_code='REVMIF'
and   d.ente_proprietario_id=t.ente_proprietario_id
and   d.flusso_elab_mif_tipo_id=t.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='codice_cge'
order by d.ente_proprietario_id,d.flusso_elab_mif_ordine;
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
                raise notice 'dataVerificaSiopeStr = %', dataVerificaSiopeStr;
                dataVerificaSiopeConfronto = to_date(dataVerificaSiopeStr,'yyyy-mm-dd');
             else 
             	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
             end if;
        else
        	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
        end if;
    else
    	 dataVerificaSiopeConfronto = to_date('2099-01-01','yyyy-mm-dd');
    end if;
END IF;

raise notice 'dataVerificaSiopeConfronto = %', dataVerificaSiopeConfronto;

RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;

--	I parametri non sono obbligatori ma almeno uno deve essere specificato.
contaRecord=0;
for elencoReversali in	 
select DISTINCT	os.mif_ord_desc_ente, ep.codice_fiscale cod_fisc_ente, os.mif_ord_anno_esercizio,
		os.mif_ord_anno, os.mif_ord_codifica_bilancio, os.mif_ord_articolo,
        os.mif_ord_numero_acc, 
        os.mif_ord_importo, os.mif_ord_id,
        os.mif_ord_numero, os.mif_ord_data, os.mif_ord_siope_codice_cge,
        os.mif_ord_info_tesoriere, os.mif_ord_vers_causale, os.mif_ord_ord_id,
        os.mif_ord_codfisc_versante, os.mif_ord_partiva_versante,
        os.mif_ord_anag_versante, os.mif_ord_indir_versante, os.mif_ord_cap_versante,
        os.mif_ord_localita_versante, os.mif_ord_prov_versante, t_bil_elem.elem_id,
        t_bil_elem.elem_code, t_bil_elem.elem_code2,
        t_ordinativo.ord_cast_emessi, t_ordinativo.ord_cast_cassa,
        OL.ente_oil_resp_ord,disp_ente.mif_ord_dispe_valore transaz_elementare,
        t_ordinativo.ord_cast_competenza, t_doc.doc_numero num_fattura,
        t_doc.doc_importo importo_fattura, t_doc.doc_anno anno_fattura,
        t_subdoc.subdoc_importo importo_subdoc, t_subdoc.subdoc_numero num_subdoc,
        OL.ente_oil_resp_amm, OL.ente_oil_tes_desc, flusso_elab.flusso_elab_mif_id,
        flusso_elab.flusso_elab_mif_data, os.mif_ord_codice_funzione,
        flusso_elab_tipo.flusso_elab_mif_tipo_dec, flusso_elab_tipo.flusso_elab_mif_tipo_id,
        os.mif_ord_codice_flusso_oil
		FROM  	siac_t_ente_proprietario ep,        	  
            siac_t_ente_oil OL, 
            siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
            siac_t_ordinativo t_ordinativo,            
            siac_d_ordinativo_tipo d_ordinativo_tipo,
			siac_t_bil_elem t_bil_elem   ,
            mif_t_flusso_elaborato flusso_elab,	
            mif_d_flusso_elaborato_tipo flusso_elab_tipo,
            mif_t_ordinativo_entrata    	os 
            LEFT JOIN mif_t_ordinativo_entrata_disp_ente disp_ente
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
        WHERE  os.ente_proprietario_id=ep.ente_proprietario_id
        	AND OL.ente_proprietario_id=ep.ente_proprietario_id 
            AND flusso_elab.flusso_elab_mif_id=os.mif_ord_flusso_elab_mif_id
        	AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id 
            AND  r_ordinativo_bil_elem.ord_id=os.mif_ord_ord_id
            AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
            AND t_ordinativo.ente_proprietario_id=os.ente_proprietario_id
            AND t_ordinativo_ts.ord_id=t_ordinativo.ord_id          
            AND t_ordinativo.ord_id=os.mif_ord_ord_id
            and flusso_elab_tipo.flusso_elab_mif_tipo_id=flusso_elab.flusso_elab_mif_tipo_id
            AND t_ordinativo.ord_anno=anno_eser_int
            AND d_ordinativo_tipo.ord_tipo_code='I' /* INCASSO */   
        	AND os.ente_proprietario_id= p_ente_prop_id              
             AND flusso_elab.flusso_elab_mif_esito='OK'                 	
           AND ((p_num_revers_da IS NOT NULL AND p_num_revers_a IS NOT NULL
            		AND (os.mif_ord_numero ::INTEGER between  p_num_revers_da 
                    AND p_num_revers_a))
            	 OR (p_num_revers_da IS NULL AND p_num_revers_a IS NULL)
            	 OR (p_num_revers_a IS  NULL AND p_num_revers_da IS NOT NULL
                	AND p_num_revers_da=os.mif_ord_numero ::INTEGER )
                 OR (p_num_revers_da IS  NULL AND p_num_revers_a IS NOT NULL
                	AND p_num_revers_a=os.mif_ord_numero ::INTEGER )) 
            AND ((p_data_revers_da IS NOT NULL AND p_data_revers_a IS NOT NULL 
            	AND (to_date(os.mif_ord_data,'yyyy/MM/dd') between  p_data_revers_da AND
                	p_data_revers_a ))    
                OR (p_data_revers_da IS  NULL AND p_data_revers_a IS  NULL)
                OR (p_data_revers_a IS NULL AND p_data_revers_da IS NOT NULL
                	AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_revers_da)
                OR (p_data_revers_da IS NULL AND p_data_revers_a IS NOT NULL
                	AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_revers_a))
          		/* 11/07/2016: aggiunto il parametro relativo al
                	numero distinta */
        	 AND ((p_numero_distinta IS NULL OR p_numero_distinta ='') OR
            	(p_numero_distinta IS NOT NULL 
           		AND	 os.mif_ord_codice_flusso_oil = p_numero_distinta))                      
			/* estraggo tutti i record con qualsiasi stato ma
                	prendo solo quello con la massima data di elaborazione
                    sulla tabella mif_t_flusso_elaborato, perchè potrei avere
                    una reversale con stato 'I' in un flusso e poi in stato 'A'
                    nel flusso successivo; in questo caso il record deve
                    essere escluso */                        
        	--AND os.mif_ord_codice_funzione='I'    
            AND  flusso_elab.flusso_elab_mif_data = (select max(flusso_elab1.flusso_elab_mif_data)
            		FROM  mif_t_ordinativo_entrata   	os1,   
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
            AND t_ordinativo.data_cancellazione IS NULL
            AND r_ordinativo_bil_elem.data_cancellazione IS NULL   
            AND d_ordinativo_tipo.data_cancellazione IS NULL  
            AND t_bil_elem.data_cancellazione IS NULL      
            AND flusso_elab.data_cancellazione IS NULL 
            AND t_ordinativo_ts.data_cancellazione IS NULL
            order by os.mif_ord_numero, os.mif_ord_data, t_doc.doc_numero, t_subdoc.subdoc_numero
loop
contaRecord=contaRecord+1;
/*  controllo il flag flusso_elab_mif_tipo_dec:
	se è false la stampa non può essere effettuata */
  if elencoReversali.flusso_elab_mif_tipo_dec = false AND contaRecord=1 THEN
	display_error='Stampa giornaliera delle reversali di incasso ABI36 (BILR108): STAMPA NON UTILIZZABILE.';
    return next;
    return;
end if;
--raise notice 'Distinta = %', elencoReversali.mif_ord_codice_flusso_oil;
	cod_stato_reversale=upper(substr(elencoReversali.mif_ord_codice_funzione,1,1));
    tit_tipo_categ=COALESCE(elencoReversali.mif_ord_codifica_bilancio,'');
	
    --raise notice 'cerco accertamento';
    /* cerco accertamento e sub-accertamento: potrebbero essere più di uno, quindi
        li cerco con un ciclo e li concateno. */  
    numAccert='';      
	for elencoAccertamenti in
		select d_ord_tipo.ord_tipo_code, t_ord_ts.ord_id, t_ord.ord_numero, 
        		t_ord.ord_anno, t_ord.ord_desc, 
                t_movgest.movgest_numero NUM_REVERSALE, 
                t_movgest.movgest_anno ANNO_COMP_REVERSALE,
                t_movgest_ts.movgest_ts_code NUM_SUBREVERSALE
             FROM  siac_t_ordinativo t_ord,           
             siac_t_ordinativo_ts t_ord_ts,
              siac_d_ordinativo_tipo d_ord_tipo,
              siac_t_movgest t_movgest,
             siac_t_movgest_ts t_movgest_ts,                                      
              siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts
             where r_ord_ts_movgest_ts.ord_ts_id=t_ord_ts.ord_ts_id
             	and r_ord_ts_movgest_ts.movgest_ts_id= t_movgest_ts.movgest_ts_id                
                and t_movgest.movgest_id=t_movgest_ts.movgest_id
                and t_ord.ord_id=t_ord_ts.ord_id
                and d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
                and t_ord_ts.ord_id = elencoReversali.mif_ord_ord_id
             	AND t_ord.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND d_ord_tipo.data_cancellazione IS NULL
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND r_ord_ts_movgest_ts.data_cancellazione IS NULL               
		loop

        	if anno_primo_accertamento='' THEN
            	anno_primo_accertamento= elencoAccertamenti.ANNO_COMP_REVERSALE;               
            end if;
            if numAccert = '' THEN
            	numAccert=elencoAccertamenti.ANNO_COMP_REVERSALE||'/'||elencoAccertamenti.NUM_REVERSALE;
            else
            	numAccert=numAccert||', '||elencoAccertamenti.ANNO_COMP_REVERSALE||'/'||elencoAccertamenti.NUM_REVERSALE;
            end if;
            if COALESCE(elencoAccertamenti.NUM_SUBREVERSALE,'') <> COALESCE(elencoAccertamenti.NUM_REVERSALE,0) ::VARCHAR THEN
				numAccert = numAccert||'/'||COALESCE(elencoAccertamenti.NUM_SUBREVERSALE,'');
            end if;        
        end loop;
        
        num_accertamento =numAccert;       
                
   
    appStr='';


    nome_ente=elencoReversali.mif_ord_desc_ente;
    partita_iva_ente=elencoReversali.cod_fisc_ente;
    anno_ese_finanz=elencoReversali.mif_ord_anno_esercizio;
    anno_capitolo=elencoReversali.mif_ord_anno;
    cod_capitolo=elencoReversali.elem_code;
    --cod_articolo=elencoReversali.mif_ord_articolo;
    cod_articolo=elencoReversali.elem_code2;
    cod_gestione=COALESCE(elencoReversali.mif_ord_siope_codice_cge,''); 


    numero_reversale=elencoReversali.mif_ord_numero ::integer;
    data_reversale=elencoReversali.mif_ord_data;
   /* 04/01/2017: controllo se la data della reversale è >= della data di confronto
   		letta da parametro.
        Se lo è la gestione è di tipo NUOVO, altrimenti è di tipo VECCHIO */
	if data_reversale >= dataVerificaSiopeConfronto THEN
    	tipoGestioneSiope ='NEW';
    ELSE 
    	tipoGestioneSiope ='OLD';
    END IF;
    --raise notice 'tipoGestioneSiope = %', tipoGestioneSiope;
         
    /* tutti gli importi sono dei VARCHAR che devono quindi essere convertiti 
            NUMERIC e contengono le 2 cifre decimali.*/
    importo_lordo_reversale= COALESCE(elencoReversali.mif_ord_importo ::numeric,0);
    importo_stanz_cassa=COALESCE(elencoReversali.ord_cast_cassa ::numeric,0); 
    importo_tot_reversali_emessi=COALESCE(elencoReversali.ord_cast_emessi ::NUMERIC,0);
    importo_tot_reversali_dopo_emiss=importo_tot_reversali_emessi+importo_lordo_reversale;
    
    IF importo_stanz_cassa >= importo_tot_reversali_dopo_emiss THEN
        importo_dispon=importo_stanz_cassa-importo_tot_reversali_dopo_emiss;
    ELSE
        importo_dispon=0;
    END IF;

    nome_tesoriere=COALESCE(elencoReversali.ente_oil_tes_desc,'');
    desc_causale=elencoReversali.mif_ord_vers_causale;

    if COALESCE(elencoReversali.num_fattura,'') = '' THEN
        num_fattura='';
        anno_fattura=0;
        importo_fattura=0;
    else /* concateno il sub-documento al numero fattura */
      num_fattura=COALESCE(elencoReversali.num_fattura,'')||'/'||COALESCE(elencoReversali.num_subdoc ::VARCHAR,'');
      anno_fattura=COALESCE(elencoReversali.anno_fattura,0);
        /* prendo l'importo del sub-documento */
      importo_fattura=COALESCE(elencoReversali.importo_subdoc,0);
    END IF;

    versante_cod_fiscale=COALESCE(elencoReversali.mif_ord_codfisc_versante,'');
    versante_partita_iva=COALESCE(elencoReversali.mif_ord_partiva_versante,'');
    versante_nome=COALESCE(elencoReversali.mif_ord_anag_versante,'');
    versante_indirizzo=COALESCE(elencoReversali.mif_ord_indir_versante,'');
    versante_cap=COALESCE(elencoReversali.mif_ord_cap_versante,'');
    versante_localita=COALESCE(elencoReversali.mif_ord_localita_versante,'');
    versante_provincia=COALESCE(elencoReversali.mif_ord_prov_versante,'');

    resp_sett_amm=COALESCE(elencoReversali.ente_oil_resp_ord,'');
    resp_amm=COALESCE(elencoReversali.ente_oil_resp_amm,'');    

    BEGIN
      for elencoOneri IN
            SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
              sum(r_doc_onere.importo_imponibile) IMPORTO_ONERE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA
            from siac_t_ordinativo_ts t_ordinativo_ts,            
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,            
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere,
                siac_d_onere d_onere,
                siac_d_onere_tipo d_onere_tipo
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
                AND t_ordinativo_ts.ord_id=elencoReversali.mif_ord_ord_id          
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
                GROUP BY d_onere_tipo.onere_tipo_code,d_onere.onere_code
        loop       
              IF elencoOneri.onere_tipo_code = 'IRPEF' THEN
                  importo_imposta = elencoOneri.IMPOSTA; 
              ELSIF  elencoOneri.onere_tipo_code = 'INPS' THEN
                  importo_ritenuta = elencoOneri.IMPOSTA;  
              END IF;                
        end loop;                     
    END;  

    importo_netto=importo_lordo_reversale-importo_ritenuta-importo_imposta;
	
    /* cerco la transazione elementare: accedo prima x ID ordinativo */
	for elencoClass in 
          select distinct d_class_tipo.classif_tipo_code, t_class.classif_code
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_ordinativo_class r_ordinativo_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_ordinativo_class.classif_id=t_class.classif_id
              and r_ordinativo_class.ord_id = elencoReversali.mif_ord_ord_id
             -- and d_class_tipo.classif_tipo_code IN ('GRUPPO_COFOG',
              --	'TRANSAZIONE_UE_ENTRATA',  'PDC_V')
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and r_ordinativo_class.data_cancellazione IS NULL
        loop
          IF elencoClass.classif_tipo_code ='RICORRENTE_ENTRATA' THEN
          	ricorrente_entrata=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_ENTRATA' THEN         
          	cod_trans_europea=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='PDC_V' THEN
          	cod_v_livello=elencoClass.classif_code;
          elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_ENTRATA' THEN
          	perimetro_sanit_entrata=elencoClass.classif_code;            
          elsif  substr(elencoClass.classif_tipo_code,1,13) ='SIOPE_ENTRATA_' THEN
          	cod_siope = elencoClass.classif_code;
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
raise notice 'ord_id = % ricorrente_entrata1 =%',elencoReversali.mif_ord_ord_id,ricorrente_entrata;
        /* se uno degli elementi della transazione non è valorizzato
        	per l'ordinativo devo estrarre quelli dell'accertamento  */
    if cod_v_livello = '' OR ricorrente_entrata = '' OR
    	 cod_trans_europea = '' OR perimetro_sanit_entrata ='' OR
         cod_siope = '' THEN
		for elencoClass in 
          select distinct d_class_tipo.*, t_class.*
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
          siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts,
          siac_r_movgest_class r_movgest_class ,
          siac_t_ordinativo_ts t_ordinativo_ts 
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_movgest_class.classif_id=t_class.classif_id
              and r_ord_ts_movgest_ts.movgest_ts_id=r_movgest_class.movgest_ts_id
              and t_ordinativo_ts.ord_ts_id=r_ord_ts_movgest_ts.ord_ts_id
              and t_ordinativo_ts.ord_id= elencoReversali.mif_ord_ord_id
              --and d_class_tipo.classif_tipo_code IN ('PDC_V')
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and r_ord_ts_movgest_ts.data_cancellazione IS NULL
              and r_movgest_class.data_cancellazione IS NULL
              and t_ordinativo_ts.data_cancellazione IS NULL
        	loop
 				IF elencoClass.classif_tipo_code ='RICORRENTE_ENTRATA' AND
                	ricorrente_entrata = '' THEN
                  ricorrente_entrata=elencoClass.classif_code;
                elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_ENTRATA' AND
                	cod_trans_europea =''  THEN         
                  cod_trans_europea=elencoClass.classif_code;
                elsif elencoClass.classif_tipo_code ='PDC_V' AND 
                	cod_v_livello = '' THEN
                  cod_v_livello=elencoClass.classif_code;                  
                elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_ENTRATA' AND
                	perimetro_sanit_entrata = '' THEN
                  perimetro_sanit_entrata=elencoClass.classif_code;            
                elsif  substr(elencoClass.classif_tipo_code,1,13) ='SIOPE_ENTRATA_' AND 
                	cod_siope = '' THEN
                  cod_siope = elencoClass.classif_code;
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
       --transaz_elementare=cod_trans_elem||'-'||cod_v_livello||'-'||cod_trans_europea||'-' ||cod_cofog;    
raise notice 'ord_id = % ricorrente_entrata2 =%',elencoReversali.mif_ord_ord_id,ricorrente_entrata;	   
       transaz_elementare=cod_v_livello;
       
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
       if ricorrente_entrata <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||ricorrente_entrata;
            else
            	transaz_elementare=ricorrente_entrata;
            end if;
       end if; 
       if perimetro_sanit_entrata <> '' THEN
       		if transaz_elementare <> '' THEN
            	transaz_elementare=transaz_elementare||'-'||perimetro_sanit_entrata;
            else
            	transaz_elementare=perimetro_sanit_entrata;
            end if;
       end if;                   
--raise notice 'cod_trans_elem = %, cod_v_livello = %, cod_trans_europea = %, cod_cofog = %', cod_trans_elem, cod_v_livello, cod_trans_europea,cod_cofog;

    return next;

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
cod_gestione='';
num_accertamento='';
num_subimpegno='';
importo_lordo_reversale=0;
numero_reversale=0;
data_reversale=NULL;
importo_stanz_cassa=0;
importo_tot_reversali_emessi=0;
importo_tot_reversali_dopo_emiss=0;
importo_dispon=0;
nome_tesoriere='';
desc_causale='';
num_fattura='';
anno_fattura=0;
importo_fattura=0;
versante_cod_fiscale='';
versante_partita_iva='';
versante_nome='';
versante_indirizzo='';
versante_cap='';
versante_localita='';
versante_provincia='';
transaz_elementare='';
importo_netto=0;
resp_sett_amm='';
importo_ritenuta=0;
importo_imposta=0;
resp_amm='';
tit_tipo_categ='';
anno_primo_accertamento='';
cod_stato_reversale='';

cod_trans_europea ='';
cod_v_livello ='';
cod_trans_elem ='';

ricorrente_entrata='';
perimetro_sanit_entrata='';
cod_siope='';
        
tipoGestioneSiope ='';

id_liquidazione=0;

end loop;


raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  


exception
	when no_data_found THEN
		raise notice 'nessuna reversale trovata' ;
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