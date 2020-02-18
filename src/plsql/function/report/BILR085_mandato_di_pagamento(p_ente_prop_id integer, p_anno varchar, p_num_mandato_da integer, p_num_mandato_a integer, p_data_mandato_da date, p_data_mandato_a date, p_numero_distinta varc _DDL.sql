/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
  importo_da_dedurre_ncd numeric,
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
cod_benef_cess_incasso:='';
desc_benef_cess_incasso:='';
codfisc_benef_cess_incasso:='';

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
   
/* 26/03/2018; SIAC-5973.
	Se il mandato e' annullato devono essere messi a 0 gli importi relativi a:
    	- importo_irpef_imponibile 
  		- importo_imposta 
  		- importo_inps_inponibile 
  		- importo_ritenuta 
  		- importo_netto.
*/   
/* 25/06/2018: SIAC-6216.
            	Aggiunti anche i dati del soggetto per valorizzare sul report
                il campo Beneficiario Amministrativo */
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
        select a.ord_id,c.accredito_tipo_desc, b.iban,
        		f.soggetto_code, f.soggetto_desc,
                f.codice_fiscale
            from siac_r_ordinativo_modpag a,
                siac_t_modpag b, siac_d_accredito_tipo c,
                siac_r_soggrel_modpag d,
                siac_r_soggetto_relaz e, 
                siac_t_soggetto f
            where a.soggetto_relaz_id=d.soggetto_relaz_id
              AND d.modpag_id=b.modpag_id
              AND b.accredito_tipo_id=c.accredito_tipo_id
              AND d.soggetto_relaz_id = e.soggetto_relaz_id
              AND f.soggetto_id = e.soggetto_id_a
              AND a.ente_proprietario_id = '||p_ente_prop_id||' 
              AND b.data_cancellazione IS NULL
              AND c.data_cancellazione IS NULL
              AND a.data_cancellazione IS NULL
              AND d.data_cancellazione IS NULL
              AND e.data_cancellazione IS NULL
              AND f.data_cancellazione IS NULL),
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
         -- 26/03/2018; SIAC-5973.
           CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
         	0::numeric
         else
         	COALESCE(reversale.importo_irpef_imponibile,0)::numeric end importo_irpef_imponibile,
         --case when reversale.onere_tipo_code=''IRPEF'' then reversale.importo_ord::numeric else 0::numeric end
         --importo_imposta,
         -- 26/03/2018; SIAC-5973.
         CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
         	0:: numeric
         else
         	COALESCE(reversale.importo_irpef_imposta,0)::numeric end importo_imposta,
        --    case when reversale.onere_tipo_code=''INPS'' then reversale.importo_imponibile::numeric else 0::numeric end
         --importo_inps_inponibile,
         -- 26/03/2018; SIAC-5973.
           CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
         	0::numeric
         else
         	COALESCE(reversale.importo_inps_imponibile,0)::numeric end importo_inps_inponibile,
         --case when reversale.onere_tipo_code=''INPS'' then reversale.importo_ord::numeric else 0::numeric end
         --importo_ritenuta,
         -- 26/03/2018; SIAC-5973.
         CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
         	0::numeric
         else
         	COALESCE(reversale.importo_inps_imposta,0)::numeric end importo_ritenuta,
         --COALESCE(mif.mif_ord_importo::numeric,0::numeric) / 100 ::numeric
		--	- case when reversale.onere_tipo_code=''INPS'' then reversale.importo_ord::numeric else 0::numeric end
		--	-case when reversale.onere_tipo_code=''IRPEF'' then reversale.importo_ord::numeric else 0::numeric end
		--	-case when reversale.relaz_tipo_code=''SPR'' then reversale.importo_ord::numeric else 0::numeric end 
       --  importo_netto,--daimplementare
       -- 26/03/2018; SIAC-5973.
        CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
       		0::numeric
        else 
        	COALESCE(mif.mif_ord_importo::numeric,0::numeric) / 100 ::numeric
        	-COALESCE(reversale.importo_irpef_imposta,0)::numeric
            -COALESCE(reversale.importo_inps_imposta,0)::numeric
            -COALESCE(reversale.importo_split,0)::numeric end importo_netto,
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
        -- 26/03/2018; SIAC-5973.
        CASE WHEN COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''') = ''A'' THEN
        	0::numeric
        ELSE 
        	COALESCE(reversale.importo_split,0)::numeric end importo_split_reverse,
        imp.anno_primo_impegno::varchar anno_primo_impegno,   
        case when mif.flusso_elab_mif_tipo_dec = true then ''Stampa giornaliera dei mandati di pagamento (BILR085): STAMPA NON UTILIZZABILE.''::varchar
        else '''||display_error||'''::varchar end display_error,
        COALESCE(upper(substring(mif.mif_ord_codice_funzione from 1 for 1)),'''')::varchar cod_stato_mandato,
        COALESCE(mif.mif_ord_bci_conto,'''')::varchar banca_cc_bitalia,
        COALESCE(doc.doc_tipo_code,'''')::varchar tipo_doc,
        COALESCE(doc.num_doc_ncd,'''')::varchar num_doc_ncd ,
        COALESCE(ndcimpded.importo_da_dedurre_ncd::numeric,0)::numeric importo_da_dedurre_ncd,
        COALESCE(modpagcess.soggetto_code,'''')::varchar cod_benef_cess_incasso,
        COALESCE(modpagcess.soggetto_desc,'''')::varchar desc_benef_cess_incasso,
        COALESCE(modpagcess.codice_fiscale,'''')::varchar codfisc_benef_cess_incasso
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