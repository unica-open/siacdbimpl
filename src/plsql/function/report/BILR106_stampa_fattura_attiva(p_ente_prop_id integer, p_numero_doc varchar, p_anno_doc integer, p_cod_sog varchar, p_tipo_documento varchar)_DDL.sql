/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR106_stampa_fattura_attiva" (
  p_ente_prop_id integer,
  p_numero_doc varchar,
  p_anno_doc integer,
  p_cod_sog varchar,
  p_tipo_documento varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  cf_ente varchar,
  indirizzo_ente varchar,
  tel_ente varchar,
  fax_ente varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  benef_indirizzo varchar,
  benef_cap varchar,
  benef_comune varchar,
  benef_prov varchar,
  benef_nazione varchar,
  tipo_documento varchar,
  oggetto_fattura varchar,
  descr_fattura varchar,
  num_fattura varchar,
  anno_fattura integer,
  data_fattura date,
  imp_lordo_fattura numeric,
  imp_imponibile_fattura numeric,
  numero_aliq_fattura integer,
  anno_aliq_fattura varchar,
  perc_aliq_fattura numeric,
  imp_aliq_fattura numeric,
  imponibile_aliq_fattura numeric,
  desc_aliq_fattura varchar,
  doc_id integer,
  data_scadenza_fattura date,
  bollo_fattura varchar,
  note_fattura varchar,
  termine_pagamento varchar,
  subdoc_r_id integer
) AS
$body$
DECLARE
elencoFatture record;
elencoOneri	record;
elencoAttr record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

doc_r_id_APP INTEGER;

BEGIN

nome_ente='';
partita_iva_ente='';
cf_ente='';
indirizzo_ente='';
tel_ente='';
fax_ente='';
benef_codice='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
benef_indirizzo='';
benef_cap='';
benef_comune='';
benef_prov='';
benef_nazione='';
tipo_documento='';
oggetto_fattura='';
descr_fattura='';
num_fattura='';
anno_fattura=0;
data_fattura=NULL;
imp_lordo_fattura=0;
imp_imponibile_fattura=0;
numero_aliq_fattura=0;
anno_aliq_fattura='';
perc_aliq_fattura=0;
imp_aliq_fattura=0;
imponibile_aliq_fattura=0;
desc_aliq_fattura='';
doc_id=0;
data_scadenza_fattura=NULL;
bollo_fattura='';
note_fattura='';
termine_pagamento='';
subdoc_r_id=0;

RTN_MESSAGGIO:='Estrazione dei dati della fattura ''.';
raise notice 'Estrazione dei dati della fattura ';
raise notice 'ora: % ',clock_timestamp()::varchar;

doc_r_id_APP=NULL;
/* 18/10/2016: verifico il tipo di legame dell'iva con la fattura:
	- se esite il legame con siac_r_doc_iva l'iva è legata alla fattura;
    - se il legame NON esiste, l'iva è legata alle quote della fattura */
select rdi.doc_id doc_r_id
INTO doc_r_id_APP
from siac_t_doc t_doc, siac_t_subdoc_iva  tsi, siac_r_doc_iva  rdi,
	siac_d_doc_tipo d_doc_tipo, siac_t_soggetto t_soggetto, 
    siac_r_doc_sog r_doc_sog
where t_doc.doc_id = rdi.doc_id
	and rdi.dociva_r_id=tsi.dociva_r_id
	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id  
    and r_doc_sog.doc_id=t_doc.doc_id
    and t_soggetto.soggetto_id=r_doc_sog.soggetto_id
	and t_doc.ente_proprietario_id=p_ente_prop_id
    and t_doc.doc_anno=p_anno_doc
    and t_doc.doc_numero=p_numero_doc
    and d_doc_tipo.doc_tipo_code=p_tipo_documento
    and t_soggetto.soggetto_code=p_cod_sog    
    and r_doc_sog.data_cancellazione is null
    and t_soggetto.data_cancellazione is null
    and d_doc_tipo.data_cancellazione is null
    and tsi.data_cancellazione is null
    and t_doc.data_cancellazione is null;
    
