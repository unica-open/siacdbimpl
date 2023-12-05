/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute_irpef" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_tipo_ritenuta varchar,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_ritenuta_irpef varchar,
  codice_tributo_irpef varchar,
  importo_ritenuta_irpef numeric,
  importo_netto_irpef numeric,
  importo_imponibile_irpef numeric,
  codice_risc varchar,
  tipo_ritenuta_inps varchar,
  codice_tributo_inps varchar,
  importo_ritenuta_inps numeric,
  importo_netto_inps numeric,
  importo_imponibile_inps numeric,
  importo_ente_inps numeric,
  tipo_ritenuta_irap varchar,
  importo_ritenuta_irap numeric,
  importo_netto_irap numeric,
  importo_imponibile_irap numeric,
  codice_ritenuta_irap varchar,
  desc_ritenuta_irap varchar,
  importo_ente_irap numeric,
  display_error varchar,
  tipo_ritenuta_irpeg varchar,
  codice_tributo_irpeg varchar,
  importo_ritenuta_irpeg numeric,
  importo_netto_irpeg numeric,
  importo_imponibile_irpeg numeric,
  codice_ritenuta_irpeg varchar,
  desc_ritenuta_irpeg varchar,
  importo_ente_irpeg numeric,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar,
  conto_tesoreria varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importoSubDoc NUMERIC;
imponibileInpsApp NUMERIC;
impostaInpsApp	NUMERIC;
enteInpsApp NUMERIC;
imponibileIrpefApp NUMERIC;
impostaIrpefApp	NUMERIC;
imponibileIrapApp NUMERIC;
impostaIrapApp	NUMERIC;
contaQuotaIrap integer;
importoParzIrapImpon NUMERIC;
importoParzIrapNetto NUMERIC;
importoParzIrapRiten NUMERIC;
importoParzIrapEnte NUMERIC;

contaQuotaIrpef integer;
importoParzIrpefImpon NUMERIC;
importoParzIrpefNetto NUMERIC;
importoParzIrpefRiten NUMERIC;
importoParzIrpefEnte NUMERIC;
importoTotDaDedurreFattura NUMERIC;
importTotaleFattura NUMERIC;

percQuota NUMERIC;
idFatturaOld INTEGER;
numeroQuoteFattura INTEGER;
numeroParametriData Integer;
docIdApp integer;

ente_denominazione VARCHAR;
cod_fisc_ente VARCHAR;
bilancio_id  INTEGER;
miaQuery VARCHAR;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

codice_risc='';
importo_lordo_mandato=0;
importo_netto_irpef=0;
importo_imponibile_irpef=0;
importo_ritenuta_irpef=0;
importo_netto_inps=0;
importo_imponibile_inps=0;
importo_ritenuta_inps=0;
importo_netto_irap=0;
importo_imponibile_irap=0;
importo_ritenuta_irap=0;

tipo_ritenuta_inps='';
tipo_ritenuta_irpef='';
tipo_ritenuta_irap='';

codice_tributo_irpef='';
codice_tributo_inps='';

codice_ritenuta_irap='';
desc_ritenuta_irap='';
benef_codice='';
importo_ente_irap=0;
importo_ente_inps=0;
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';

tipo_ritenuta_irpeg='';
codice_tributo_irpeg='';
importo_ritenuta_irpeg=0;
importo_netto_irpeg=0;
importo_imponibile_irpeg=0;
codice_ritenuta_irpeg='';
desc_ritenuta_irpeg='';
importo_ente_irpeg=0;
numeroParametriData=0;


display_error='';
conto_tesoreria:='';

/* 01/08/2018 SIAC-6306.
	Funzione creata per la gestione dell'aliquota IRPEF.

*/

idFatturaOld=0;
contaQuotaIrpef=0;
importoParzIrpefImpon =0;
importoParzIrpefNetto =0;
importoParzIrpefRiten =0;

    
  /* 11/10/2016: la query deve estrarre insieme mandati e dati IRPEF e
      ordinare i dati per id fattura (doc_id) perche' ci sono
      fatture che sono legate a differenti mandati.
      In questo caso e' necessario riproporzionare l'importo
      dell'aliquota a seconda della percentuale della quota fattura
      relativa al mandato rispetto al totale fattura */   
