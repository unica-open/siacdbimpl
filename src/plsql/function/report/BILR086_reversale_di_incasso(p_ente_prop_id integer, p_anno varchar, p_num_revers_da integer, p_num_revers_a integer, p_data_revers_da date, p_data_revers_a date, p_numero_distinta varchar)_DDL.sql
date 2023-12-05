/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR086_reversale_di_incasso" (
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

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
appStr VARCHAR;
posizione integer;
numAccertApp VARCHAR;
numSubAccertApp VARCHAR;
numAccert VARCHAR;
annoAccertamento VARCHAR;
importo_ritenuta NUMERIC;
importo_imposta NUMERIC;
anno_eser_int INTEGER;
contaRecord INTEGER;

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


RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;

/* 22/12/2015: gestiti i parametri numero reversale da/a e data reversale da/a 
	al posto della sola data reversale.
		AND AND to_date(os.mif_ord_data,'yyyy/MM/dd') = p_data_revers.
	I parametri non sono obbligatori ma almeno uno deve essere specificato.
*/
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
            FULL JOIN mif_t_ordinativo_entrata_disp_ente disp_ente
            	ON (disp_ente.mif_ord_id=os.mif_ord_id   
            		AND disp_ente.mif_ord_dispe_nome='Transazione Elementare'  
                    AND  disp_ente.data_cancellazione IS NULL),              
            siac_t_ordinativo_ts t_ordinativo_ts
            FULL JOIN  siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts   
            	ON  (r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id 
                	 AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL) 
            FULL JOIN  siac_t_subdoc t_subdoc
            	ON  (t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                	 AND t_subdoc.data_cancellazione IS NULL)   
            FULL JOIN  siac_t_doc 	t_doc
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
			/* 22/02/2016: estraggo tutti i record con qualsiasi stato ma
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
            	/* 28/01/2016: non è necessario testare la data di
                	fine validita del flusso perchè è sempre valorizzata */
           -- AND flusso_elab.validita_fine IS NULL 
            AND t_ordinativo_ts.data_cancellazione IS NULL
            order by os.mif_ord_numero, os.mif_ord_data, t_doc.doc_numero, t_subdoc.subdoc_numero
loop
contaRecord=contaRecord+1;
/* 18/03/2016: aggiunto il controllo sul flag flusso_elab_mif_tipo_dec:
	se è true la stampa non può essere effettuata */
--raise notice 'Flusso: %, id_tipo_flusso: %, tipo_dec = %', elencoReversali.flusso_elab_mif_id,elencoReversali.flusso_elab_mif_tipo_id, elencoReversali.flusso_elab_mif_tipo_dec;
if elencoReversali.flusso_elab_mif_tipo_dec = true AND contaRecord =1 THEN
	display_error='Stampa giornaliera delle reversali di incasso (BILR086): STAMPA NON UTILIZZABILE.';
    return next;
    return;
