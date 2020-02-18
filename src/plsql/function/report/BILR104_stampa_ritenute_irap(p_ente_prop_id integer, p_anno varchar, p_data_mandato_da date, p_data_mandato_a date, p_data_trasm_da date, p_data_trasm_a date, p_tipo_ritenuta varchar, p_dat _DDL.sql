/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute_irap" (
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
  attivita_desc varchar
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

/* 01/08/2018 SIAC-6306.
	Funzione creata per la gestione dell'aliquota IRAP.

*/

idFatturaOld=0;
contaQuotaIrap=0;
importoParzIrapImpon =0;
importoParzIrapNetto =0;
importoParzIrapRiten =0;
importoParzIrapEnte =0;
    
    /* 11/10/2016: la query deve estrarre insieme mandati e dati IRAP e
        ordinare i dati per id fattura (doc_id) perche' ci sono
        fatture che sono legate a differenti mandati.
        In questo caso e' necessario riproporzionare l'importo
        dell'aliquota a seconda della percentuale della quota fattura
        relativa al mandato rispetto al totale fattura */    
/* 16/10/2017: ottimizzata e resa dinamica la query */              
miaQuery:='WITH irap as
    (SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
        d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
        t_subdoc.subdoc_id,t_doc.doc_id,
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
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere,
            siac_d_onere_tipo d_onere_tipo
        WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
           -- AND t_ordinativo_ts.ord_id=mandati.ord_id
            AND t_ordinativo_ts.ente_proprietario_id = '||p_ente_prop_id||'
            AND upper(d_onere_tipo.onere_tipo_code) in(''IRAP'')
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                t_doc.doc_id,
                d_onere.onere_code, d_onere.onere_desc,
                 t_doc.doc_importo, t_subdoc.subdoc_importo , 
                 t_subdoc.subdoc_importo_da_dedurre) ,
 mandati as  (select ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
        t_periodo.anno anno_eser, t_ordinativo.ord_anno,
         t_ordinativo.ord_desc, t_ordinativo.ord_id,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
        t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
        t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        t_movgest.movgest_anno anno_impegno
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
                    and r_ord_quietanza.validita_fine is null ),  
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
           -- inizio INC000001342288      
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
            miaQuery:=miaQuery||' AND t_ordinativo.ente_proprietario_id = '||p_ente_prop_id||'
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
              t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
               )  
    select  *
      from  mandati
           join irap on mandati.ord_id = irap.ord_id   
            ORDER BY irap.doc_id, irap.subdoc_id   ';    
raise notice 'Query IRAP: %', miaQuery;          
FOR elencoMandati IN
    execute miaQuery
loop           
    percQuota=0;    	          
       
        /* verifico quante quote ci sono relative alla fattura */
    numeroQuoteFattura=0;
    SELECT count(*)
    INTO numeroQuoteFattura
    from siac_t_subdoc s
    where s.doc_id= elencoMandati.doc_id
            --19/07/2017: prendo solo le quote NON STORNATE completamente.
        and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
    IF NOT FOUND THEN
        numeroQuoteFattura=0;
    END IF;
    --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
    --	per calcolare correttamente la percentuale della quota.
    importoTotDaDedurreFattura:=0;
    SELECT sum(s.subdoc_importo_da_dedurre)
      INTO importoTotDaDedurreFattura
      from siac_t_subdoc s
      where s.doc_id= elencoMandati.doc_id;
      IF NOT FOUND THEN
          importoTotDaDedurreFattura:=0;
    END IF;
        
    raise notice 'contaQuotaIrapXXX= %', contaQuotaIrap;
        
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
                
    tipo_ritenuta_irap=upper(elencoMandati.onere_tipo_code);
                				
    codice_ritenuta_irap=elencoMandati.onere_code;
    desc_ritenuta_irap=elencoMandati.onere_desc;
        
        -- calcolo la percentuale della quota corrente rispetto
        -- al totale fattura.
    --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
    --	della quota da dedurre.
    --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
    percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        (elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
    importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);         
    raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
    raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
    raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
    raise notice 'Importo da Dedurre= %', elencoMandati.IMP_DEDURRE;
    raise notice 'Perc quota = %', percQuota;
        
        -- la fattura e' la stessa della quota precedente. 
    IF  idFatturaOld = elencoMandati.doc_id THEN
        contaQuotaIrap=contaQuotaIrap+1;
        raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
            -- e' l'ultima quota della fattura:
            -- gli importi sono quelli totali meno quelli delle quote
            -- precedenti, per evitare problemi di arrotondamento.            
        if contaQuotaIrap= numeroQuoteFattura THEN
            raise notice 'ULTIMA QUOTA';
            importo_imponibile_irap=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrapImpon;
            importo_ritenuta_irap=elencoMandati.IMPOSTA-importoParzIrapRiten;
            importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrapEnte;
                
                -- azzero gli importi parziali per fattura
            importoParzIrapImpon=0;
            importoParzIrapRiten=0;
            importoParzIrapEnte=0;
            importoParzIrapNetto=0;
            contaQuotaIrap=0;
        ELSE
            raise notice 'ALTRA QUOTA';
            importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
            importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
            importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
            importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;
                
                -- sommo l'importo della quota corrente
                -- al parziale per fattura.
            importoParzIrapImpon=importoParzIrapImpon+importo_imponibile_irap;
            importoParzIrapRiten=importoParzIrapRiten+ importo_ritenuta_irap;
            importoParzIrapEnte=importoParzIrapEnte+importo_ente_irap;
            importoParzIrapNetto=importoParzIrapNetto+importo_netto_irap;
            --contaQuotaIrap=contaQuotaIrap+1;
                
        END IF;
    ELSE -- fattura diversa dalla precedente
        raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
        importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
        importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;

            -- imposto l'importo della quota corrente
            -- al parziale per fattura.            
        importoParzIrapImpon=importo_imponibile_irap;
        importoParzIrapRiten= importo_ritenuta_irap;
        importoParzIrapEnte=importo_ente_irap;
        importoParzIrapNetto=importo_netto_irap;
        contaQuotaIrap=1;            
    END IF;
        
                
  raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
  raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
  idFatturaOld=elencoMandati.doc_id;
            
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