/* 16/10/2017: ottimizzata e resa dinamica la query */
/* 16/10/2017: SIAC-5337
  Occorre estrarre le reversali anche se annullate.
  Se la reversale e' annullata mettere l''importo ritenuta =0.
  Riproporzione sempre tranne quando importo lordo = importo reversale.
*/
miaQuery:='WITH irpef as
  (SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
      d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
      t_subdoc.subdoc_id,t_doc.doc_id,d_onere.onere_id ,
      d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
      d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
        t_doc.doc_importo IMPORTO_FATTURA,
        t_subdoc.subdoc_importo IMPORTO_QUOTA,
        t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
        sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
        sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
        sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
      from siac_t_ordinativo_ts t_ordinativo_ts,
          siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
          siac_t_doc t_doc, 
          siac_t_subdoc t_subdoc,
          siac_r_doc_onere r_doc_onere
              LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                  ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        r_doc_onere.somma_non_soggetta_tipo_id
                      AND d_dom_non_sogg_tipo.data_cancellazione IS NULL),
          siac_d_onere d_onere,                	
          siac_d_onere_tipo d_onere_tipo ,
          /* 11/10/2017: SIAC-5337 - 
              aggiunte tabelle per poter testare lo stato. */
          siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato d_ord_stato             
      WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
          AND t_doc.doc_id=t_subdoc.doc_id
          and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
          AND r_ord_stato.ord_id=t_ordinativo_ts.ord_id
          AND r_ord_stato.ord_stato_id=d_ord_stato.ord_stato_id
          AND r_doc_onere.doc_id=t_doc.doc_id
          AND d_onere.onere_id=r_doc_onere.onere_id
          AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id                                      
         -- AND t_ordinativo_ts.ord_id=mandati.ord_id
          AND t_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id||'
          AND upper(d_onere_tipo.onere_tipo_code) in(''IRPEF'')                
          AND t_doc.data_cancellazione IS NULL
          AND t_subdoc.data_cancellazione IS NULL
          AND r_doc_onere.data_cancellazione IS NULL
          AND d_onere.data_cancellazione IS NULL
          AND d_onere_tipo.data_cancellazione IS NULL
          AND t_ordinativo_ts.data_cancellazione IS NULL
          AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL  
          AND r_ord_stato.validita_fine IS NULL 
          AND d_ord_stato.data_cancellazione IS NULL                              
          GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
              t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
              d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
              d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
              t_doc.doc_id,d_onere.onere_id ,
              d_onere.onere_code, d_onere.onere_desc,
               t_doc.doc_importo, t_subdoc.subdoc_importo,
               t_subdoc.subdoc_importo_da_dedurre  ),               
          /* 01/06/2017: aggiunta gestione delle causali 770 */     
         caus_770 as (SELECT distinct r_onere_caus.onere_id,
                      r_doc_onere.doc_id,t_subdoc.subdoc_id,
                      COALESCE(d_causale.caus_code,'''') caus_code_770,
                      COALESCE(d_causale.caus_desc,'''') caus_desc_770
                  FROM siac_r_doc_onere r_doc_onere,
                      siac_t_subdoc t_subdoc,
                      siac_r_onere_causale r_onere_caus,
                      siac_d_causale d_causale ,
                      siac_d_modello d_modello                                                       
              WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                  AND r_doc_onere.onere_id=r_onere_caus.onere_id
                  AND d_causale.caus_id=r_doc_onere.caus_id
                  AND d_causale.caus_id=r_onere_caus.caus_id   
                  AND d_modello.model_id=d_causale.model_id                                                      
                  AND d_modello.model_code=''01'' --Causale 770
                  AND r_doc_onere.ente_proprietario_id ='||p_ente_prop_id||'                         --AND r_doc_onere.onere_id=5
                  AND r_onere_caus.validita_fine IS NULL                        
                  AND r_doc_onere.data_cancellazione IS NULL 
                  AND d_modello.data_cancellazione IS NULL 
                  AND d_causale.data_cancellazione IS NULL
                  AND t_subdoc.data_cancellazione IS NULL) ,                   
 mandati as  (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
      t_periodo.anno anno_eser, t_ordinativo.ord_anno,
       t_ordinativo.ord_desc, t_ordinativo.ord_id,
      t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
      t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
      t_soggetto.partita_iva,t_soggetto.codice_fiscale,
      t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
      t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
      SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
      t_movgest.movgest_anno anno_impegno, 
      	--13/10/2020 SIAC-7812 aggiunto il conto tesoreria.
      COALESCE(d_contotes.contotes_code,'''') conto_tesoreria
      FROM  	siac_t_ente_proprietario ep,
              siac_t_bil t_bil,
              siac_t_periodo t_periodo,
              siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
              siac_t_bil_elem t_bil_elem,                  
              siac_t_ordinativo t_ordinativo
            --09/02/2017: aggiunta la tabella della quietanza per testare
            -- la data quietanza se specificata in input.
              LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
              on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                  and r_ord_quietanza.data_cancellazione IS NULL
                  -- 10/10/2017: aggiunto test sulla data di fine validita'' 
                  -- per prendere la quietanza corretta.
                  and r_ord_quietanza.validita_fine is null )  
                  --13/10/2020 SIAC-7812 aggiunto il conto tesoreria.
               LEFT JOIN siac_d_contotesoreria d_contotes 
                on (d_contotes.contotes_id = t_ordinativo.contotes_id 
                	and d_contotes.data_cancellazione is null),
              siac_t_ordinativo_ts t_ord_ts,
              siac_r_liquidazione_ord r_liq_ord,
              siac_r_liquidazione_movgest r_liq_movgest,
              siac_t_movgest t_movgest,
              siac_t_movgest_ts t_movgest_ts,
              siac_t_ordinativo_ts_det t_ord_ts_det,
              siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
              siac_r_ordinativo_stato r_ord_stato,  
              siac_d_ordinativo_stato d_ord_stato ,
               siac_d_ordinativo_tipo d_ord_tipo,
               siac_r_ordinativo_soggetto r_ord_soggetto ,
               siac_t_soggetto t_soggetto  		    	
      WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
          AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
          AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
         AND t_ordinativo.ord_id=r_ord_stato.ord_id
         AND t_bil.bil_id=t_ordinativo.bil_id
         AND t_periodo.periodo_id=t_bil.periodo_id
         AND t_ord_ts.ord_id=t_ordinativo.ord_id           
         AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
         AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
         AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
         AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
         AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
         AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
         AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
         AND r_liq_movgest.liq_id=r_liq_ord.liq_id
         AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
         AND t_movgest_ts.movgest_id=t_movgest.movgest_id ';
         if p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
             miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'')                                                
                between '''||p_data_mandato_da||''' AND '''||p_data_mandato_a||''') ';
         end if;
         if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL THEN
            miaQuery:=miaQuery||' AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                between '''||p_data_trasm_da ||''' AND '''||p_data_trasm_a||''') ';
         end if;
         if p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL THEN
             miaQuery:=miaQuery||' AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
                between '''||p_data_quietanza_da||''' AND '''||p_data_quietanza_a||''') ';          
         end if;    
          miaQuery:=miaQuery||' AND t_ordinativo.ente_proprietario_id ='|| p_ente_prop_id||'
          --and t_ordinativo.ord_numero in (6744,6745,6746)
          --and t_ordinativo.ord_numero in (7578,7579,7580)                
          AND t_periodo.anno='''||p_anno||'''
              /* Gli stati possibili sono:
                  I = INSERITO
                  T = TRASMESSO 
                  Q = QUIETANZIATO
                  F = FIRMATO
                  A = ANNULLATO 
                  Prendo tutti tranne gli annullati.
                 */
          AND d_ord_stato.ord_stato_code <> ''A''
          AND d_ord_tipo.ord_tipo_code=''P'' /* Ordinativi di pagamento */
          AND d_ts_det_tipo.ord_ts_det_tipo_code=''A'' /* importo attuale */
              /* devo testare la data di fine validita'' perche''
                  quando un ordinativo e'' annullato, lo trovo 2 volte,
                  uno con stato inserito e l''altro annullato */
          AND r_ord_stato.validita_fine IS NULL 
          AND ep.data_cancellazione IS NULL
          AND r_ord_stato.data_cancellazione IS NULL
          AND r_ordinativo_bil_elem.data_cancellazione IS NULL
          AND t_bil_elem.data_cancellazione IS NULL
          AND  t_bil.data_cancellazione IS NULL
          AND  t_periodo.data_cancellazione IS NULL
          AND  t_ordinativo.data_cancellazione IS NULL
          AND  t_ord_ts.data_cancellazione IS NULL
          AND  t_ord_ts_det.data_cancellazione IS NULL
          AND  d_ts_det_tipo.data_cancellazione IS NULL
          AND  r_ord_stato.data_cancellazione IS NULL
          AND  d_ord_stato.data_cancellazione IS NULL
          AND  d_ord_tipo.data_cancellazione IS NULL  
          AND r_ord_soggetto.data_cancellazione IS NULL
          AND t_soggetto.data_cancellazione IS NULL
          AND r_liq_ord.data_cancellazione IS NULL 
          AND r_liq_movgest.data_cancellazione IS NULL 
          AND t_movgest.data_cancellazione IS NULL
          AND t_movgest_ts.data_cancellazione IS NULL
          AND t_ord_ts.data_cancellazione IS NULL
          GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
            t_periodo.anno , t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
            t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno,
            conto_tesoreria
             ) ,
      reversali as (select a.ord_id ord_id_rev, 
            a.codice_risc codice_risc_rev,
            a.importo_imponibile importo_imponibile_rev,
            a.importo_ente importo_ente_rev,
            a.importo_imposta importo_imposta_rev,
            a.importo_ritenuta importo_ritenuta_rev,
            a.importo_reversale importo_reversale_rev,
            a.importo_ord importo_ord_rev,
            a.stato_reversale,
            a.num_reversale                  
          from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||''',false) a) 
 select  *
    from  mandati
         join irpef on mandati.ord_id =     irpef.ord_id 
         join reversali on mandati.ord_id =  reversali.ord_id_rev 
         left join caus_770  ON (caus_770.onere_id=irpef.onere_id
                  AND caus_770.doc_id=irpef.doc_id
                  AND caus_770.subdoc_id=irpef.subdoc_id)   
    --where mandati.ord_numero in (9868,9867)
    --SIAC-7028: aggiunto nell''order by il campo irpef.onere_code
    -- per risolvere un problema nel caso ci siano piu'' quote di una fattura
    -- collegata a piu'' di un onere 
ORDER BY irpef.doc_id, irpef.onere_code, irpef.subdoc_id '; 

raise notice 'Query: %', miaQuery;  
                              
	FOR elencoMandati IN
    	execute miaQuery
   	loop           
        percQuota=0;    
raise notice 'Mandato: % ',  elencoMandati.ord_numero;      	          
raise notice '  Ord_id reversale = %, Importo ritenuta da reversale: % ', 
	elencoMandati.ord_id_rev, elencoMandati.importo_ritenuta_rev;
raise notice 'XXX doc_id = %', elencoMandati.doc_id;       

   			/* se la fattura e' nuova verifico quante quote ci sono 
            	relative alla fattura */
        IF  idFatturaOld <> elencoMandati.doc_id THEN
        /* 01/08/2018 SIAC-6306.
        	aggiunto join con siac_r_subdoc_prov_cassa perche'
            non devono essere considerate le quote che hanno un provvisorio
            di cassa */
          numeroQuoteFattura=0;
          SELECT count(*)
          INTO numeroQuoteFattura
          from siac_t_subdoc s
          		left join siac_r_subdoc_prov_cassa provv
                	on (provv.subdoc_id= s.subdoc_id
                    	and provv.data_cancellazione IS NULL)
          where s.doc_id= elencoMandati.doc_id
          	--19/07/2017: prendo solo le quote NON STORNATE completamente.
          	and s.subdoc_importo-s.subdoc_importo_da_dedurre>0
            and s.data_cancellazione IS NULL
            and provv.subdoc_provc_id IS NULL;
          IF NOT FOUND THEN
              numeroQuoteFattura=0;
          END IF;

        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        /* 01/08/2018 SIAC-6306.
        	aggiunto join con siac_r_subdoc_prov_cassa perche'
            non devono essere considerate le quote che hanno un provvisorio
            di cassa */
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          	left join siac_r_subdoc_prov_cassa provv
                	on (provv.subdoc_id= s.subdoc_id
                    	and provv.data_cancellazione IS NULL)
          where s.doc_id= elencoMandati.doc_id
          	and s.data_cancellazione IS NULL
            and provv.subdoc_provc_id IS NULL;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
          END IF;
        END IF;                
        
raise notice 'Numero quote fattura = %, importo da dedurre fattura = %, importo tota fattura = %',
numeroQuoteFattura,importoTotDaDedurreFattura, importTotaleFattura;
 
        raise notice 'contaQuotaIrpefXXX= %', contaQuotaIrpef;
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irpef=upper(elencoMandati.onere_tipo_code);
                				
        codice_tributo_irpef=elencoMandati.onere_code;
        --desc_ritenuta_irpef=elencoMandati.onere_desc;
        code_caus_770:=COALESCE(elencoMandati.caus_code_770,'');
		desc_caus_770:=COALESCE(elencoMandati.caus_desc_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_code,'');
		desc_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_desc,'');
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
             --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        
        importTotaleFattura:=0;
        
        /* 01/08/2018 SIAC-6306.
        	Calcolo il totale della fattura come somma delle quote
            che non hanno il provvisorio di cassa.
            Serve per calcolare in modo corretto la percentuale da applicare
            sulla quota.  */
        SELECT sum(s.subdoc_importo)
          INTO importTotaleFattura
          from siac_t_subdoc s
          	left join siac_r_subdoc_prov_cassa provv
                	on (provv.subdoc_id= s.subdoc_id
                    	and provv.data_cancellazione IS NULL)
          where s.doc_id= elencoMandati.doc_id
          	and s.data_cancellazione IS NULL
            and provv.subdoc_provc_id IS NULL;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
          END IF;
                          
        --percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        --	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(importTotaleFattura-importoTotDaDedurreFattura);                