end if;
--raise notice 'Distinta = %', elencoReversali.mif_ord_codice_flusso_oil;
--raise notice 'numero revers %, mif_ord_id = %, FLUSSO_ID= % ',elencoReversali.mif_ord_numero, elencoReversali.mif_ord_id, elencoReversali.flusso_elab_mif_id;
	
 /* 22/02/2016: ho estratto anche i record in stato 'A' ma invio solo
     	quelli in stato 'I' 
    24/02/2016: ci sono enti per cui lo stato non è "I" ma "INSERIMENTO".
    Pertanto estraggo il primo carattere del campo mif_ord_codice_funzione
    per capire quali sono i record da inviare.
    IF elencoReversali.mif_ord_codice_funzione ='I' THEN */
  /*  17/03/2016: le reversali devono essere stampate tutte, tolto il controllo
     	IF upper(substr(elencoReversali.mif_ord_codice_funzione,1,1))='I' THEN  */         
	cod_stato_reversale=upper(substr(elencoReversali.mif_ord_codice_funzione,1,1));
    tit_tipo_categ=COALESCE(elencoReversali.mif_ord_codifica_bilancio,'');
	
    --raise notice 'cerco accertamento';
    /* cerco accertamento e sub-accertamento: potrebbero essere più di uno, quindi
        li cerco con un ciclo e li concateno. */
        BEGIN
          appStr='';
          numAccertApp='';
          numSubAccertApp='';
          numAccert='';
          
          for elencoAccertamenti in
              SELECT disp_ente.mif_ord_dispe_valore    
              FROM mif_t_ordinativo_entrata_disp_ente disp_ente
              WHERE disp_ente.mif_ord_id= elencoReversali.mif_ord_id
                  AND disp_ente.mif_ord_dispe_nome='Accertamento quota reversale'
                  AND disp_ente.ente_proprietario_id=p_ente_prop_id  
          loop
          
              appStr = elencoAccertamenti.mif_ord_dispe_valore;
              --raise notice 'trovato accertamento %', appStr;
              posizione = position ('-' in appStr);
              if posizione > 0 THEN
                  annoAccertamento = substr(appStr,1, posizione-1);
                  /* 11/02/2015: devo restituire l'anno dell'accertamento perchè sulla stampa
                      devo distinguere tra COMPETENZA/RESIDUI.
                      Se ci sono più accertamenti restituisco solo il primo */
                  if anno_primo_accertamento='' THEN
                      anno_primo_accertamento= annoAccertamento;                                
                  end if;
                  --raise notice 'anno accertamento %', annoAccertamento;
                  appStr = substr(appStr,posizione+1, char_length(appStr)-posizione);
                 -- raise notice 'altro %', appStr;
                  posizione = position ('-' in appStr);
                  if posizione > 0 THEN
                      numAccertApp = substr(appStr,1, posizione-1);
                      numSubAccertApp = substr(appStr,posizione+1, char_length(appStr)-posizione);
                      if numAccert = '' THEN
                          numAccert=annoAccertamento||'/'||numAccertApp||'/'||numSubAccertApp;
                      else
                          numAccert=numAccert||', '||annoAccertamento||'/'||numAccertApp||'/'||numSubAccertApp;
                      end if;
                  else
                      numAccertApp= appStr;
                      numSubAccertApp ='';
                      if numAccert = '' THEN
                          numAccert=annoAccertamento||'/'||appStr;
                      else
                           numAccert=numAccert||', '||annoAccertamento||'/'||appStr;
                      end if;
                  END IF;
              ELSE
                  numAccertApp='';
                  numSubAccertApp='';
                  --numAccert='';
              END IF;
         
          numAccertApp='';  
          numsubaccertapp='';   
          
          end loop;
        
        END;        
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

    /*
      BEGIN
          SELECT disp_ente.mif_ord_dispe_valore    
          INTO appStr
          FROM mif_t_ordinativo_entrata_disp_ente disp_ente
          WHERE disp_ente.mif_ord_id= elencoReversali.mif_ord_id
              AND disp_ente.mif_ord_dispe_nome='Stanziamento Cassa'
              AND disp_ente.ente_proprietario_id=p_ente_prop_id ;
          IF NOT FOUND THEN
              importo_stanz_cassa=0;
          else 
              importo_stanz_cassa=COALESCE(appStr ::numeric,0) / 100;
          END IF;
      END;*/
                
    --importo_stanz_cassa=elencoReversali.mif_ord_disp_cassa;
    --importo_stanz_cassa=0;
    --importo_tot_reversali_emessi=elencoReversali.mif_ord_mandati_prev;
    --importo_tot_reversali_dopo_emiss=elencoReversali.mif_ord_mandati_stanz;
    --importo_dispon=elencoReversali.mif_ord_disponibilita;


      
    /* tutti gli importi sono dei VARCHAR che devono quindi essere convertiti 
            NUMERIC e contengono le 2 cifre decimali.
            Pertanto i valori devono essere divisi per 100 */
    importo_lordo_reversale= COALESCE(elencoReversali.mif_ord_importo ::numeric,0) / 100;
    importo_stanz_cassa=COALESCE(elencoReversali.ord_cast_cassa ::numeric,0); 
    importo_tot_reversali_emessi=COALESCE(elencoReversali.ord_cast_emessi ::NUMERIC,0);
    importo_tot_reversali_dopo_emiss=importo_tot_reversali_emessi+importo_lordo_reversale;
    --importo_dispon=COALESCE(elencoReversali.ord_cast_competenza ::NUMERIC,0);
    IF importo_stanz_cassa >= importo_tot_reversali_dopo_emiss THEN
        importo_dispon=importo_stanz_cassa-importo_tot_reversali_dopo_emiss;
    ELSE
        importo_dispon=0;
    END IF;
    --nome_tesoriere=COALESCE(elencoReversali.mif_ord_info_tesoriere,'');
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

    transaz_elementare=COALESCE(elencoReversali.transaz_elementare,'');

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

    --importo_netto=importo_lordo_reversale;
    importo_netto=importo_lordo_reversale-importo_ritenuta-importo_imposta;

    return next;
--end if; /* IF elencoReversali.mif_ord_codice_funzione='I' THEN */

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