raise notice 'doc_r_id_APP = %', doc_r_id_APP;

if doc_r_id_APP is not NULL then
    raise notice 'query OLD';
/* 18/10/2016: iva è legata al documento, 
	nella query seguente non c'è legame con le quote */
    for elencoFatture in
    select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 		
            t_doc.doc_anno, t_doc.doc_numero, t_doc.doc_importo,
            t_doc.doc_data_emissione, t_doc.doc_desc, t_doc.doc_id,
            t_doc.doc_data_scadenza,
            t_soggetto.codice_fiscale cf_soggetto, t_soggetto.partita_iva piva_soggetto,
            t_soggetto.soggetto_desc, t_soggetto.soggetto_code,
            d_via_tipo.via_tipo_desc, t_indir_sogg.toponimo, t_indir_sogg.numero_civico,
            t_indir_sogg.frazione, t_indir_sogg.interno, t_indir_sogg.zip_code,
            t_comune.comune_desc, t_provincia.sigla_automobilistica sigla_prov,
            t_nazione.nazione_desc, t_subdoc_iva.subdociva_anno, t_subdoc_iva.subdociva_numero,
            t_subdoc_iva.subdociva_desc, d_doc_tipo.doc_tipo_code,
            t_ivamov.ivamov_imponibile, t_ivamov.ivamov_imposta, t_ivamov.ivamov_totale,
            t_iva_aliq.ivaaliquota_code, t_iva_aliq.ivaaliquota_desc, 
            t_iva_aliq.ivaaliquota_perc, d_cod_bollo.codbollo_desc
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_doc t_doc
                    LEFT JOIN siac_r_doc_iva r_doc_iva
                        ON (r_doc_iva.doc_id=t_doc.doc_id
                            AND r_doc_iva.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_subdoc_iva t_subdoc_iva
                        ON (t_subdoc_iva.dociva_r_id=r_doc_iva.dociva_r_id
                            AND t_subdoc_iva.data_cancellazione IS NULL)
                    LEFT JOIN siac_r_ivamov r_ivamov
                        ON (r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
                            AND r_ivamov.data_cancellazione IS NULL)
                    LEFT JOIN  siac_t_ivamov t_ivamov
                        ON (t_ivamov.ivamov_id=r_ivamov.ivamov_id
                            AND t_ivamov.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_iva_aliquota t_iva_aliq
                        ON (t_iva_aliq.ivaaliquota_id=t_ivamov.ivaaliquota_id
                            AND t_iva_aliq.data_cancellazione IS NULL)
                    LEFT JOIN siac_d_codicebollo d_cod_bollo
                        ON (d_cod_bollo.codbollo_id=t_doc.codbollo_id
                            AND d_cod_bollo.data_cancellazione IS NULL),                     
                    siac_r_doc_sog r_doc_sog,                  
                    siac_d_doc_tipo d_doc_tipo,  
                    siac_r_doc_stato r_doc_stato,
                    siac_d_doc_stato d_doc_stato,
                    siac_t_soggetto t_soggetto
                    LEFT JOIN siac_t_indirizzo_soggetto t_indir_sogg
                        ON  (t_indir_sogg.soggetto_id=t_soggetto.soggetto_id
                                AND t_indir_sogg.principale='S'
                                AND  t_indir_sogg.data_cancellazione IS NULL)
                    LEFT JOIN siac_d_via_tipo d_via_tipo
                        ON (d_via_tipo.via_tipo_id=t_indir_sogg.via_tipo_id
                            AND d_via_tipo.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_comune t_comune		
                        ON (t_comune.comune_id=t_indir_sogg.comune_id
                            AND t_comune.data_cancellazione IS NULL)   
                    LEFT JOIN siac_r_comune_provincia r_com_provincia
                        ON (r_com_provincia.comune_id=t_comune.comune_id
                            AND r_com_provincia.data_cancellazione IS NULL) 
                    LEFT JOIN siac_t_provincia t_provincia	
                        ON (t_provincia.provincia_id=r_com_provincia.provincia_id
                            AND t_provincia.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_nazione t_nazione
                        ON (t_nazione.nazione_id=t_comune.nazione_id
                            AND t_nazione.data_cancellazione IS NULL)
            WHERE  t_doc.ente_proprietario_id=ep.ente_proprietario_id       
               AND r_doc_sog.doc_id=t_doc.doc_id 	 
               AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id                
               AND t_soggetto.soggetto_id=r_doc_sog.soggetto_id
               AND d_doc_stato.doc_stato_id=r_doc_stato.doc_stato_id
               AND r_doc_stato.doc_id=t_doc.doc_id
                -- 21/03/2016: aggiunto il trim per togliere gli eventuali spazi.
               AND btrim(t_doc.doc_numero)=btrim(p_numero_doc)
               AND t_doc.doc_anno=p_anno_doc
               AND t_soggetto.soggetto_code=p_cod_sog  
               AND t_doc.ente_proprietario_id=p_ente_prop_id  
               AND d_doc_tipo.doc_tipo_code=p_tipo_documento
                /* 26/04/2016: aggiunto il controllo sullo stato del documento
                    per escludere le fatture annullate */
               AND d_doc_stato.doc_stato_code<>'A'
               AND ep.data_cancellazione IS NULL
               AND t_soggetto.data_cancellazione IS NULL
               AND r_doc_sog.data_cancellazione IS NULL 
               AND t_doc.data_cancellazione IS NULL     
               AND d_doc_tipo.data_cancellazione IS NULL      
               AND d_doc_stato.data_cancellazione IS NULL   
               AND r_doc_stato.data_cancellazione IS NULL                              
    loop

        nome_ente=elencoFatture.ente_denominazione;
        partita_iva_ente='';
        cf_ente=COALESCE(elencoFatture.cod_fisc_ente,'');
        indirizzo_ente='';
        tel_ente='';
        fax_ente='';

        benef_codice=elencoFatture.soggetto_code;
        benef_cod_fiscale=COALESCE(elencoFatture.cf_soggetto,'');
        benef_partita_iva=COALESCE(elencoFatture.piva_soggetto,'');
        benef_nome=elencoFatture.soggetto_desc;
        benef_indirizzo=COALESCE(elencoFatture.via_tipo_desc,'')||' '||
            COALESCE(elencoFatture.toponimo,'')|| ' '||COALESCE(elencoFatture.numero_civico,'');
        if COALESCE(elencoFatture.frazione,'') <> '' THEN
            benef_indirizzo= benef_indirizzo|| ' Frazione '||COALESCE(elencoFatture.frazione,'');
        end if;
        if COALESCE(elencoFatture.interno,'') <> '' THEN
            benef_indirizzo= benef_indirizzo|| ' Interno '||COALESCE(elencoFatture.interno,'');
        end if;    
        benef_cap=COALESCE(elencoFatture.zip_code,'');
        benef_comune=COALESCE(elencoFatture.comune_desc,'');
        benef_prov=COALESCE(elencoFatture.sigla_prov,'');
        benef_nazione=COALESCE(elencoFatture.nazione_desc,''); 
        tipo_documento=elencoFatture.doc_tipo_code;
        oggetto_fattura=COALESCE(elencoFatture.doc_desc,'');
        
        if COALESCE(elencoFatture.subdociva_desc,'') ='' THEN
            descr_fattura=COALESCE(elencoFatture.doc_desc,'');
        else
            descr_fattura=COALESCE(elencoFatture.subdociva_desc,'');
        end if;
        num_fattura=elencoFatture.doc_numero;
        anno_fattura=elencoFatture.doc_anno;
        data_fattura=elencoFatture.doc_data_emissione;
        imp_lordo_fattura=elencoFatture.doc_importo;
        imp_imponibile_fattura=0;
        data_scadenza_fattura=elencoFatture.doc_data_scadenza;
       
        numero_aliq_fattura=COALESCE(elencoFatture.subdociva_numero,0);
        anno_aliq_fattura=COALESCE(elencoFatture.subdociva_anno,'');
        perc_aliq_fattura=COALESCE(elencoFatture.ivaaliquota_perc,0);
        imp_aliq_fattura=COALESCE(elencoFatture.ivamov_imposta,0);
        imponibile_aliq_fattura=COALESCE(elencoFatture.ivamov_imponibile,0);
        desc_aliq_fattura=COALESCE(elencoFatture.ivaaliquota_desc,'');
        doc_id=elencoFatture.doc_id;
        bollo_fattura=COALESCE(elencoFatture.codbollo_desc,'');
        
       -- raise notice 'DOC_ID = %', doc_id;
       -- raise notice 'ivamov_imponibile = %, ivamov_imposta = %',elencoFatture.ivamov_imponibile, elencoFatture.ivamov_imposta;
       -- raise notice 'ivamov_totale = %, ivaaliquota_code = %',elencoFatture.ivamov_totale, elencoFatture.ivaaliquota_code;
        --raise notice 'ivaaliquota_desc = %,  ivaaliquota_perc = %',elencoFatture.ivaaliquota_desc,elencoFatture.ivaaliquota_perc;

            /* cerco gli attributi: NOTE e Termine di Pagamento */
        for elencoAttr in 
            select t_attr.attr_code, r_doc_attr.testo, r_doc_attr.numerico
            from siac_r_doc_attr r_doc_attr,
                    siac_t_attr t_attr
            where r_doc_attr.attr_id=t_attr.attr_id
            and r_doc_attr.doc_id=elencoFatture.doc_id
            and upper(t_attr.attr_code) in ('TERMINEPAGAMENTO','NOTE')
            and r_doc_attr.data_cancellazione is null
            and t_attr.data_cancellazione is null
        loop
            if upper(elencoAttr.attr_code)='TERMINEPAGAMENTO' THEN
                termine_pagamento=COALESCE(elencoAttr.numerico ::VARCHAR,'') ;
            elsif upper(elencoAttr.attr_code)='NOTE' THEN        
                note_fattura=COALESCE(elencoAttr.testo,'');
            end if;
        end loop;                
            
    return next;



    nome_ente='';
    partita_iva_ente='';
    cf_ente='';
    indirizzo_ente='';
    tel_ente='';
    fax_ente='';
    benef_codice='';
    benef_cod_fiscale='';
    benef_partita_iva='';
    benef_nome='';
    benef_indirizzo='';
    benef_cap='';
    benef_comune='';
    benef_prov='';
    benef_nazione='';
    tipo_documento='';
    oggetto_fattura='';
    descr_fattura='';
    num_fattura='';
    anno_fattura=0;
    data_fattura=NULL;
    imp_lordo_fattura=0;
    imp_imponibile_fattura=0;
    imponibile_aliq_fattura=0;
    numero_aliq_fattura=0;
    anno_aliq_fattura='';
    perc_aliq_fattura=0;
    imp_aliq_fattura=0;
    desc_aliq_fattura='';
    doc_id=0;
    data_scadenza_fattura=NULL;
    bollo_fattura='';
    note_fattura='';
    termine_pagamento='';

    --raise notice 'fine numero mandato % ',elencoFatture.ord_numero;

    end loop;
ELSE
/* 18/10/2016: iva è legata alle quote , 
	nella query seguente non c'è legame con le quote */
raise notice 'query NEW';

    for elencoFatture in
    select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 		
            t_doc.doc_anno, t_doc.doc_numero, t_doc.doc_importo,
            t_doc.doc_data_emissione, t_doc.doc_desc, t_doc.doc_id,
            t_doc.doc_data_scadenza,
            t_soggetto.codice_fiscale cf_soggetto, t_soggetto.partita_iva piva_soggetto,
            t_soggetto.soggetto_desc, t_soggetto.soggetto_code,
            d_via_tipo.via_tipo_desc, t_indir_sogg.toponimo, t_indir_sogg.numero_civico,
            t_indir_sogg.frazione, t_indir_sogg.interno, t_indir_sogg.zip_code,
            t_comune.comune_desc, t_provincia.sigla_automobilistica sigla_prov,
            t_nazione.nazione_desc, tab1.subdociva_anno, tab1.subdociva_numero,
            tab1.subdociva_desc, d_doc_tipo.doc_tipo_code,
            t_ivamov.ivamov_imponibile, t_ivamov.ivamov_imposta, t_ivamov.ivamov_totale,
            t_iva_aliq.ivaaliquota_code, t_iva_aliq.ivaaliquota_desc, 
            t_iva_aliq.ivaaliquota_perc, d_cod_bollo.codbollo_desc,
            ts.subdoc_desc, tab1.doc_id doc_r_id , tab1.subdoc_id subdoc_r_id
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_doc t_doc
                    left join siac_t_subdoc ts
                    on ts.doc_id = t_doc.doc_id
                   /* left join  (           
                                select tsi.*, rdi.doc_id, rssi.subdoc_id
                                from   siac_t_subdoc_iva tsi
                                left join siac_r_doc_iva  rdi
                                on   rdi.dociva_r_id = tsi.dociva_r_id
                                left join siac_r_subdoc_subdoc_iva rssi
                                on   rssi.subdociva_id = tsi.subdociva_id
                                ) tab1          
                    on (ts.subdoc_id = tab1.subdoc_id or t_doc.doc_id = tab1.doc_id) */
                    left join  (           
                                select tsi.*, NULL doc_id, rssi.subdoc_id
                                from   siac_t_subdoc_iva tsi
                                left join siac_r_subdoc_subdoc_iva rssi
                                on   rssi.subdociva_id = tsi.subdociva_id
                                ) tab1          
                    on (ts.subdoc_id = tab1.subdoc_id )
    /*                LEFT JOIN siac_r_doc_iva r_doc_iva
                        ON (r_doc_iva.doc_id=t_doc.doc_id
                            AND r_doc_iva.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_subdoc_iva t_subdoc_iva
                        ON (t_subdoc_iva.dociva_r_id=r_doc_iva.dociva_r_id
                            AND t_subdoc_iva.data_cancellazione IS NULL)*/
                    LEFT JOIN siac_r_ivamov r_ivamov
                        ON (r_ivamov.subdociva_id=tab1.subdociva_id
                            AND r_ivamov.data_cancellazione IS NULL)
                    LEFT JOIN  siac_t_ivamov t_ivamov
                        ON (t_ivamov.ivamov_id=r_ivamov.ivamov_id
                            AND t_ivamov.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_iva_aliquota t_iva_aliq
                        ON (t_iva_aliq.ivaaliquota_id=t_ivamov.ivaaliquota_id
                            AND t_iva_aliq.data_cancellazione IS NULL)
                    LEFT JOIN siac_d_codicebollo d_cod_bollo
                        ON (d_cod_bollo.codbollo_id=t_doc.codbollo_id
                            AND d_cod_bollo.data_cancellazione IS NULL),                     
                    siac_r_doc_sog r_doc_sog,                  
                    siac_d_doc_tipo d_doc_tipo,  
                    siac_r_doc_stato r_doc_stato,
                    siac_d_doc_stato d_doc_stato,
                    siac_t_soggetto t_soggetto
                    LEFT JOIN siac_t_indirizzo_soggetto t_indir_sogg
                        ON  (t_indir_sogg.soggetto_id=t_soggetto.soggetto_id
                                AND t_indir_sogg.principale='S'
                                AND  t_indir_sogg.data_cancellazione IS NULL)
                    LEFT JOIN siac_d_via_tipo d_via_tipo
                        ON (d_via_tipo.via_tipo_id=t_indir_sogg.via_tipo_id
                            AND d_via_tipo.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_comune t_comune		
                        ON (t_comune.comune_id=t_indir_sogg.comune_id
                            AND t_comune.data_cancellazione IS NULL)   
                    LEFT JOIN siac_r_comune_provincia r_com_provincia
                        ON (r_com_provincia.comune_id=t_comune.comune_id
                            AND r_com_provincia.data_cancellazione IS NULL) 
                    LEFT JOIN siac_t_provincia t_provincia	
                        ON (t_provincia.provincia_id=r_com_provincia.provincia_id
                            AND t_provincia.data_cancellazione IS NULL)
                    LEFT JOIN siac_t_nazione t_nazione
                        ON (t_nazione.nazione_id=t_comune.nazione_id
                            AND t_nazione.data_cancellazione IS NULL)
            WHERE  t_doc.ente_proprietario_id=ep.ente_proprietario_id       
               AND r_doc_sog.doc_id=t_doc.doc_id 	 
               AND d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id                
               AND t_soggetto.soggetto_id=r_doc_sog.soggetto_id
               AND d_doc_stato.doc_stato_id=r_doc_stato.doc_stato_id
               AND r_doc_stato.doc_id=t_doc.doc_id
                -- 21/03/2016: aggiunto il trim per togliere gli eventuali spazi.
               AND btrim(t_doc.doc_numero)=btrim(p_numero_doc)
               AND t_doc.doc_anno=p_anno_doc
               AND t_soggetto.soggetto_code=p_cod_sog  
               AND t_doc.ente_proprietario_id=p_ente_prop_id  
               AND d_doc_tipo.doc_tipo_code=p_tipo_documento
                /* 26/04/2016: aggiunto il controllo sullo stato del documento
                    per escludere le fatture annullate */
               AND d_doc_stato.doc_stato_code<>'A'
               AND ep.data_cancellazione IS NULL
               AND t_soggetto.data_cancellazione IS NULL
               AND r_doc_sog.data_cancellazione IS NULL 
               AND t_doc.data_cancellazione IS NULL     
               AND d_doc_tipo.data_cancellazione IS NULL      
               AND d_doc_stato.data_cancellazione IS NULL   
               AND r_doc_stato.data_cancellazione IS NULL  
               ORDER BY t_doc.doc_data_emissione, tab1.subdoc_id                           
    loop

        nome_ente=elencoFatture.ente_denominazione;
        partita_iva_ente='';
        cf_ente=COALESCE(elencoFatture.cod_fisc_ente,'');
        indirizzo_ente='';
        tel_ente='';
        fax_ente='';

        benef_codice=elencoFatture.soggetto_code;
        benef_cod_fiscale=COALESCE(elencoFatture.cf_soggetto,'');
        benef_partita_iva=COALESCE(elencoFatture.piva_soggetto,'');
        benef_nome=elencoFatture.soggetto_desc;
        benef_indirizzo=COALESCE(elencoFatture.via_tipo_desc,'')||' '||
            COALESCE(elencoFatture.toponimo,'')|| ' '||COALESCE(elencoFatture.numero_civico,'');
        if COALESCE(elencoFatture.frazione,'') <> '' THEN
            benef_indirizzo= benef_indirizzo|| ' Frazione '||COALESCE(elencoFatture.frazione,'');
        end if;
        if COALESCE(elencoFatture.interno,'') <> '' THEN
            benef_indirizzo= benef_indirizzo|| ' Interno '||COALESCE(elencoFatture.interno,'');
        end if;    
        benef_cap=COALESCE(elencoFatture.zip_code,'');
        benef_comune=COALESCE(elencoFatture.comune_desc,'');
        benef_prov=COALESCE(elencoFatture.sigla_prov,'');
        benef_nazione=COALESCE(elencoFatture.nazione_desc,''); 
        tipo_documento=elencoFatture.doc_tipo_code;
        oggetto_fattura=COALESCE(elencoFatture.doc_desc,'');
        
        raise notice 'elencoFatture.doc_r_id %', elencoFatture.doc_r_id;
        
       /* if elencoFatture.doc_r_id is not null then
          if COALESCE(elencoFatture.subdociva_desc,'') ='' THEN
              descr_fattura=COALESCE(elencoFatture.doc_desc,'');
          else
              descr_fattura=COALESCE(elencoFatture.subdociva_desc,'');
          end if; 
        else*/
          if COALESCE(elencoFatture.subdociva_desc,'') ='' THEN
              descr_fattura=COALESCE(elencoFatture.subdoc_desc,'');
          else
              descr_fattura=COALESCE(elencoFatture.subdociva_desc,'');
          end if;    
          
     
      --  end if; 
        num_fattura=elencoFatture.doc_numero;
        anno_fattura=elencoFatture.doc_anno;
        data_fattura=elencoFatture.doc_data_emissione;
        imp_lordo_fattura=elencoFatture.doc_importo;
        imp_imponibile_fattura=0;
        data_scadenza_fattura=elencoFatture.doc_data_scadenza;
       
        numero_aliq_fattura=COALESCE(elencoFatture.subdociva_numero,0);
        anno_aliq_fattura=COALESCE(elencoFatture.subdociva_anno,'');
        perc_aliq_fattura=COALESCE(elencoFatture.ivaaliquota_perc,0);
        imp_aliq_fattura=COALESCE(elencoFatture.ivamov_imposta,0);
        imponibile_aliq_fattura=COALESCE(elencoFatture.ivamov_imponibile,0);
        desc_aliq_fattura=COALESCE(elencoFatture.ivaaliquota_desc,'');
        doc_id=elencoFatture.doc_id;
        bollo_fattura=COALESCE(elencoFatture.codbollo_desc,'');
        subdoc_r_id=elencoFatture.subdoc_r_id;
        
       -- raise notice 'DOC_ID = %', doc_id;
       -- raise notice 'ivamov_imponibile = %, ivamov_imposta = %',elencoFatture.ivamov_imponibile, elencoFatture.ivamov_imposta;
       -- raise notice 'ivamov_totale = %, ivaaliquota_code = %',elencoFatture.ivamov_totale, elencoFatture.ivaaliquota_code;
        --raise notice 'ivaaliquota_desc = %,  ivaaliquota_perc = %',elencoFatture.ivaaliquota_desc,elencoFatture.ivaaliquota_perc;

            /* cerco gli attributi: NOTE e Termine di Pagamento */
        for elencoAttr in 
            select t_attr.attr_code, r_doc_attr.testo, r_doc_attr.numerico
            from siac_r_doc_attr r_doc_attr,
                    siac_t_attr t_attr
            where r_doc_attr.attr_id=t_attr.attr_id
            and r_doc_attr.doc_id=elencoFatture.doc_id
            and upper(t_attr.attr_code) in ('TERMINEPAGAMENTO','NOTE')
            and r_doc_attr.data_cancellazione is null
            and t_attr.data_cancellazione is null
        loop
            if upper(elencoAttr.attr_code)='TERMINEPAGAMENTO' THEN
                termine_pagamento=COALESCE(elencoAttr.numerico ::VARCHAR,'') ;
            elsif upper(elencoAttr.attr_code)='NOTE' THEN        
                note_fattura=COALESCE(elencoAttr.testo,'');
            end if;
        end loop;                
            
    return next;



    nome_ente='';
    partita_iva_ente='';
    cf_ente='';
    indirizzo_ente='';
    tel_ente='';
    fax_ente='';
    benef_codice='';
    benef_cod_fiscale='';
    benef_partita_iva='';
    benef_nome='';
    benef_indirizzo='';
    benef_cap='';
    benef_comune='';
    benef_prov='';
    benef_nazione='';
    tipo_documento='';
    oggetto_fattura='';
    descr_fattura='';
    num_fattura='';
    anno_fattura=0;
    data_fattura=NULL;
    imp_lordo_fattura=0;
    imp_imponibile_fattura=0;
    imponibile_aliq_fattura=0;
    numero_aliq_fattura=0;
    anno_aliq_fattura='';
    perc_aliq_fattura=0;
    imp_aliq_fattura=0;
    desc_aliq_fattura='';
    doc_id=0;
    data_scadenza_fattura=NULL;
    bollo_fattura='';
    note_fattura='';
    termine_pagamento='';
    subdoc_r_id=0;

    --raise notice 'fine numero mandato % ',elencoFatture.ord_numero;

    end loop;
end if;

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