raise notice 'XXXX PercQuota = %', percQuota;       
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0); 
          
        raise notice 'irpef ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, LORDO MANDATO = %', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,importo_lordo_mandato;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'importo da dedurre quota: %; Importo da dedurre TOTALE = % ', 
        	elencoMandati.IMP_DEDURRE, importoTotDaDedurreFattura;
        raise notice 'Perc quota = %', percQuota;
        
        IF elencoMandati.stato_reversale = 'A' THEN
        	importo_ritenuta_irpef:=0;
        else
        	IF elencoMandati.importo_ritenuta_rev = importo_lordo_mandato THEN
        		importo_ritenuta_irpef:=elencoMandati.importo_ritenuta_rev;
            end if;
        end if;
            -- la fattura e' la stessa della quota precedente.         
        IF  idFatturaOld = elencoMandati.doc_id THEN
            contaQuotaIrpef=contaQuotaIrpef+1;
            raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrpef;
                  	
                -- e' l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrpef= numeroQuoteFattura THEN
                raise notice 'ULTIMA QUOTA';
                importo_imponibile_irpef=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrpefImpon;
                IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
                	importo_ritenuta_irpef=round(elencoMandati.IMPOSTA-importoParzIrpefRiten,2);
                end if;
                --importo_ente_irpef=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrpefEnte;
        raise notice 'importo_lordo_mandato = %, importo_ritenuta_irpef = %,
                        importoParzIrpefRiten = %',
                     importo_lordo_mandato, importo_ritenuta_irpef, importoParzIrpefRiten;
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                      
                raise notice 'Dopo ultima rata - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
                    -- azzero gli importi parziali per fattura
                importoParzIrpefImpon=0;
                importoParzIrpefRiten=0;
                importoParzIrpefNetto=0;
                contaQuotaIrpef=0;
            ELSE
                raise notice 'ALTRA QUOTA';
                importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
                IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
                	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);         		
                end if;
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                      
                    -- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrpefImpon=round(importoParzIrpefImpon+importo_imponibile_irpef,2);
                importoParzIrpefRiten=round(importoParzIrpefRiten+ importo_ritenuta_irpef,2);                
                importoParzIrpefNetto=round(importoParzIrpefNetto+importo_netto_irpef,2);
                raise notice 'Dopo altra quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            END IF;
        ELSE -- fattura diversa dalla precedente
            raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
            IF elencoMandati.stato_reversale <> 'A' AND 
                	elencoMandati.importo_ritenuta_rev <> importo_lordo_mandato THEN
            	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);    
            end if;
            importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrpefImpon=round(importo_imponibile_irpef,2);
            importoParzIrpefRiten= round(importo_ritenuta_irpef,2);
            importoParzIrpefNetto=round(importo_netto_irpef,2);
                  
            raise notice 'Dopo prima quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            contaQuotaIrpef=1;            
        END IF;

      raise notice 'IMPON =%, RITEN = %,  NETTO= %', importo_imponibile_irpef, importo_ritenuta_irpef,importo_netto_irpef; 
      idFatturaOld=elencoMandati.doc_id;
      
      -- codice delle reversali
      if codice_risc = '' THEN
      	codice_risc = elencoMandati.codice_risc_rev;
      else
    	codice_risc = codice_risc||', '||elencoMandati.codice_risc_rev;
      end if;
      
      	--13/10/2020 SIAC-7812 aggiunto il conto tesoreria.
      conto_tesoreria:=elencoMandati.conto_tesoreria;
      
      return next;
      
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
	  desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      conto_tesoreria:='';
   end loop;   
   

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato per % ', p_tipo_ritenuta ;
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