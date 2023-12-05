/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-6337 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_daregolarizzareprovvisorio (
  provc_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
BEGIN

number_out:=0.0;

with uno as ( 
  --provvisorio.importo SEGNO PIU 
  select case when(a.provc_importo) is null then 0 else a.provc_importo end importo_provvisorio 
  from siac_t_prov_cassa a where a.provc_id = provc_id_in
  and a.data_cancellazione is null
)
, due as (
  --sum( RegolarizzazioneProvvisiorio.importo) SEGNO MENO
  SELECT 
  case when(sum(b.ord_provc_importo)) is null then 0 else sum(b.ord_provc_importo) end importo_regolarizzazione_provvisorio 
  from siac_t_prov_cassa a, siac_r_ordinativo_prov_cassa b, siac_t_ordinativo c,siac_r_ordinativo_stato d ,siac_d_ordinativo_stato e
  where b.provc_id=a.provc_id
  and  a.provc_id = provc_id_in
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  and c.ord_id=b.ord_id 
  and d.ord_id=c.ord_id
  and e.ord_stato_id=d.ord_stato_id
  and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
  and e.ord_stato_code<>'A'
)
, tre AS( --9000
    --sum(Subdocumento.importo) SEGNO MENO
    select 
    case when(sum(c.subdoc_importo)) is null then 0 else sum(c.subdoc_importo) end  importo_subdoc
    ,case when(sum(c.subdoc_importo_da_dedurre)) is null then 0 else sum(c.subdoc_importo_da_dedurre) end  subdoc_importo_da_dedurre
    from siac_t_prov_cassa a, siac_r_subdoc_prov_cassa b, siac_t_subdoc c, siac_r_doc_stato d ,siac_d_doc_stato e
     where b.provc_id=a.provc_id 
     and c.subdoc_id=b.subdoc_id
     and a.provc_id = provc_id_in
     and a.data_cancellazione is null
     and b.data_cancellazione is null
     and c.data_cancellazione is null
     and d.data_cancellazione is null
     and e.data_cancellazione is null
     and d.doc_id=c.doc_id
     and e.doc_stato_id=d.doc_stato_id
     and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine, now())
     and e.doc_stato_code<>'A'
     and Not exists(
         select 1 from 
         siac_r_subdoc_ordinativo_ts z,
         siac_t_ordinativo_ts a1, siac_t_ordinativo b1,siac_r_ordinativo_stato c1,siac_d_ordinativo_stato d1
         where 
         z.ord_ts_id=a1.ord_ts_id and
         a1.ord_id=b1.ord_id and c1.ord_id=b1.ord_id and c1.ord_stato_id=d1.ord_stato_id and d1.ord_stato_code<>'A'
         and now() between c1.validita_inizio and coalesce(c1.validita_fine,now()) and a1.ord_ts_id=z.ord_ts_id
         and c.subdoc_id=z.subdoc_id
         and a1.data_cancellazione is null
         and b1.data_cancellazione is null
         and c1.data_cancellazione is null 
         and d1.data_cancellazione is null 
         and z.data_cancellazione is null 
     ) 
 )
, quattro as (
  -- sum(predocumento.importo) SEGNO MENO
  select  
  case when(sum(c.predoc_importo)) is null then 0 else sum(c.predoc_importo) end importo_predoc 
  from siac_t_prov_cassa a, siac_r_predoc_prov_cassa b, siac_t_predoc c, siac_r_predoc_stato d, siac_d_predoc_stato e
  where b.provc_id=a.provc_id
  and c.predoc_id=b.predoc_id
  and a.provc_id = provc_id_in
   and a.data_cancellazione is null
   and b.data_cancellazione is null
   and c.data_cancellazione is null
   and d.data_cancellazione is null
   and e.data_cancellazione is null
   and d.predoc_id=c.predoc_id
   and e.predoc_stato_id=d.predoc_stato_id
   and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine, now())
   and e.predoc_stato_code <>'A'
  and not exists (select 1 from siac_r_predoc_subdoc zz  where zz.predoc_id=c.predoc_id and zz.data_cancellazione is null)
)
select uno.importo_provvisorio - due.importo_regolarizzazione_provvisorio - tre.importo_subdoc + tre.subdoc_importo_da_dedurre - quattro.importo_predoc into number_out
from uno,due,tre,quattro;

return number_out;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--SIAC-6337 FINE


--SIAC-6306 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR104_stampa_ritenute"(p_ente_prop_id integer, p_anno varchar, p_data_mandato_da date, p_data_mandato_a date, p_data_trasm_da date, p_data_trasm_a date, p_tipo_ritenuta varchar, p_data_quietanza_da date, p_data_quietanza_a date);
DROP FUNCTION if exists siac."BILR104_stampa_ritenute_inps_irpeg"(p_ente_prop_id integer, p_anno varchar, p_data_mandato_da date, p_data_mandato_a date, p_data_trasm_da date, p_data_trasm_a date, p_tipo_ritenuta varchar, p_data_quietanza_da date, p_data_quietanza_a date);
DROP FUNCTION if exists siac."BILR104_stampa_ritenute_irap"(p_ente_prop_id integer, p_anno varchar, p_data_mandato_da date, p_data_mandato_a date, p_data_trasm_da date, p_data_trasm_a date, p_tipo_ritenuta varchar, p_data_quietanza_da date, p_data_quietanza_a date);
DROP FUNCTION if exists siac."BILR104_stampa_ritenute_irpef"(p_ente_prop_id integer, p_anno varchar, p_data_mandato_da date, p_data_mandato_a date, p_data_trasm_da date, p_data_trasm_a date, p_tipo_ritenuta varchar,  p_data_quietanza_da date,  p_data_quietanza_a date);
 
 
CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute" (
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
/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;


if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;*/

if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

if numeroParametriData = 0 THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if numeroParametriData>=2 THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if (p_data_trasm_da IS NULL AND p_data_trasm_a IS NOT NULL) OR 
	(p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;

if (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL) OR 
	(p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA MANDATO DA/A".';
    return next;
    return;
end if;

if (p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NOT NULL) OR 
	(p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;

    	/* 11/10/2016: cerco i mandati di tutte le ritenute tranne l'IRAP che 
        	deve essere estratta in modo diverso */
/* 30/05/2017: L'IRPEF deve essere gestita in modo simile all'IRAP in quanto 
	e' necessario calcolare il dato della ritenuta proporzionandola con la
    percentuale calcolata delle relativie quote della fattura */
--if p_tipo_ritenuta <> 'IRAP' THEN

/* 01/08/2018 SIAC-6303.
	Per ragioni di leggibilita' della procedura la gestione delle diverse
    aliquote e' stata suddivisa in procedure apposite.
*/
if p_tipo_ritenuta in ('INPS','IRPEG') THEN
  return query
  select outpt.*
  from
  (
      select *
      from "BILR104_stampa_ritenute_inps_irpeg"(p_ente_prop_id, p_anno, p_data_mandato_da,
          p_data_mandato_a, p_data_trasm_da, p_data_trasm_a, p_tipo_ritenuta,
          p_data_quietanza_da, p_data_quietanza_a)
  ) outpt;


	/* 11/10/2016: e' stata richiesta IRAP, estraggo solo i dati relativi */
elsif p_tipo_ritenuta = 'IRAP' THEN
	return query
	select outpt.*
	from
	(
		select *
		from "BILR104_stampa_ritenute_irap"(p_ente_prop_id, p_anno, p_data_mandato_da,
			p_data_mandato_a, p_data_trasm_da, p_data_trasm_a, p_tipo_ritenuta,
    		p_data_quietanza_da, p_data_quietanza_a)
	) outpt;

elsif p_tipo_ritenuta = 'IRPEF' THEN

	return query
	select outpt.*
	from
	(
		select *
		from "BILR104_stampa_ritenute_irpef"(p_ente_prop_id, p_anno, p_data_mandato_da,
			p_data_mandato_a, p_data_trasm_da, p_data_trasm_a, p_tipo_ritenuta,
    		p_data_quietanza_da, p_data_quietanza_a)
	) outpt;

   
end if; -- FINE IF p_tipo_ritenuta

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
                  and r_ord_quietanza.validita_fine is null )  ,
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
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
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
ORDER BY irpef.doc_id, irpef.subdoc_id '; 

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

CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute_inps_irpeg" (
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
	Funzione creata per la gestione dell'aliquota IRPEF.

*/

	select a.ente_denominazione, a.codice_fiscale
into  ente_denominazione, cod_fisc_ente
from  siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id;
    
select a.bil_id 
into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = p_anno;

/* 07/09/2017: rivista la modalita' di estrazione dei dati INPS e IRPEG per velocizzare 
    la procedura.
    In particolare e' stata creata la function fnc_bilr104_tab_reversali per estrarre
    tutte le reversali per mandato in modo da estrarre tutte le informazioni in un
    colpo solo senza dover cercare le reversali nel ciclo per ogni mandato. 
    Corretto anche un problema relativo ai casi in cui un mandato ha piu' reversali 
    collegate, fatto in modo di sommare gli importi IMPONIBILE, ENTE e RITENUTA ma
    solo se la reversale collegata ha un onere del tipo richiesto (INPS o IRPEG). */

miaQuery ='
with ordinativo as (
    select t_ordinativo.ord_anno,
           t_ordinativo.ord_desc, 
           t_ordinativo.ord_numero,
           t_ordinativo.ord_emissione_data,        
           t_ord_ts_det.ord_ts_det_importo,
           d_ord_stato.ord_stato_code,
           t_ordinativo.ord_id,
           t_ord_ts_det.ord_ts_id
    from  siac_t_ordinativo t_ordinativo,
          siac_t_ordinativo_ts t_ord_ts,
          siac_t_ordinativo_ts_det t_ord_ts_det,
          siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
          siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato d_ord_stato,
          siac_d_ordinativo_tipo  d_ord_tipo
    where t_ordinativo.ente_proprietario_id = ' ||p_ente_prop_id||'
    and   t_ordinativo.bil_id =  '||bilancio_id ||'    
    and   d_ts_det_tipo.ord_ts_det_tipo_code = ''A''            
    and   d_ord_stato.ord_stato_code <> ''A''
    and   d_ord_tipo.ord_tipo_code = ''P''
    and   r_ord_stato.validita_fine is null 
    and   t_ordinativo.ord_id = t_ord_ts.ord_id
    and   t_ord_ts.ord_ts_id = t_ord_ts_det.ord_ts_id
    and   t_ord_ts_det.ord_ts_det_tipo_id = d_ts_det_tipo.ord_ts_det_tipo_id
    and   t_ordinativo.ord_id = r_ord_stato.ord_id
    and   r_ord_stato.ord_stato_id = d_ord_stato.ord_stato_id
    and   t_ordinativo.ord_tipo_id = d_ord_tipo.ord_tipo_id ';
	if p_data_mandato_da is not null and p_data_mandato_a is not null THEN
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_mandato_da ||''' and '''||p_data_mandato_a||'''';
	elsif p_data_trasm_da is not null and p_data_trasm_a is not null THEN 
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_trasm_da || ''' and '''||p_data_trasm_a||'''';
	end if;
    
    miaQuery=miaQuery||' 
    and   t_ordinativo.data_cancellazione is null
    and   t_ord_ts.data_cancellazione is null
    and   t_ord_ts_det.data_cancellazione is null
    and   d_ts_det_tipo.data_cancellazione is null
    and   r_ord_stato.data_cancellazione is null
    and   d_ord_stato.data_cancellazione is null
    and   d_ord_tipo.data_cancellazione is null
    )
    , capitolo as (
    select t_bil_elem.elem_code, 
           t_bil_elem.elem_code2,
           r_ordinativo_bil_elem.ord_id,
           t_bil_elem.elem_id       
    from   siac_r_ordinativo_bil_elem r_ordinativo_bil_elem, 
           siac_t_bil_elem t_bil_elem
    where  r_ordinativo_bil_elem.elem_id = t_bil_elem.elem_id
    and    r_ordinativo_bil_elem.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ordinativo_bil_elem.data_cancellazione is null
    and    t_bil_elem.data_cancellazione is null     
    )
    , movimento as (
    select distinct t_movgest.movgest_anno,
           r_liq_ord.sord_id
    from  siac_r_liquidazione_ord r_liq_ord,
          siac_r_liquidazione_movgest r_liq_movgest,
          siac_t_movgest t_movgest,
          siac_t_movgest_ts t_movgest_ts
    where r_liq_ord.liq_id = r_liq_movgest.liq_id
    and   r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
    and   t_movgest_ts.movgest_id = t_movgest.movgest_id
    and   t_movgest.ente_proprietario_id = '||p_ente_prop_id||'
    and   r_liq_ord.data_cancellazione is null
    and   r_liq_movgest.data_cancellazione is null
    and   t_movgest.data_cancellazione is null
    and   t_movgest_ts.data_cancellazione is null
    )
    , soggetto as (
    select t_soggetto.soggetto_code, 
           t_soggetto.soggetto_desc,  
           t_soggetto.partita_iva,
           t_soggetto.codice_fiscale,
           r_ord_soggetto.ord_id
    from   siac_r_ordinativo_soggetto r_ord_soggetto,
           siac_t_soggetto t_soggetto
    where  r_ord_soggetto.soggetto_id = t_soggetto.soggetto_id
    and    t_soggetto.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ord_soggetto.data_cancellazione is null  
    and    t_soggetto.data_cancellazione is null
    )
    , reversali as (select * from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||''',true))
    select '''||ente_denominazione||''' ente_denominazione, '''||
           cod_fisc_ente||''' cod_fisc_ente, '''||
           p_anno||''' anno_eser,
           ordinativo.ord_anno,
           ordinativo.ord_desc, 
           ordinativo.ord_numero,
           ordinativo.ord_emissione_data,        
           -- ordinativo.ord_ts_det_importo,
           SUM(ordinativo.ord_ts_det_importo) IMPORTO_TOTALE,
           ordinativo.ord_stato_code,
           ordinativo.ord_id,
           capitolo.elem_code cod_cap, 
           capitolo.elem_code2 cod_art,
           capitolo.elem_id,
           movimento.movgest_anno anno_impegno,
           soggetto.soggetto_code, 
           soggetto.soggetto_desc,  
           soggetto.partita_iva,
           soggetto.codice_fiscale,
           reversali.*
    from  ordinativo         
    inner join capitolo  on ordinativo.ord_id = capitolo.ord_id
    inner join movimento on ordinativo.ord_ts_id = movimento.sord_id
    inner join soggetto  on ordinativo.ord_id = soggetto.ord_id
    inner join reversali  on ordinativo.ord_id = reversali.ord_id
    left  join siac_r_ordinativo_quietanza r_ord_quietanza  
    	ON (ordinativo.ord_id = r_ord_quietanza.ord_id 
            and r_ord_quietanza.data_cancellazione is null 
            -- 10/10/2017: aggiunto test sulla data di fine validita'' 
            -- per prendere la quietanza corretta.
            and r_ord_quietanza.validita_fine is null )
	where reversali.onere_tipo_code='''||p_tipo_ritenuta||'''';
    if p_data_quietanza_da is not null and p_data_quietanza_a is not null THEN
		miaQuery=miaQuery||' 
		and to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
        	between ''' ||p_data_quietanza_da ||''' and ''' ||p_data_quietanza_a||'''';
    end if;
	miaQuery=miaQuery||' 
    group by ente_denominazione, cod_fisc_ente, anno_eser,
             ordinativo.ord_anno,
             ordinativo.ord_desc, 
             ordinativo.ord_numero,
             ordinativo.ord_emissione_data,
             ordinativo.ord_stato_code,
             ordinativo.ord_id,
             capitolo.elem_code, 
             capitolo.elem_code2,
             capitolo.elem_id,  
             movimento.movgest_anno,
             soggetto.soggetto_code, 
             soggetto.soggetto_desc,  
             soggetto.partita_iva,
             soggetto.codice_fiscale,
             reversali.ord_id,      
             reversali.conta_reversali,  
             reversali.codice_risc,  
             reversali.onere_code,  
             reversali.onere_tipo_code,  
             reversali.importo_imponibile,  
             reversali.importo_ente,  
             reversali.importo_imposta,  
             reversali.importo_ritenuta,  
             --reversali.importo_netto,  
             reversali.importo_reversale,  
             reversali.importo_ord,  
             reversali.attivita_inizio,  
             reversali.attivita_fine,  
             reversali.attivita_code,  
             reversali.attivita_desc,
             reversali.code_caus_770,
			 reversali.desc_caus_770,
			 reversali.code_caus_esenz,
			 reversali.desc_caus_esenz,
             reversali.stato_reversale ,
             reversali.num_reversale  
    order by ordinativo.ord_numero, ordinativo.ord_emissione_data ';
raise notice 'miaQuery = %', miaQuery;


for 
  elencoMandati in execute miaQuery    
          
loop

    importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);

    codice_risc:=elencoMandati.codice_risc;
    if upper(elencoMandati.onere_tipo_code) = 'INPS' THEN
      codice_tributo_inps=COALESCE(elencoMandati.onere_code,'');
      tipo_ritenuta_inps=upper(elencoMandati.onere_tipo_code);        
      importo_imponibile_inps = elencoMandati.importo_imponibile;
      --raise notice 'ord_id = % - IMPON = %', elencoMandati.ord_id, elencoMandati.importo_imponibile;
      importo_ente_inps=elencoMandati.importo_ente;                   
      importo_ritenuta_inps = elencoMandati.importo_ord;    
      importo_netto_inps=importo_lordo_mandato-elencoMandati.importo_ritenuta;-- elencoMandati.importo_netto;-- importo_lordo_mandato-importo_ritenuta_inps;
      attivita_inizio:=elencoMandati.attivita_inizio;
      attivita_fine:=elencoMandati.attivita_fine;
      attivita_code:=elencoMandati.attivita_code;
      attivita_desc:=elencoMandati.attivita_desc;
    elsif upper(elencoMandati.onere_tipo_code) = 'IRPEG' THEN

      codice_tributo_irpeg=COALESCE(elencoMandati.onere_code,'');
      tipo_ritenuta_irpeg=upper(elencoMandati.onere_tipo_code);    		
      importo_imponibile_irpeg = elencoMandati.importo_imponibile;
      importo_ritenuta_irpeg = elencoMandati.importo_ord;    
                                        
      importo_netto_irpeg=importo_lordo_mandato-elencoMandati.importo_ritenuta;  
      code_caus_770:=COALESCE(elencoMandati.code_caus_770,'');
      desc_caus_770:=COALESCE(elencoMandati.desc_caus_770,'');
      code_caus_esenz:=COALESCE(elencoMandati.code_caus_esenz,'');
      desc_caus_esenz:=COALESCE(elencoMandati.desc_caus_esenz,'');
    end if; 
      
      /* 07/09/2017: restituisco solo i dati relativi alla ritenuta richiesta */
     if (p_tipo_ritenuta='INPS' AND tipo_ritenuta_inps <> '') OR
             (p_tipo_ritenuta='IRPEG' AND tipo_ritenuta_irpeg <> '') THEN
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
            
          return next;
       end if;
     
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


--SIAC-6306 - Maurizio - FINE 

-- SIAC-6292 - Sofia - INIZIO
drop function if exists siac.fnc_dba_create_index (
  table_in text,
  index_in text,
  index_columns_in text,
  index_where_def_in text,
  index_unique_in boolean
);

CREATE OR REPLACE FUNCTION siac.fnc_dba_create_index (
  table_in text,
  index_in text,
  index_columns_in text,
  index_where_def_in text,
  index_unique_in boolean
)
RETURNS text AS
$body$
declare

query_var text;

query_to_exe text;
esito text;
begin

 query_var:= 'CREATE '
               ||(case when index_unique_in = true then 'UNIQUE '
                  else ' ' end)
               ||'INDEX '
               ||index_in|| ' ON ' || table_in || ' USING BTREE ( '||index_columns_in||' )'
               ||(case when coalesce(index_where_def_in,'')!='' then ' WHERE ( '||index_where_def_in||' );'
                  else ';' end);
-- raise notice 'query_var=%',query_var;

 select  query_var into query_to_exe
 where
 not exists
 (
  SELECT 1
  FROM pg_class pg
  WHERE pg.relname=index_in
  and   pg.relkind='i'
 );

 if query_to_exe is not null then
 	esito:='indice creato';
  	execute query_to_exe;

 else
	esito:='indice '||index_in||' gia presente';
 end if;

 return esito;

exception
    when RAISE_EXCEPTION THEN
    esito:=substring(upper(SQLERRM) from 1 for 2500);
        return esito;
	when others  THEN
	esito:=' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return esito;


end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


drop VIEW if exists siac.siac_v_dwh_mod_imp_sogg_classe;
drop VIEW if exists siac.siac_v_dwh_mod_impegno_sogg;
drop VIEW if exists siac.siac_v_dwh_mod_impegno_classe;
drop VIEW if exists siac.siac_v_dwh_mod_impegno;
drop VIEW if exists siac.siac_v_dwh_mod_accertamento;
drop VIEW if exists siac.siac_v_dwh_mod_accert_sogg;
drop VIEW if exists siac.siac_v_dwh_mod_accert_classe;

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_impegno
(
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    importo_modifica,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    ente_proprietario_id,
    desc_stato_modifica,
    flag_reimputazione,
    anno_reimputazione,
    validita_inizio,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
WITH zz AS(
  SELECT l.anno,
         b.movgest_anno,
         b.movgest_numero,
         c.movgest_ts_code,
         c.movgest_ts_desc,
         dmtt.movgest_ts_tipo_code,
         a.movgest_ts_det_importo,
         d.mod_num,
         d.mod_desc,
         f.mod_stato_code,
         g.mod_tipo_code,
         g.mod_tipo_desc,
         h.attoamm_anno,
         h.attoamm_numero,
         daat.attoamm_tipo_code,
         a.ente_proprietario_id,
         h.attoamm_id,
         f.mod_stato_desc,
         a.mtdm_reimputazione_flag,
         a.mtdm_reimputazione_anno,
         d.validita_inizio,
         d.data_creazione -- 30.08.2018 Sofia jira-6292
  FROM siac_t_movgest_ts_det_mod a
       JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
       JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
       JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
       JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
       JOIN siac_t_modifica d ON d.mod_id = e.mod_id
       JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
       LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND
         g.data_cancellazione IS NULL
       JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
       JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id =
         h.attoamm_tipo_id
       JOIN siac_t_bil i ON i.bil_id = b.bil_id
       JOIN siac_t_periodo l ON i.periodo_id = l.periodo_id
       JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id =
         c.movgest_ts_tipo_id
  WHERE tt.movgest_tipo_code::text = 'I' ::text AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        tt.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        e.data_cancellazione IS NULL AND
        f.data_cancellazione IS NULL AND
        h.data_cancellazione IS NULL AND
        daat.data_cancellazione IS NULL AND
        i.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        dmtt.data_cancellazione IS NULL), aa AS(
    SELECT i.attoamm_id,
           l.classif_id,
           l.classif_code,
           l.classif_desc,
           m.classif_tipo_code
    FROM siac_r_atto_amm_class i,
         siac_t_class l,
         siac_d_class_tipo m,
         siac_r_class_fam_tree n,
         siac_t_class_fam_tree o,
         siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND
          m.classif_tipo_id = l.classif_tipo_id AND
          n.classif_id = l.classif_id AND
          n.classif_fam_tree_id = o.classif_fam_tree_id AND
          o.classif_fam_id = p.classif_fam_id AND
          p.classif_fam_code::text = '00005' ::text AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL)
      SELECT zz.anno AS bil_anno,
             zz.movgest_anno AS anno_impegno,
             zz.movgest_numero AS num_impegno,
             zz.movgest_ts_code AS cod_movgest_ts,
             zz.movgest_ts_desc AS desc_movgest_ts,
             zz.movgest_ts_tipo_code AS tipo_movgest_ts,
             zz.movgest_ts_det_importo AS importo_modifica,
             zz.mod_num AS numero_modifica,
             zz.mod_desc AS desc_modifica,
             zz.mod_stato_code AS stato_modifica,
             zz.mod_tipo_code AS cod_tipo_modifica,
             zz.mod_tipo_desc AS desc_tipo_modifica,
             zz.attoamm_anno AS anno_atto_amministrativo,
             zz.attoamm_numero AS num_atto_amministrativo,
             zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
             aa.classif_code AS cod_sac,
             aa.classif_desc AS desc_sac,
             aa.classif_tipo_code AS tipo_sac,
             zz.ente_proprietario_id,
             zz.mod_stato_desc AS desc_stato_modifica,
             zz.mtdm_reimputazione_flag AS flag_reimputazione,
             zz.mtdm_reimputazione_anno AS anno_reimputazione,
             zz.validita_inizio,
             zz.data_creazione -- 30.08.2018 Sofia jira-6292
      FROM zz
           LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id; 
		   
		   
CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_impegno_sogg (
    ente_proprietario_id,
    bil_anno_sogg,
    anno_impegno_sogg,
    num_impegno_sogg,
    cod_movgest_ts_sogg,
    desc_movgest_ts_sogg,
    tipo_movgest_ts_sogg,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggeto_old,
    desc_soggetto_old,
    cf_old,
    cf_estero_old,
    partita_iva_old,
    cod_soggeto_new,
    desc_soggetto_new,
    cf_new,
    cf_estero_new,
    partita_iva_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    tipo_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
 WITH a AS (
SELECT tm.ente_proprietario_id, tm.mod_num, tm.mod_desc,
            dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc, tp.anno,
            stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
            tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
            ts1.soggetto_code AS cod_soggeto_old,
            ts1.soggetto_desc AS desc_soggetto_old,
            ts1.codice_fiscale AS cf_old,
            ts1.codice_fiscale_estero AS cf_estero_old,
            ts1.partita_iva AS partita_iva_old,
            ts2.soggetto_code AS cod_soggeto_new,
            ts2.soggetto_desc AS desc_soggetto_new,
            ts2.codice_fiscale AS cf_new,
            ts2.codice_fiscale_estero AS cf_estero_new,
            ts2.partita_iva AS partita_iva_new, tam.attoamm_anno,
            tam.attoamm_numero, daat.attoamm_tipo_code, tam.attoamm_id,
            dms.mod_stato_desc,
            tm.data_creazione, -- 30.08.2018 Sofia jira-6292
                CASE
                    WHEN rmtsm.soggetto_id_new = rmtsm.soggetto_id_old THEN 'CS'::text
                    WHEN rmtsm.soggetto_id_new IS NULL THEN 'SC'::text
                    ELSE 'SS'::text
                END AS tipo_modifica
FROM siac_r_movgest_ts_sog_mod rmtsm
      JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = rmtsm.mod_stato_r_id
   JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
   JOIN siac_d_modifica_stato dms ON rms.mod_stato_id = dms.mod_stato_id
   LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND
       dmt.data_cancellazione IS NULL
   JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
   JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
   JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rmtsm.movgest_ts_id
   JOIN siac_t_soggetto ts1 ON ts1.soggetto_id = rmtsm.soggetto_id_old
   LEFT JOIN siac_t_soggetto ts2 ON ts2.soggetto_id = rmtsm.soggetto_id_new AND
       ts2.data_cancellazione IS NULL
   JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
   JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
   JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
   JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
   JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'I'::text AND rmtsm.data_cancellazione IS
    NULL AND rms.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dms.data_cancellazione IS NULL AND tam.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL AND ts1.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL AND stm.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tp.data_cancellazione IS NULL AND tb.data_cancellazione IS NULL
        ), b AS (
    SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
            tc.classif_desc, dct.classif_tipo_code
    FROM siac_r_atto_amm_class raac, siac_t_class tc,
            siac_d_class_tipo dct, siac_r_class_fam_tree cft,
            siac_t_class_fam_tree tcft, siac_d_class_fam dcf
    WHERE raac.classif_id = tc.classif_id AND dct.classif_tipo_id =
        tc.classif_tipo_id AND cft.classif_id = tc.classif_id AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id AND tcft.classif_fam_id = dcf.classif_fam_id AND dcf.classif_fam_code::text = '00005'::text AND raac.data_cancellazione IS NULL AND tc.data_cancellazione IS NULL AND dct.data_cancellazione IS NULL AND cft.data_cancellazione IS NULL AND tcft.data_cancellazione IS NULL AND dcf.data_cancellazione IS NULL
    )
    SELECT a.ente_proprietario_id, a.anno AS bil_anno_sogg,
    a.movgest_anno AS anno_impegno_sogg, a.movgest_numero AS num_impegno_sogg,
    a.movgest_ts_code AS cod_movgest_ts_sogg,
    a.movgest_ts_desc AS desc_movgest_ts_sogg,
    a.movgest_ts_tipo_code AS tipo_movgest_ts_sogg,
    a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
    a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
    a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggeto_old,
    a.desc_soggetto_old, a.cf_old, a.cf_estero_old, a.partita_iva_old,
    a.cod_soggeto_new, a.desc_soggetto_new, a.cf_new, a.cf_estero_new,
    a.partita_iva_new, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS num_atto_amministrativo,
    a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
    b.classif_tipo_code AS tipo_sac, a.mod_stato_desc AS desc_stato_modifica,
    a.tipo_modifica,
    a.data_creazione -- 30.08.2018 Sofia jira-6292
    FROM a
   LEFT JOIN b ON a.attoamm_id = b.attoamm_id;   

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_impegno_classe (
    ente_proprietario_id,
    bil_anno_classe,
    anno_impegno_classe,
    num_impegno_classe,
    cod_movgest_ts_classe,
    desc_movgest_ts_classe,
    tipo_movgest_ts_classe,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggetto_classe_old,
    desc_soggetto_classe_old,
    cod_tipo_sog_classe_old,
    desc_tipo_sog_classe_old,
    cod_soggetto_classe_new,
    desc_soggetto_classe_new,
    cod_tipo_sog_classe_new,
    desc_tipo_sog_classe_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    tipo_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
   )
AS
 WITH
 a AS
 (
   SELECT tm.ente_proprietario_id, tm.mod_num, tm.mod_desc,
          dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc,
          tam.attoamm_anno, tam.attoamm_numero, daat.attoamm_tipo_code,
          tp.anno, stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
          tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
          dsc1.soggetto_classe_code AS cod_soggetto_classe_old,
          dsc1.soggetto_classe_desc AS desc_soggetto_classe_old,
          dsct1.soggetto_classe_tipo_code AS cod_tipo_sog_classe_old,
          dsct1.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_old,
          dsc2.soggetto_classe_code AS cod_soggetto_classe_new,
          dsc2.soggetto_classe_desc AS desc_soggetto_classe_new,
          dsct2.soggetto_classe_tipo_code AS cod_tipo_sog_classe_new,
          dsct2.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_new,
          tam.attoamm_id, dms.mod_stato_desc,
          tm.data_creazione, -- 30.08.2018 Sofia jira-6292
          CASE WHEN dmtt.movgest_ts_tipo_code::text = 'S'::text THEN
                  (
				    SELECT count(mtsm1.*) AS count
				    FROM siac_r_movgest_ts_sogclasse_mod mtsm1
                	  JOIN siac_r_modifica_stato rms1 ON rms1.mod_stato_r_id = mtsm1.mod_stato_r_id
		              JOIN siac_t_modifica tm1 ON tm1.mod_id = rms1.mod_id
	    	          JOIN siac_d_modifica_stato dms1 ON dms1.mod_stato_id = rms1.mod_stato_id
	                  LEFT JOIN siac_d_modifica_tipo dmt1 ON dmt1.mod_tipo_id = tm1.mod_tipo_id
	                                 AND dmt1.data_cancellazione IS NULL AND dmt1.mod_tipo_code::text = dmt.mod_tipo_code::text
			          JOIN siac_t_atto_amm tam1 ON tam1.attoamm_id = tm1.attoamm_id
	                  JOIN siac_d_atto_amm_tipo daat1 ON daat1.attoamm_tipo_id = tam1.attoamm_tipo_id
	                  JOIN siac_t_movgest_ts tmt1 ON tmt1.movgest_ts_id = mtsm1.movgest_ts_id
	                  JOIN siac_d_soggetto_classe dsc11 ON dsc11.soggetto_classe_id = mtsm1.soggetto_classe_id_old
			          LEFT JOIN siac_d_soggetto_classe dsc21 ON dsc21.soggetto_classe_id =  mtsm1.soggetto_classe_id_new AND dsc21.data_cancellazione IS NULL
				      JOIN siac_d_soggetto_classe_tipo dsct11 ON dsct11.soggetto_classe_tipo_id = dsc11.soggetto_classe_tipo_id
	                  LEFT JOIN siac_d_soggetto_classe_tipo dsct21 ON dsct21.soggetto_classe_tipo_id = dsc21.soggetto_classe_tipo_id AND dsct21.data_cancellazione IS NULL
				      JOIN siac_d_movgest_ts_tipo dmtt1 ON dmtt1.movgest_ts_tipo_id = tmt1.movgest_ts_tipo_id
	 				  JOIN siac_t_movgest stm1 ON stm1.movgest_id = tmt1.movgest_id
					  JOIN siac_d_movgest_tipo sdmt1 ON sdmt1.movgest_tipo_id = stm1.movgest_tipo_id
					  JOIN siac_t_bil tb1 ON tb1.bil_id = stm1.bil_id
	   			      JOIN siac_t_periodo tp1 ON tp1.periodo_id = tb1.periodo_id
				    WHERE sdmt1.movgest_tipo_code::text = 'I'::text
                    AND   dmtt1.movgest_ts_tipo_code::text = 'T'::text
                    AND stm1.movgest_anno = stm.movgest_anno
                    AND stm1.movgest_numero = stm.movgest_numero
                    AND tm1.mod_num = tm.mod_num AND dms1.mod_stato_code::text = dms.mod_stato_code::text
                    AND tm1.ente_proprietario_id = tm.ente_proprietario_id
                    AND tp1.anno::text = tp.anno::text
                    AND mtsm1.data_cancellazione IS NULL
                    AND rms1.data_cancellazione IS NULL
                    AND tm1.data_cancellazione IS NULL
                    AND dms1.data_cancellazione IS NULL
                    AND dmt1.data_cancellazione IS NULL
                    AND tam1.data_cancellazione IS NULL
                    AND daat1.data_cancellazione IS NULL
                    AND tmt1.data_cancellazione IS NULL
                    AND dsc11.data_cancellazione IS NULL
                    AND dsct11.data_cancellazione IS NULL
                    AND dmtt1.data_cancellazione IS NULL
                    AND tm1.data_cancellazione IS NULL
                    AND dmt.data_cancellazione IS NULL
                    AND tb1.data_cancellazione IS NULL
                    AND tp1.data_cancellazione IS NULL
			    )
                ELSE 0::bigint  END AS verifica_record_doppi,
                CASE WHEN mtsm.soggetto_classe_id_new = mtsm.soggetto_classe_id_old THEN 'SC'::text
                     WHEN mtsm.soggetto_classe_id_new IS NULL THEN 'CS'::text
                     ELSE 'CC'::text
                END AS tipo_modifica
FROM siac_r_movgest_ts_sogclasse_mod mtsm
     JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = mtsm.mod_stato_r_id
     JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
     JOIN siac_d_modifica_stato dms ON dms.mod_stato_id = rms.mod_stato_id
     LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND dmt.data_cancellazione IS NULL
     JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
     JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
     JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = mtsm.movgest_ts_id
     JOIN siac_d_soggetto_classe dsc1 ON dsc1.soggetto_classe_id = mtsm.soggetto_classe_id_old
     LEFT JOIN siac_d_soggetto_classe dsc2 ON dsc2.soggetto_classe_id = mtsm.soggetto_classe_id_new AND dsc2.data_cancellazione IS NULL
     JOIN siac_d_soggetto_classe_tipo dsct1 ON dsct1.soggetto_classe_tipo_id = dsc1.soggetto_classe_tipo_id
     LEFT JOIN siac_d_soggetto_classe_tipo dsct2 ON dsct2.soggetto_classe_tipo_id = dsc2.soggetto_classe_tipo_id AND dsct2.data_cancellazione IS NULL
     JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
     JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
     JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
     JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
     JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'I'::text AND mtsm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   tm.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   dmt.data_cancellazione IS NULL
AND   tam.data_cancellazione IS NULL
AND   daat.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   dsc1.data_cancellazione IS NULL
AND   dsct1.data_cancellazione IS NULL
AND   dmtt.data_cancellazione IS NULL
AND   tm.data_cancellazione IS NULL
AND   dmt.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
),
b AS
(
   SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
          tc.classif_desc, dct.classif_tipo_code
   FROM siac_r_atto_amm_class raac, siac_t_class tc,
        siac_d_class_tipo dct, siac_r_class_fam_tree cft,
         siac_t_class_fam_tree tcft, siac_d_class_fam dcf
   WHERE raac.classif_id = tc.classif_id
   AND dct.classif_tipo_id = tc.classif_tipo_id
   AND cft.classif_id = tc.classif_id
   AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id
   AND tcft.classif_fam_id = dcf.classif_fam_id
   AND dcf.classif_fam_code::text = '00005'::text
   AND raac.data_cancellazione IS NULL
   AND tc.data_cancellazione IS NULL
   AND dct.data_cancellazione IS NULL
   AND cft.data_cancellazione IS NULL
   AND tcft.data_cancellazione IS NULL
   AND dcf.data_cancellazione IS NULL
)
SELECT  a.ente_proprietario_id,
        a.anno AS bil_anno_classe,
        a.movgest_anno AS anno_impegno_classe,
        a.movgest_numero AS num_impegno_classe,
        a.movgest_ts_code AS cod_movgest_ts_classe,
        a.movgest_ts_desc AS desc_movgest_ts_classe,
        a.movgest_ts_tipo_code AS tipo_movgest_ts_classe,
        a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
        a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
        a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggetto_classe_old,
        a.desc_soggetto_classe_old, a.cod_tipo_sog_classe_old,
        a.desc_tipo_sog_classe_old, a.cod_soggetto_classe_new,
        a.desc_soggetto_classe_new, a.cod_tipo_sog_classe_new,
        a.desc_tipo_sog_classe_new, a.attoamm_anno AS anno_atto_amministrativo,
        a.attoamm_numero AS num_atto_amministrativo,
        a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
        b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
        b.classif_tipo_code AS tipo_sac, a.mod_stato_desc AS desc_stato_modifica,
        a.tipo_modifica,
        a.data_creazione -- 30.08.2018 Sofia jira-6292
FROM a
     LEFT JOIN b ON a.attoamm_id = b.attoamm_id
WHERE a.verifica_record_doppi = 0;

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_imp_sogg_classe (
    ente_proprietario_id,
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_old,
    desc_old,
    cf_old,
    cf_estero_old,
    partita_iva_old,
    cod_tipo_old,
    desc_tipo_old,
    cod_new,
    desc_new,
    cf_new,
    cf_estero_new,
    partita_iva_new,
    cod_tipo_new,
    desc_tipo_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    tipo_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
  )
AS
(
SELECT siac_v_dwh_mod_impegno_sogg.ente_proprietario_id,
       siac_v_dwh_mod_impegno_sogg.bil_anno_sogg AS bil_anno,
       siac_v_dwh_mod_impegno_sogg.anno_impegno_sogg AS anno_impegno,
       siac_v_dwh_mod_impegno_sogg.num_impegno_sogg AS num_impegno,
       siac_v_dwh_mod_impegno_sogg.cod_movgest_ts_sogg AS cod_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.desc_movgest_ts_sogg AS desc_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.tipo_movgest_ts_sogg AS tipo_movgest_ts,
       siac_v_dwh_mod_impegno_sogg.numero_modifica,
       siac_v_dwh_mod_impegno_sogg.desc_modifica,
       siac_v_dwh_mod_impegno_sogg.stato_modifica,
       siac_v_dwh_mod_impegno_sogg.cod_tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.desc_tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.cod_soggeto_old AS cod_old,
       siac_v_dwh_mod_impegno_sogg.desc_soggetto_old AS desc_old,
       siac_v_dwh_mod_impegno_sogg.cf_old,
       siac_v_dwh_mod_impegno_sogg.cf_estero_old,
       siac_v_dwh_mod_impegno_sogg.partita_iva_old,
       NULL::character varying AS cod_tipo_old,
       NULL::character varying AS desc_tipo_old,
       siac_v_dwh_mod_impegno_sogg.cod_soggeto_new AS cod_new,
       siac_v_dwh_mod_impegno_sogg.desc_soggetto_new AS desc_new,
       siac_v_dwh_mod_impegno_sogg.cf_new,
       siac_v_dwh_mod_impegno_sogg.cf_estero_new,
       siac_v_dwh_mod_impegno_sogg.partita_iva_new,
       NULL::character varying AS cod_tipo_new,
       NULL::character varying AS desc_tipo_new,
       siac_v_dwh_mod_impegno_sogg.anno_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.num_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.cod_tipo_atto_amministrativo,
       siac_v_dwh_mod_impegno_sogg.cod_sac,
       siac_v_dwh_mod_impegno_sogg.desc_sac,
       siac_v_dwh_mod_impegno_sogg.tipo_sac,
       siac_v_dwh_mod_impegno_sogg.desc_stato_modifica,
       siac_v_dwh_mod_impegno_sogg.tipo_modifica,
       siac_v_dwh_mod_impegno_sogg.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_sogg
WHERE siac_v_dwh_mod_impegno_sogg.tipo_modifica = 'SS'::text
UNION
SELECT siac_v_dwh_mod_impegno_classe.ente_proprietario_id,
       siac_v_dwh_mod_impegno_classe.bil_anno_classe AS bil_anno,
       siac_v_dwh_mod_impegno_classe.anno_impegno_classe AS anno_impegno,
       siac_v_dwh_mod_impegno_classe.num_impegno_classe AS num_impegno,
       siac_v_dwh_mod_impegno_classe.cod_movgest_ts_classe  AS cod_movgest_ts,
       siac_v_dwh_mod_impegno_classe.desc_movgest_ts_classe AS desc_movgest_ts,
       siac_v_dwh_mod_impegno_classe.tipo_movgest_ts_classe AS tipo_movgest_ts,
       siac_v_dwh_mod_impegno_classe.numero_modifica,
       siac_v_dwh_mod_impegno_classe.desc_modifica,
       siac_v_dwh_mod_impegno_classe.stato_modifica,
       siac_v_dwh_mod_impegno_classe.cod_tipo_modifica,
       siac_v_dwh_mod_impegno_classe.desc_tipo_modifica,
       siac_v_dwh_mod_impegno_classe.cod_soggetto_classe_old AS cod_old,
       siac_v_dwh_mod_impegno_classe.desc_soggetto_classe_old AS desc_old,
       NULL::bpchar AS cf_old,
       NULL::character varying AS cf_estero_old,
       NULL::character varying AS partita_iva_old,
       siac_v_dwh_mod_impegno_classe.cod_tipo_sog_classe_old AS cod_tipo_old,
       siac_v_dwh_mod_impegno_classe.desc_tipo_sog_classe_old AS desc_tipo_old,
       siac_v_dwh_mod_impegno_classe.cod_soggetto_classe_new  AS cod_new,
       siac_v_dwh_mod_impegno_classe.desc_soggetto_classe_new AS desc_new,
       NULL::bpchar AS cf_new,
       NULL::character varying AS cf_estero_new,
       NULL::character varying AS partita_iva_new,
       siac_v_dwh_mod_impegno_classe.cod_tipo_sog_classe_new AS cod_tipo_new,
       siac_v_dwh_mod_impegno_classe.desc_tipo_sog_classe_new AS desc_tipo_new,
       siac_v_dwh_mod_impegno_classe.anno_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.num_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.cod_tipo_atto_amministrativo,
       siac_v_dwh_mod_impegno_classe.cod_sac,
       siac_v_dwh_mod_impegno_classe.desc_sac,
       siac_v_dwh_mod_impegno_classe.tipo_sac,
       siac_v_dwh_mod_impegno_classe.desc_stato_modifica,
       siac_v_dwh_mod_impegno_classe.tipo_modifica,
       siac_v_dwh_mod_impegno_classe.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_classe
WHERE siac_v_dwh_mod_impegno_classe.tipo_modifica = 'CC'::text)
UNION
SELECT soggetto.ente_proprietario_id,
       soggetto.bil_anno_sogg AS bil_anno,
       soggetto.anno_impegno_sogg AS anno_impegno,
       soggetto.num_impegno_sogg AS num_impegno,
       soggetto.cod_movgest_ts_sogg AS cod_movgest_ts,
       soggetto.desc_movgest_ts_sogg AS desc_movgest_ts,
       soggetto.tipo_movgest_ts_sogg AS tipo_movgest_ts,
       soggetto.numero_modifica,
       soggetto.desc_modifica,
       soggetto.stato_modifica,
       soggetto.cod_tipo_modifica,
       soggetto.desc_tipo_modifica,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN soggetto.cod_soggeto_old
            ELSE classe.cod_soggetto_classe_old
            END AS cod_old,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN soggetto.desc_soggetto_old
            ELSE classe.desc_soggetto_classe_old
            END AS desc_old,
       soggetto.cf_old,
       soggetto.cf_estero_old,
       soggetto.partita_iva_old,
       classe.cod_tipo_sog_classe_old AS cod_tipo_old,
       classe.desc_tipo_sog_classe_old AS desc_tipo_old,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.cod_soggetto_classe_new
            ELSE soggetto.cod_soggeto_new
            END AS cod_new,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.desc_soggetto_classe_new
            ELSE soggetto.desc_soggetto_new
            END AS desc_new,
       soggetto.cf_new,
       soggetto.cf_estero_new,
       soggetto.partita_iva_new,
       classe.cod_tipo_sog_classe_new AS cod_tipo_new,
       classe.desc_tipo_sog_classe_new AS desc_tipo_new,
       soggetto.anno_atto_amministrativo,
       soggetto.num_atto_amministrativo,
       soggetto.cod_tipo_atto_amministrativo,
       soggetto.cod_sac,
       soggetto.desc_sac,
       soggetto.tipo_sac,
       soggetto.desc_stato_modifica,
       soggetto.tipo_modifica,
       CASE WHEN soggetto.tipo_modifica = 'SC'::text THEN classe.data_creazione
            ELSE soggetto.data_creazione
            END AS data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_v_dwh_mod_impegno_sogg soggetto,
     siac_v_dwh_mod_impegno_classe classe
WHERE soggetto.ente_proprietario_id = classe.ente_proprietario_id
AND   soggetto.bil_anno_sogg::text = classe.bil_anno_classe::text
AND   soggetto.anno_impegno_sogg = classe.anno_impegno_classe
AND   soggetto.num_impegno_sogg = classe.num_impegno_classe
AND   soggetto.cod_movgest_ts_sogg::text = classe.cod_movgest_ts_classe::text
AND   soggetto.desc_movgest_ts_sogg::text = classe.desc_movgest_ts_classe::text
AND   soggetto.tipo_movgest_ts_sogg::text = classe.tipo_movgest_ts_classe::text
AND   soggetto.numero_modifica = classe.numero_modifica
AND   soggetto.desc_modifica::text = classe.desc_modifica::text
AND   soggetto.stato_modifica::text = classe.stato_modifica::text
AND   soggetto.cod_tipo_modifica::text = classe.cod_tipo_modifica::text
AND   soggetto.desc_tipo_modifica::text = classe.desc_tipo_modifica::text
AND   soggetto.anno_atto_amministrativo::text = classe.anno_atto_amministrativo::text
AND   soggetto.num_atto_amministrativo = classe.num_atto_amministrativo
AND   soggetto.cod_tipo_atto_amministrativo::text = classe.cod_tipo_atto_amministrativo::text
AND   soggetto.cod_sac::text = classe.cod_sac::text
AND   soggetto.desc_sac::text = classe.desc_sac::text
AND   soggetto.tipo_sac::text = classe.tipo_sac::text
AND   soggetto.desc_stato_modifica::text = classe.desc_stato_modifica::text
AND   soggetto.tipo_modifica = classe.tipo_modifica;

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accertamento(
    bil_anno,
    anno_accertamento,
    num_accertamento,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    importo_modifica,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    ente_proprietario_id,
    desc_stato_modifica,
    flag_reimputazione,
    anno_reimputazione,
    validita_inizio,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
WITH zz AS(
  SELECT l.anno,
         b.movgest_anno,
         b.movgest_numero,
         c.movgest_ts_code,
         c.movgest_ts_desc,
         dmtt.movgest_ts_tipo_code,
         a.movgest_ts_det_importo,
         d.mod_num,
         d.mod_desc,
         f.mod_stato_code,
         g.mod_tipo_code,
         g.mod_tipo_desc,
         h.attoamm_anno,
         h.attoamm_numero,
         daat.attoamm_tipo_code,
         a.ente_proprietario_id,
         h.attoamm_id,
         f.mod_stato_desc,
         a.mtdm_reimputazione_flag,
         d.validita_inizio,
         a.mtdm_reimputazione_anno,
         d.data_creazione, -- 30.08.2018 Sofia jira-6292
         CASE
           WHEN dmtt.movgest_ts_tipo_code::text = 'S' ::text THEN (SELECT count(a1.*) AS count
                                                                   FROM siac_t_movgest_ts_det_mod a1
                                                                   JOIN siac_t_movgest_ts c1 ON c1.movgest_ts_id = a1.movgest_ts_id
                                                                   JOIN siac_t_movgest b1 ON b1.movgest_id = c1.movgest_id
                                                                   JOIN siac_d_movgest_tipo tt1 ON tt1.movgest_tipo_id = b1.movgest_tipo_id
                                                                   JOIN siac_r_modifica_stato e1 ON e1.mod_stato_r_id = a1.mod_stato_r_id
                                                                   JOIN siac_t_modifica d1 ON d1.mod_id = e1.mod_id
                                                                   JOIN siac_d_modifica_stato f1 ON f1.mod_stato_id = e1.mod_stato_id
                                                                   LEFT JOIN siac_d_modifica_tipo g1 ON g1.mod_tipo_id = d1.mod_tipo_id
                                                                                                     AND g1.data_cancellazione IS NULL
                                                                                                     AND g1.mod_tipo_code::text = g.mod_tipo_code::text
                                                                   JOIN siac_d_movgest_ts_tipo dmtt1 ON dmtt1.movgest_ts_tipo_id = c1.movgest_ts_tipo_id
                                                                   JOIN siac_t_bil i1 ON i1.bil_id = b1.bil_id
                                                                   JOIN siac_t_periodo l1 ON l1.periodo_id = i1.periodo_id
                                                                   WHERE tt1.movgest_tipo_code::text = 'A'::text
																   AND   dmtt1.movgest_ts_tipo_code::text = 'T'::text
																   AND   b1.movgest_anno = b.movgest_anno
																   AND   b1.movgest_numero = b.movgest_numero
																   AND d1.mod_num = d.mod_num
																   AND f1.mod_stato_code::text = f.mod_stato_code::text
																   AND a1.ente_proprietario_id = a.ente_proprietario_id
																   AND l1.anno::text = l.anno::text
																   AND a1.data_cancellazione IS NULL
																   AND b1.data_cancellazione IS NULL
																   AND c1.data_cancellazione IS NULL
																   AND tt1.data_cancellazione IS NULL
																   AND d1.data_cancellazione IS NULL
																   AND e1.data_cancellazione IS NULL
																   AND f1.data_cancellazione IS NULL
																   AND dmtt1.data_cancellazione IS NULL
																   AND i1.data_cancellazione IS NULL
																   AND l1.data_cancellazione IS NULL
         )
           ELSE 0::bigint
         END AS verifica_record_doppi
  FROM siac_t_movgest_ts_det_mod a
       JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
       JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
       JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
       JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
       JOIN siac_t_modifica d ON d.mod_id = e.mod_id
       JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
       LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND
         g.data_cancellazione IS NULL
       JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
       JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id =
         h.attoamm_tipo_id
       JOIN siac_t_bil i ON i.bil_id = b.bil_id
       JOIN siac_t_periodo l ON l.periodo_id = i.periodo_id
       JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id =
         c.movgest_ts_tipo_id
  WHERE tt.movgest_tipo_code::text = 'A' ::text AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        tt.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        e.data_cancellazione IS NULL AND
        f.data_cancellazione IS NULL AND
        h.data_cancellazione IS NULL AND
        daat.data_cancellazione IS NULL AND
        i.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        dmtt.data_cancellazione IS NULL), aa AS (
         SELECT i.attoamm_id,
                l.classif_id,
                l.classif_code,
                l.classif_desc,
                m.classif_tipo_code
         FROM siac_r_atto_amm_class i,
              siac_t_class l,
              siac_d_class_tipo m,
              siac_r_class_fam_tree n,
              siac_t_class_fam_tree o,
              siac_d_class_fam p
         WHERE i.classif_id = l.classif_id AND
               m.classif_tipo_id = l.classif_tipo_id AND
               n.classif_id = l.classif_id AND
               n.classif_fam_tree_id = o.classif_fam_tree_id AND
               o.classif_fam_id = p.classif_fam_id AND
               p.classif_fam_code::text = '00005' ::text AND
               i.data_cancellazione IS NULL AND
               l.data_cancellazione IS NULL AND
               m.data_cancellazione IS NULL AND
               n.data_cancellazione IS NULL AND
               o.data_cancellazione IS NULL AND
               p.data_cancellazione IS NULL)
 SELECT zz.anno AS bil_anno,
        zz.movgest_anno AS anno_accertamento,
        zz.movgest_numero AS num_accertamento,
        zz.movgest_ts_code AS cod_movgest_ts,
        zz.movgest_ts_desc AS desc_movgest_ts,
        zz.movgest_ts_tipo_code AS tipo_movgest_ts,
        zz.movgest_ts_det_importo AS importo_modifica,
        zz.mod_num AS numero_modifica,
        zz.mod_desc AS desc_modifica,
        zz.mod_stato_code AS stato_modifica,
        zz.mod_tipo_code AS cod_tipo_modifica,
        zz.mod_tipo_desc AS desc_tipo_modifica,
        zz.attoamm_anno AS anno_atto_amministrativo,
        zz.attoamm_numero AS num_atto_amministrativo,
        zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
        aa.classif_code AS cod_sac,
        aa.classif_desc AS desc_sac,
        aa.classif_tipo_code AS tipo_sac,
        zz.ente_proprietario_id,
        zz.mod_stato_desc AS desc_stato_modifica,
        zz.mtdm_reimputazione_flag AS flag_reimputazione,
        zz.mtdm_reimputazione_anno AS anno_reimputazione,
        zz.validita_inizio,
        zz.data_creazione -- 30.08.2018 Sofia jira-6292
 FROM zz
      LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id
 WHERE zz.verifica_record_doppi = 0;

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accert_sogg (
    ente_proprietario_id,
    bil_anno_sogg,
    anno_accertamento_sogg,
    num_accertamento_sogg,
    cod_movgest_ts_sogg,
    desc_movgest_ts_sogg,
    tipo_movgest_ts_sogg,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggeto_old,
    desc_soggetto_old,
    cf_old,
    cf_estero_old,
    partita_iva_old,
    cod_soggeto_new,
    desc_soggetto_new,
    cf_new,
    cf_estero_new,
    partita_iva_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
   )
AS
 WITH a AS (
SELECT tm.ente_proprietario_id, tm.mod_num, tm.mod_desc,
            dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc, tp.anno,
            stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
            tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
            ts1.soggetto_code AS cod_soggeto_old,
            ts1.soggetto_desc AS desc_soggetto_old,
            ts1.codice_fiscale AS cf_old,
            ts1.codice_fiscale_estero AS cf_estero_old,
            ts1.partita_iva AS partita_iva_old,
            ts2.soggetto_code AS cod_soggeto_new,
            ts2.soggetto_desc AS desc_soggetto_new,
            ts2.codice_fiscale AS cf_new,
            ts2.codice_fiscale_estero AS cf_estero_new,
            ts2.partita_iva AS partita_iva_new, tam.attoamm_anno,
            tam.attoamm_numero, daat.attoamm_tipo_code, tam.attoamm_id,
            dms.mod_stato_desc,
            tm.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_r_movgest_ts_sog_mod rmtsm
      JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = rmtsm.mod_stato_r_id
   JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
   JOIN siac_d_modifica_stato dms ON rms.mod_stato_id = dms.mod_stato_id
   LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND
       dmt.data_cancellazione IS NULL
   JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
   JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
   JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rmtsm.movgest_ts_id
   JOIN siac_t_soggetto ts1 ON ts1.soggetto_id = rmtsm.soggetto_id_old
   JOIN siac_t_soggetto ts2 ON ts2.soggetto_id = rmtsm.soggetto_id_new
   JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
   JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
   JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
   JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
   JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'A'::text AND rmtsm.data_cancellazione IS
    NULL AND rms.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dms.data_cancellazione IS NULL AND tam.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL AND ts1.data_cancellazione IS NULL AND ts2.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL AND stm.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tp.data_cancellazione IS NULL AND tb.data_cancellazione IS NULL
        ), b AS (
    SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
            tc.classif_desc, dct.classif_tipo_code
    FROM siac_r_atto_amm_class raac, siac_t_class tc,
            siac_d_class_tipo dct, siac_r_class_fam_tree cft,
            siac_t_class_fam_tree tcft, siac_d_class_fam dcf
    WHERE raac.classif_id = tc.classif_id AND dct.classif_tipo_id =
        tc.classif_tipo_id AND cft.classif_id = tc.classif_id AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id AND tcft.classif_fam_id = dcf.classif_fam_id AND dcf.classif_fam_code::text = '00005'::text AND raac.data_cancellazione IS NULL AND tc.data_cancellazione IS NULL AND dct.data_cancellazione IS NULL AND cft.data_cancellazione IS NULL AND tcft.data_cancellazione IS NULL AND dcf.data_cancellazione IS NULL
    )
    SELECT a.ente_proprietario_id, a.anno AS bil_anno_sogg,
    a.movgest_anno AS anno_accertamento_sogg,
    a.movgest_numero AS num_accertamento_sogg,
    a.movgest_ts_code AS cod_movgest_ts_sogg,
    a.movgest_ts_desc AS desc_movgest_ts_sogg,
    a.movgest_ts_tipo_code AS tipo_movgest_ts_sogg,
    a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
    a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
    a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggeto_old,
    a.desc_soggetto_old, a.cf_old, a.cf_estero_old, a.partita_iva_old,
    a.cod_soggeto_new, a.desc_soggetto_new, a.cf_new, a.cf_estero_new,
    a.partita_iva_new, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS num_atto_amministrativo,
    a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
    b.classif_tipo_code AS tipo_sac,
    a.mod_stato_desc AS desc_stato_modifica,
    a.data_creazione -- 30.08.2018 Sofia jira-6292
    FROM a
   LEFT JOIN b ON a.attoamm_id = b.attoamm_id;

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accert_classe (
    ente_proprietario_id,
    bil_anno_classe,
    anno_accertamento_classe,
    num_accertamento_classe,
    cod_movgest_ts_classe,
    desc_movgest_ts_classe,
    tipo_movgest_ts_classe,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    cod_soggetto_classe_old,
    desc_soggetto_classe_old,
    cod_tipo_sog_classe_old,
    desc_tipo_sog_classe_old,
    cod_soggetto_classe_new,
    desc_soggetto_classe_new,
    cod_tipo_sog_classe_new,
    desc_tipo_sog_classe_new,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    desc_stato_modifica,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
 WITH a AS (
SELECT tm.ente_proprietario_id, tm.mod_num, tm.mod_desc,
            dms.mod_stato_code, dmt.mod_tipo_code, dmt.mod_tipo_desc,
            tam.attoamm_anno, tam.attoamm_numero, daat.attoamm_tipo_code,
            tp.anno, stm.movgest_anno, stm.movgest_numero, tmt.movgest_ts_code,
            tmt.movgest_ts_desc, dmtt.movgest_ts_tipo_code,
            dsc1.soggetto_classe_code AS cod_soggetto_classe_old,
            dsc1.soggetto_classe_desc AS desc_soggetto_classe_old,
            dsct1.soggetto_classe_tipo_code AS cod_tipo_sog_classe_old,
            dsct1.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_old,
            dsc2.soggetto_classe_code AS cod_soggetto_classe_new,
            dsc2.soggetto_classe_desc AS desc_soggetto_classe_new,
            dsct2.soggetto_classe_tipo_code AS cod_tipo_sog_classe_new,
            dsct2.soggetto_classe_tipo_desc AS desc_tipo_sog_classe_new,
            tam.attoamm_id,
            dms.mod_stato_desc,
            tm.data_creazione -- 30.08.2018 Sofia jira-6292
FROM siac_r_movgest_ts_sogclasse_mod mtsm
      JOIN siac_r_modifica_stato rms ON rms.mod_stato_r_id = mtsm.mod_stato_r_id
   JOIN siac_t_modifica tm ON tm.mod_id = rms.mod_id
   JOIN siac_d_modifica_stato dms ON dms.mod_stato_id = rms.mod_stato_id
   LEFT JOIN siac_d_modifica_tipo dmt ON dmt.mod_tipo_id = tm.mod_tipo_id AND
       dmt.data_cancellazione IS NULL
   JOIN siac_t_atto_amm tam ON tam.attoamm_id = tm.attoamm_id
   JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = tam.attoamm_tipo_id
   JOIN siac_t_movgest_ts tmt ON tmt.movgest_ts_id = mtsm.movgest_ts_id
   JOIN siac_d_soggetto_classe dsc1 ON dsc1.soggetto_classe_id =
       mtsm.soggetto_classe_id_old
   JOIN siac_d_soggetto_classe dsc2 ON dsc2.soggetto_classe_id =
       mtsm.soggetto_classe_id_new
   JOIN siac_d_soggetto_classe_tipo dsct1 ON dsct1.soggetto_classe_tipo_id =
       dsc1.soggetto_classe_tipo_id
   JOIN siac_d_soggetto_classe_tipo dsct2 ON dsct2.soggetto_classe_tipo_id =
       dsc2.soggetto_classe_tipo_id
   JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
   JOIN siac_t_movgest stm ON stm.movgest_id = tmt.movgest_id
   JOIN siac_d_movgest_tipo sdmt ON sdmt.movgest_tipo_id = stm.movgest_tipo_id
   JOIN siac_t_bil tb ON tb.bil_id = stm.bil_id
   JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
WHERE sdmt.movgest_tipo_code::text = 'A'::text AND mtsm.data_cancellazione IS
    NULL AND rms.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dms.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tam.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL AND dsc1.data_cancellazione IS NULL AND dsc2.data_cancellazione IS NULL AND dsct1.data_cancellazione IS NULL AND dsct2.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL AND tm.data_cancellazione IS NULL AND dmt.data_cancellazione IS NULL AND tb.data_cancellazione IS NULL AND tp.data_cancellazione IS NULL
        ), b AS (
    SELECT raac.attoamm_id, tc.classif_id, tc.classif_code,
            tc.classif_desc, dct.classif_tipo_code
    FROM siac_r_atto_amm_class raac, siac_t_class tc,
            siac_d_class_tipo dct, siac_r_class_fam_tree cft,
            siac_t_class_fam_tree tcft, siac_d_class_fam dcf
    WHERE raac.classif_id = tc.classif_id AND dct.classif_tipo_id =
        tc.classif_tipo_id AND cft.classif_id = tc.classif_id AND cft.classif_fam_tree_id = tcft.classif_fam_tree_id AND tcft.classif_fam_id = dcf.classif_fam_id AND dcf.classif_fam_code::text = '00005'::text AND raac.data_cancellazione IS NULL AND tc.data_cancellazione IS NULL AND dct.data_cancellazione IS NULL AND cft.data_cancellazione IS NULL AND tcft.data_cancellazione IS NULL AND dcf.data_cancellazione IS NULL
    )
    SELECT a.ente_proprietario_id, a.anno AS bil_anno_classe,
    a.movgest_anno AS anno_accertamento_classe,
    a.movgest_numero AS num_accertamento_classe,
    a.movgest_ts_code AS cod_movgest_ts_classe,
    a.movgest_ts_desc AS desc_movgest_ts_classe,
    a.movgest_ts_tipo_code AS tipo_movgest_ts_classe,
    a.mod_num AS numero_modifica, a.mod_desc AS desc_modifica,
    a.mod_stato_code AS stato_modifica, a.mod_tipo_code AS cod_tipo_modifica,
    a.mod_tipo_desc AS desc_tipo_modifica, a.cod_soggetto_classe_old,
    a.desc_soggetto_classe_old, a.cod_tipo_sog_classe_old,
    a.desc_tipo_sog_classe_old, a.cod_soggetto_classe_new,
    a.desc_soggetto_classe_new, a.cod_tipo_sog_classe_new,
    a.desc_tipo_sog_classe_new, a.attoamm_anno AS anno_atto_amministrativo,
    a.attoamm_numero AS num_atto_amministrativo,
    a.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    b.classif_code AS cod_sac, b.classif_desc AS desc_sac,
    b.classif_tipo_code AS tipo_sac,
    a.mod_stato_desc AS desc_stato_modifica,
    a.data_creazione -- 30.08.2018 Sofia jira-6292
    FROM a
   LEFT JOIN b ON a.attoamm_id = b.attoamm_id;   
   
-- SIAC-6292 - Sofia - FINE

-- SIAC-6313 - Sofia - INIZIO

drop table if exists siac_r_bil_elem_fpv;
drop table if exists siac_dwh_capitolo_fpv;
drop function if exists fnc_siac_dwh_capitolo_fpv
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE TABLE siac_r_bil_elem_fpv
(
  elem_fpv_r_id SERIAL,
  elem_id INTEGER,
  elem_fpv_id INTEGER NOT NULL,
  elem_fpv_importo NUMERIC,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_bil_elem_fpv PRIMARY KEY(elem_fpv_r_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_bil_elem_fpv FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv FOREIGN KEY (elem_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv_1 FOREIGN KEY (elem_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv_2 FOREIGN KEY (elem_fpv_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index 
(
  'siac_r_bil_elem_fpv'::text,
  'idx_siac_r_bil_elem_fpv'::text,
  'elem_id, elem_fpv_id, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index 
(
  'siac_r_bil_elem_fpv'::text,
  'siac_r_bil_elem_fpv_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  null,
  false
);

select fnc_dba_create_index 
(
  'siac_r_bil_elem_fpv'::text,
  'siac_r_bil_elem_fpv_fk_bil_elem_id_idx'::text,
  'elem_id'::text,
  null,
  false
);

select fnc_dba_create_index 
(
  'siac_r_bil_elem_fpv'::text,
  'siac_r_bil_elem_fpv_fk_bil_elem_fpv_id_idx'::text,
  'elem_fpv_id'::text,
  null,
  false
);

CREATE TABLE siac_dwh_capitolo_fpv
(
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  bil_anno VARCHAR(4),
  cod_capitolo VARCHAR(200),
  cod_articolo VARCHAR(200),
  cod_ueb VARCHAR(200),
  desc_capitolo VARCHAR,
  desc_articolo VARCHAR,
  cod_tipo_capitolo VARCHAR(200),
  desc_tipo_capitolo VARCHAR(500),
  cod_capitolo_fpv VARCHAR(200),
  cod_articolo_fpv VARCHAR(200),
  cod_ueb_fpv VARCHAR(200),
  desc_capitolo_fpv VARCHAR,
  desc_articolo_fpv VARCHAR,
  cod_tipo_capitolo_fpv VARCHAR(200),
  desc_tipo_capitolo_fpv VARCHAR(500),
  cod_tipo_fpv varchar(200),
  desc_tipo_fpv varchar(200),
  importo_fpv numeric
)
WITH (oids = false);


CREATE OR REPLACE FUNCTION fnc_siac_dwh_capitolo_fpv
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE



v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_capitolo_fpv',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_fpv
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

insert into siac_dwh_capitolo_fpv
(
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  cod_tipo_capitolo,
  desc_tipo_capitolo,
  cod_capitolo_fpv,
  cod_articolo_fpv,
  cod_ueb_fpv,
  desc_capitolo_fpv,
  desc_articolo_fpv,
  cod_tipo_capitolo_fpv,
  desc_tipo_capitolo_fpv,
  cod_tipo_fpv,
  desc_tipo_fpv,
  importo_fpv
)
select
  query.ente_proprietario_id,
  query.ente_denominazione,
  query.bil_anno,
  query.cod_capitolo,
  query.cod_articolo,
  query.cod_ueb,
  query.desc_capitolo,
  query.desc_articolo,
  query.cod_tipo_capitolo,
  query.desc_tipo_capitolo,
  query.cod_capitolo_fpv,
  query.cod_articolo_fpv,
  query.cod_ueb_fpv,
  query.desc_capitolo_fpv,
  query.desc_articolo_fpv,
  query.cod_tipo_capitolo_fpv,
  query.desc_tipo_capitolo_fpv,
  query.cod_tipo_fpv,
  query.desc_tipo_fpv,
  query.importo_fpv
from
(
with
capitolo as
(
select tipo.elem_tipo_code,
       tipo.elem_tipo_desc,
       e.elem_id,
       e.elem_code,
       e.elem_code2,
       e.elem_code3,
       e.elem_desc,
       e.elem_desc2
from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato,
     siac_t_bil bil, siac_t_periodo per
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio::integer
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code!='AN'
and   rs.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
and   e.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',e.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(e.validita_fine,date_trunc('DAY',now())))
),
capitolo_fpv as
(
select tipo.elem_tipo_code,
       tipo.elem_tipo_desc,
       e.elem_id,
       e.elem_code,
       e.elem_code2,
       e.elem_code3,
       e.elem_desc,
       e.elem_desc2,
       cat.elem_cat_code,
       cat.elem_cat_desc
from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs, siac_d_bil_elem_stato stato,
     siac_t_bil bil, siac_t_periodo per,
     siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   e.elem_tipo_id=tipo.elem_tipo_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio::integer
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   stato.elem_stato_code!='AN'
and   rcat.elem_id=e.elem_id
and   cat.elem_cat_id=rcat.elem_cat_id
and   cat.elem_cat_code like 'FPV%'
and   rs.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
and   e.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',e.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(e.validita_fine,date_trunc('DAY',now())))
and   rcat.data_cancellazione is null
and   date_trunc('DAY',now())>=date_trunc('DAY',rcat.validita_inizio)
and   date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rcat.validita_fine,date_trunc('DAY',now())))
)
select
  ente.ente_proprietario_id,
  ente.ente_denominazione,
  p_anno_bilancio     bil_anno ,
  capitolo.elem_code  cod_capitolo,
  capitolo.elem_code2 cod_articolo,
  capitolo.elem_code3 cod_ueb,
  capitolo.elem_desc  desc_capitolo,
  capitolo.elem_desc2 desc_articolo,
  capitolo.elem_tipo_code cod_tipo_capitolo,
  capitolo.elem_tipo_desc desc_tipo_capitolo,
  capitolo_fpv.elem_code cod_capitolo_fpv,
  capitolo_fpv.elem_code2 cod_articolo_fpv,
  capitolo_fpv.elem_code3 cod_ueb_fpv,
  capitolo_fpv.elem_desc  desc_capitolo_fpv,
  capitolo_fpv.elem_desc2 desc_articolo_fpv,
  capitolo_fpv.elem_tipo_code cod_tipo_capitolo_fpv,
  capitolo_fpv.elem_tipo_desc desc_tipo_capitolo_fpv,
  capitolo_fpv.elem_cat_code  cod_tipo_fpv,
  capitolo_fpv.elem_cat_desc  desc_tipo_fpv,
  r.elem_fpv_importo               importo_fpv
from capitolo, capitolo_fpv, siac_r_bil_elem_fpv r,siac_t_ente_proprietario ente
where r.ente_proprietario_id=p_ente_proprietario_id
and   capitolo.elem_id=r.elem_id
and   capitolo_fpv.elem_id=r.elem_fpv_id
and   ente.ente_proprietario_id=p_ente_proprietario_id
and   r.data_cancellazione is null
and   r.validita_fine is null
) query;



esito:= 'Fine funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) - '||clock_timestamp();

RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico legame capitolo di spesa - FPV (FNC_SIAC_DWH_CAPITOLO_FPV) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-6313 - Sofia - FINE

-- SIAC-6266 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR211_Assestamento_bilancio_di_gestione_entrate"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_tipo_var varchar);

DROP FUNCTION if exists siac."BILR213_Assestamento_bilancio_di_gestione_spese"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_tipo_var varchar);

CREATE OR REPLACE FUNCTION siac."BILR211_Assestamento_bilancio_di_gestione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_tipo_var varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  tipo_capitolo varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  variaz_stanz_anno numeric,
  variaz_stanz_anno1 numeric,
  variaz_stanz_anno2 numeric,
  variaz_residui_anno numeric,
  variaz_cassa_anno numeric,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
x_array VARCHAR [];
contaParVarPeg integer;
contaParVarBil integer;
sql_query_var1 varchar;
sql_query_var2 varchar;
cercaVariaz boolean;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';

titoloe_CODE='';
titoloe_DESC='';

tipologia_code='';
tipologia_desc='';

categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
--previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;
sql_query_var1:='';
sql_query_var2:='';
cercaVariaz:=false;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione''';
    return next;
    return;        
end if;
sql_query:='';

IF (p_ele_variazioni IS  NULL OR p_ele_variazioni = '') AND
	contaParVarBil = 0 AND
    (p_tipo_var IS NULL OR p_tipo_var = '') THEN
    display_error='OCCORRE SPECIFICARE ALMENO 1 PARAMETRO RELATIVO ALLE VARIAZIONI';
    return next;
    return;  
    
end if;
select fnc_siac_random_user()
into	user_table;


--preparo la parte della query relativa alle variazioni.
	
	sql_query_var1='    
    select	dettaglio_variazione.elem_id,
    		anno_importo.anno,
            sum(dettaglio_variazione.elem_det_importo) importo_var            	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';                
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    sql_query_var1=sql_query_var1||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id '; 
    
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id									= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;

--sono escluse le variazioni ANNULLATE e DEFINITIVE.            
    sql_query_var1=sql_query_var1||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query_var1=sql_query_var1 || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code not in (''D'',''A'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''';    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query_var2= ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    if (p_tipo_var IS NOT NULL AND p_tipo_var <> '') THEN
    	sql_query_var2=sql_query_var2||' 
        and tipologia_variazione.variazione_tipo_code = '''||p_tipo_var||'''';
    end if;
    sql_query_var2=sql_query_var2 || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
     
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2 || ' and 	atto.data_cancellazione		is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione			is null ';
    end if;
    sql_query_var2=sql_query_var2 || ' group by 	dettaglio_variazione.elem_id,               
                anno_importo.anno';	     
         
--raise notice 'Query VAR: % ',  sql_query_var1||sql_query_var2;      

-- preparo la query totale.
sql_query:='with strutt_amm as (
	select * from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||','''||p_anno||''','''')),
ele_cap as (select classific.classif_id,
    anno_eserc.anno anno_bilancio,
    cap.*, cat_del_capitolo.elem_cat_code
   from   siac_t_bil_elem cap
   			LEFT JOIN (select rc.elem_id, rc.classif_id
				from   siac_r_bil_elem_class rc,
  					siac_t_class cl,
        			siac_d_class_tipo ct
				where  cl.classif_id = rc.classif_id
    				AND ct.classif_tipo_id	= cl.classif_tipo_id
    				AND rc.ente_proprietario_id = '||p_ente_prop_id||'
    				AND ct.classif_tipo_code			=	''CATEGORIA''
					AND rc.data_cancellazione IS NULL
    				AND cl.data_cancellazione IS NULL
    				AND  ct.data_cancellazione IS NULL
    				AND now() between rc.validita_inizio and coalesce (rc.validita_fine, now()) 
    				AND now() between cl.validita_inizio and coalesce (cl.validita_fine, now()) 
    				AND	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())) classific
            	ON classific.elem_id= cap.elem_id,                    
          siac_t_bil bilancio,
          siac_t_periodo anno_eserc,
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
  where bilancio.periodo_id				=	anno_eserc.periodo_id 
  and cap.bil_id						=	bilancio.bil_id 
  and cap.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
  and	cap.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	cap.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  and cap.ente_proprietario_id 			=	'||p_ente_prop_id||'
  and anno_eserc.anno					= 	'''||p_anno||'''
  and tipo_elemento.elem_tipo_code 	= 	''CAP-EG''
  and	stato_capitolo.elem_stato_code	=	''VA''
  and cap.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  and	now() between cap.validita_inizio and coalesce (cap.validita_fine, now())
  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
  and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
  and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
  and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
  and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
  and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
  and	now() between r_cat_capitolo.validita_inizio 
  and coalesce (r_cat_capitolo.validita_fine, now())),
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), 
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||'  
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp1||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp2||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpresidui||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpCassa||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), ';
        
/* inserisco la parte di query relativa alle variazioni */
	  sql_query:= sql_query||'
      imp_variaz_comp_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'), 
      imp_variaz_comp_anno1 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp1||''''||sql_query_var2||'),
      imp_variaz_comp_anno2 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp2||''''||sql_query_var2||'),
	  imp_variaz_residui_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STR'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'),
      imp_variaz_cassa_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''SCA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||')
      ';
sql_query:= sql_query||'                        
select '''||p_anno||'''::varchar bil_anno,
	strutt_amm.titolo_code::varchar titoloe_code,
    strutt_amm.titolo_desc::varchar titoloe_desc,
    left(strutt_amm.tipologia_code,5)::varchar tipologia_code,
    strutt_amm.tipologia_desc::varchar tipologia_desc,
    strutt_amm.categoria_code::varchar categoria_code,
    strutt_amm.categoria_desc::varchar categoria_desc,
    ele_cap.elem_cat_code::varchar tipo_capitolo,
    ele_cap.elem_code::varchar bil_ele_code,
    ele_cap.elem_desc::varchar bil_ele_desc,
    ele_cap.elem_code2::varchar bil_ele_code2,
    ele_cap.elem_desc2::varchar bil_ele_desc2,
    ele_cap.elem_id::integer  bil_ele_id,
    ele_cap.elem_id_padre::integer  bil_ele_id_padre,
    COALESCE(imp_cassa_anno.importo,0)::numeric stanziamento_prev_cassa_anno,
    COALESCE(imp_comp_anno.importo,0)::numeric stanziamento_prev_anno,
    COALESCE(imp_comp_anno1.importo,0)::numeric stanziamento_prev_anno1,
    COALESCE(imp_comp_anno2.importo,0)::numeric stanziamento_prev_anno2,
    COALESCE(imp_residui_anno.importo,0)::numeric residui_presunti,
    COALESCE(imp_variaz_comp_anno.importo_var,0)::numeric variaz_stanz_anno,
    COALESCE(imp_variaz_comp_anno1.importo_var,0)::numeric variaz_stanz_anno1,
    COALESCE(imp_variaz_comp_anno2.importo_var,0)::numeric variaz_stanz_anno2,
    COALESCE(imp_variaz_residui_anno.importo_var,0)::numeric variaz_residui_anno,
    COALESCE(imp_variaz_cassa_anno.importo_var,0)::numeric variaz_cassa_anno,
    ''''::varchar display_error
from strutt_amm
	FULL join ele_cap 
    	on strutt_amm.categoria_id = ele_cap.classif_id
    left join imp_comp_anno
    	on imp_comp_anno.elem_id = ele_cap.elem_id
    left join imp_comp_anno1
    	on imp_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_comp_anno2
    	on imp_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_residui_anno
    	on imp_residui_anno.elem_id = ele_cap.elem_id
    left join imp_cassa_anno
    	on imp_cassa_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno
    	on imp_variaz_comp_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno1
    	on imp_variaz_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno2
    	on imp_variaz_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_variaz_residui_anno
    	on imp_variaz_residui_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_cassa_anno
    	on imp_variaz_cassa_anno.elem_id = ele_cap.elem_id        
where ele_cap.elem_code is not null';

raise notice 'Query: % ', sql_query;
return query execute sql_query;     
    

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR213_Assestamento_bilancio_di_gestione_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_tipo_var varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titolo_code varchar,
  titolo_desc varchar,
  macroaggr_code varchar,
  macroaggr_desc varchar,
  tipo_capitolo varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  variaz_stanz_anno numeric,
  variaz_stanz_anno1 numeric,
  variaz_stanz_anno2 numeric,
  variaz_residui_anno numeric,
  variaz_cassa_anno numeric,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
x_array VARCHAR [];
contaParVarPeg integer;
contaParVarBil integer;
sql_query_var1 varchar;
sql_query_var2 varchar;
cercaVariaz boolean;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-UG'; -- tipo capitolo USCITE GESIONE

bil_anno='';

missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titolo_code='';
titolo_desc='';

macroaggr_code='';
macroaggr_desc='';

bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
--previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;
sql_query_var1:='';
sql_query_var2:='';
cercaVariaz:=false;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione''';
    return next;
    return;        
end if;
sql_query:='';

IF (p_ele_variazioni IS  NULL OR p_ele_variazioni = '') AND
	contaParVarBil = 0 AND
    (p_tipo_var IS NULL OR p_tipo_var = '') THEN
    display_error='OCCORRE SPECIFICARE ALMENO 1 PARAMETRO RELATIVO ALLE VARIAZIONI';
    return next;
    return;  
    
end if;
select fnc_siac_random_user()
into	user_table;


--preparo la parte della query relativa alle variazioni.
	
	sql_query_var1='    
    select	dettaglio_variazione.elem_id,
    		anno_importo.anno,
            sum(dettaglio_variazione.elem_det_importo) importo_var            	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';                
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    sql_query_var1=sql_query_var1||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id '; 
    
    if contaParVarBil = 3 then 
    	sql_query_var1=sql_query_var1||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id									= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;

--sono escluse le variazioni ANNULLATE e DEFINITIVE.            
    sql_query_var1=sql_query_var1||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query_var1=sql_query_var1 || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code not in (''D'',''A'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''';    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query_var2= ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    if (p_tipo_var IS NOT NULL AND p_tipo_var <> '') THEN
    	sql_query_var2=sql_query_var2||' 
        and tipologia_variazione.variazione_tipo_code = '''||p_tipo_var||'''';
    end if;
    sql_query_var2=sql_query_var2 || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
     
    if contaParVarBil = 3 then 
    	sql_query_var2=sql_query_var2 || ' and 	atto.data_cancellazione		is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione			is null ';
    end if;
    sql_query_var2=sql_query_var2 || ' group by 	dettaglio_variazione.elem_id,               
                anno_importo.anno';	     
         
--raise notice 'Query VAR: % ',  sql_query_var1||sql_query_var2;      

-- preparo la query totale.
sql_query:='with strutt_amm as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||','''||p_anno||''','''')),
ele_cap as ( select classific.programma_id,
    	classific.macroaggregato_id,
   		anno_eserc.anno anno_bilancio,
    	cap.*, 
        cat_del_capitolo.elem_cat_code
   from   siac_t_bil_elem cap
   			LEFT JOIN (select r_capitolo_programma.elem_id, 
            		r_capitolo_programma.classif_id programma_id,
                	r_capitolo_macroaggr.classif_id macroaggregato_id
				from	siac_r_bil_elem_class r_capitolo_programma,
     					siac_r_bil_elem_class r_capitolo_macroaggr, 
                    	siac_d_class_tipo programma_tipo,
     					siac_t_class programma,
     					siac_d_class_tipo macroaggr_tipo,
     					siac_t_class macroaggr
				where   programma.classif_id=r_capitolo_programma.classif_id
    				AND programma.classif_tipo_id=programma_tipo.classif_tipo_id 
                    AND macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
    				AND macroaggr.classif_id=r_capitolo_macroaggr.classif_id
                    AND r_capitolo_programma.elem_id=r_capitolo_macroaggr.elem_id
    				AND programma.ente_proprietario_id = '||p_ente_prop_id||'
                    AND programma_tipo.classif_tipo_code=''PROGRAMMA'' 		
    				AND macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''	
					AND r_capitolo_programma.data_cancellazione IS NULL
    				AND r_capitolo_macroaggr.data_cancellazione IS NULL
    				AND programma_tipo.data_cancellazione IS NULL
                    AND programma.data_cancellazione IS NULL
                    AND macroaggr_tipo.data_cancellazione IS NULL
                    AND macroaggr.data_cancellazione IS NULL
    				AND now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now()) 
    				AND now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now()) 
    				AND	now() between programma.validita_inizio and coalesce (programma.validita_fine, now())
                    AND	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())) classific
            	ON classific.elem_id= cap.elem_id,                    
          siac_t_bil bilancio,
          siac_t_periodo anno_eserc,
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
  where bilancio.periodo_id				=	anno_eserc.periodo_id 
  and cap.bil_id						=	bilancio.bil_id 
  and cap.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
  and	cap.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	cap.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  and cap.ente_proprietario_id 			=	'||p_ente_prop_id||'
  and anno_eserc.anno					= 	'''||p_anno||'''
  and tipo_elemento.elem_tipo_code 	= 	'''||elemTipoCode||'''
  and	stato_capitolo.elem_stato_code	=	''VA''
  and cap.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  and	now() between cap.validita_inizio and coalesce (cap.validita_fine, now())
  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
  and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
  and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
  and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
  and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
  and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
  and	now() between r_cat_capitolo.validita_inizio 
  and coalesce (r_cat_capitolo.validita_fine, now())),
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), 
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||'  
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp1||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp2||''')	
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpComp||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpresidui||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_importi.ente_proprietario_id = '||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||''' 	
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
		and	stato_capitolo.elem_stato_code		=	''VA''
        and	capitolo_imp_periodo.anno in ('''||annoCapImp||''')
        and	capitolo_imp_tipo.elem_det_tipo_code = '''||TipoImpCassa||'''
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id), ';
        
/* inserisco la parte di query relativa alle variazioni */
	  sql_query:= sql_query||'
      imp_variaz_comp_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'), 
      imp_variaz_comp_anno1 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp1||''''||sql_query_var2||'),
      imp_variaz_comp_anno2 as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STA'')
      and   anno_importo.anno='''||annoCapImp2||''''||sql_query_var2||'),
	  imp_variaz_residui_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''STR'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||'),
      imp_variaz_cassa_anno as('||sql_query_var1||'
      and	tipo_elemento.elem_det_tipo_code in (''SCA'')
      and   anno_importo.anno='''||annoCapImp||''''||sql_query_var2||')
      ';
sql_query:= sql_query||'                        
select '''||p_anno||'''::varchar bil_anno,
	strutt_amm.missione_code::varchar missione_code,
    strutt_amm.missione_desc::varchar missione_desc,
    strutt_amm.programma_code::varchar programma_code,
    strutt_amm.programma_desc::varchar programma_desc,
    strutt_amm.titusc_code::varchar titolo_code,
    strutt_amm.titusc_desc::varchar titolo_desc,
    strutt_amm.macroag_code::varchar macroaggr_code,
    strutt_amm.macroag_desc::varchar macroaggr_desc,    
    ele_cap.elem_cat_code::varchar tipo_capitolo,
    ele_cap.elem_code::varchar bil_ele_code,
    ele_cap.elem_desc::varchar bil_ele_desc,
    ele_cap.elem_code2::varchar bil_ele_code2,
    ele_cap.elem_desc2::varchar bil_ele_desc2,
    ele_cap.elem_id::integer  bil_ele_id,
    ele_cap.elem_id_padre::integer  bil_ele_id_padre,
    COALESCE(imp_cassa_anno.importo,0)::numeric stanziamento_prev_cassa_anno,
    COALESCE(imp_comp_anno.importo,0)::numeric stanziamento_prev_anno,
    COALESCE(imp_comp_anno1.importo,0)::numeric stanziamento_prev_anno1,
    COALESCE(imp_comp_anno2.importo,0)::numeric stanziamento_prev_anno2,
    COALESCE(imp_residui_anno.importo,0)::numeric residui_presunti,
    COALESCE(imp_variaz_comp_anno.importo_var,0)::numeric variaz_stanz_anno,
    COALESCE(imp_variaz_comp_anno1.importo_var,0)::numeric variaz_stanz_anno1,
    COALESCE(imp_variaz_comp_anno2.importo_var,0)::numeric variaz_stanz_anno2,
    COALESCE(imp_variaz_residui_anno.importo_var,0)::numeric variaz_residui_anno,
    COALESCE(imp_variaz_cassa_anno.importo_var,0)::numeric variaz_cassa_anno,
    ''''::varchar display_error             
from strutt_amm
	FULL join ele_cap 
    	on (strutt_amm.programma_id = ele_cap.programma_id
        	and strutt_amm.macroag_id = ele_cap.macroaggregato_id)
    left join imp_comp_anno
    	on imp_comp_anno.elem_id = ele_cap.elem_id
    left join imp_comp_anno1
    	on imp_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_comp_anno2
    	on imp_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_residui_anno
    	on imp_residui_anno.elem_id = ele_cap.elem_id
    left join imp_cassa_anno
    	on imp_cassa_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno
    	on imp_variaz_comp_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno1
    	on imp_variaz_comp_anno1.elem_id = ele_cap.elem_id
    left join imp_variaz_comp_anno2
    	on imp_variaz_comp_anno2.elem_id = ele_cap.elem_id
    left join imp_variaz_residui_anno
    	on imp_variaz_residui_anno.elem_id = ele_cap.elem_id
    left join imp_variaz_cassa_anno
    	on imp_variaz_cassa_anno.elem_id = ele_cap.elem_id        
where ele_cap.elem_code is not null';

raise notice 'Query: % ', sql_query;
return query execute sql_query;     
    

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6266 - Maurizio - FINE

--CESPITI
--DDL INIZIO
-------------------
------- CODIFICHE:
-------------------
---TIPO CALCOLO CATEGORIA CESPITI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_categoria_calcolo_tipo (
	cescat_calcolo_tipo_id SERIAL,
	cescat_calcolo_tipo_code VARCHAR(200) NOT NULL,
	cescat_calcolo_tipo_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_categoria_calcolo_tipo PRIMARY KEY(cescat_calcolo_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_categoria_calcolo_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
SELECT fnc_dba_create_index ('siac_d_cespiti_categoria_calcolo_tipo'::text, 'idx_siac_d_cespiti_categoria_calcolo_tipo_1'::text,
	'cescat_calcolo_tipo_code, validita_inizio, ente_proprietario_id'::text, 'data_cancellazione is null'::text, true);
SELECT fnc_dba_create_index ('siac_d_cespiti_categoria_calcolo_tipo'::text, 'siac_d_cespiti_categoria_calcolo_tipo_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '', false);

--- TIPO BENE
CREATE TABLE IF NOT EXISTS siac_d_cespiti_bene_tipo (
	ces_bene_tipo_id SERIAL,
	ces_bene_tipo_code VARCHAR(200) NOT NULL,
	ces_bene_tipo_desc VARCHAR(500) NOT NULL,
	testo_scrittura_ammortamento VARCHAR(500),
	evento_ammortamento_id INTEGER,        --Evento di ammortamento
	evento_ammortamento_code VARCHAR(200), --Evento di ammortamento
	evento_ammortamento_desc VARCHAR(500), --Evento di ammortamento
	
	causale_ep_ammortamento_id INTEGER,        --causale di ammortamento
	causale_ep_ammortamento_code VARCHAR(200), --causale di ammortamento
	causale_ep_ammortamento_desc VARCHAR(500), --causale di ammortamento
	
	evento_incremento_id INTEGER,        --Evento di incremento valore
	evento_incremento_code VARCHAR(200), --Evento di incremento valore
	evento_incremento_desc VARCHAR(500), --Evento di incremento valore
	
	causale_ep_incremento_id INTEGER,        --causale di incremento valore
	causale_ep_incremento_code VARCHAR(200), --causale di incremento valore
	causale_ep_incremento_desc VARCHAR(500), --causale di incremento valore
	
	evento_decremento_id INTEGER,        --Evento di decremento valore
	evento_decremento_code VARCHAR(200), --Evento di decremento valore
	evento_decremento_desc VARCHAR(500), --Evento di decremento valore
	
	causale_ep_decremento_id INTEGER,        --causale di decremento valore
	causale_ep_decremento_code VARCHAR(200), --causale di decremento valore
	causale_ep_decremento_desc VARCHAR(500), --causale di decremento valore
	
	pdce_conto_ammortamento_id INTEGER,        --conto_ammortamento
	pdce_conto_ammortamento_code VARCHAR(200), --conto_ammortamento
	pdce_conto_ammortamento_desc VARCHAR(500), --conto_ammortamento
	
	pdce_conto_fondo_ammortamento_id INTEGER,        --Conto del fondo di ammortamento
	pdce_conto_fondo_ammortamento_code VARCHAR(200), --Conto del fondo di ammortamento
	pdce_conto_fondo_ammortamento_desc VARCHAR(500), --Conto del fondo di ammortamento
	
	pdce_conto_plusvalenza_id INTEGER,        --Conto plusvalenza da alienazione
	pdce_conto_plusvalenza_code VARCHAR(200), --Conto plusvalenza da alienazione
	pdce_conto_plusvalenza_desc VARCHAR(500), --Conto plusvalenza da alienazione
	
	pdce_conto_minusvalenza_id INTEGER,        --Conto di minusvalenza da alienazione
	pdce_conto_minusvalenza_code VARCHAR(200), --Conto di minusvalenza da alienazione
	pdce_conto_minusvalenza_desc VARCHAR(500), --Conto di minusvalenza da alienazione
	
	pdce_conto_incremento_id INTEGER,        --Conto di incremento valore
	pdce_conto_incremento_code VARCHAR(200), --Conto di incremento valore
	pdce_conto_incremento_desc VARCHAR(500), --Conto di incremento valore
	
	pdce_conto_decremento_id INTEGER,        --Conto di decremento valore
	pdce_conto_decremento_code VARCHAR(200), --Conto di decremento valore
	pdce_conto_decremento_desc VARCHAR(500), --Conto di decremento valore
	
	pdce_conto_alienazione_id INTEGER,        --Conto credito da alienazione
	pdce_conto_alienazione_code VARCHAR(200), --Conto credito da alienazione
	pdce_conto_alienazione_desc VARCHAR(500), --Conto credito da alienazione
	
	pdce_conto_donazione_id INTEGER,        --Conto donazione / rinvenimento
	pdce_conto_donazione_code VARCHAR(200), --Conto donazione / rinvenimento
	pdce_conto_donazione_desc VARCHAR(500), --Conto donazione / rinvenimento
	
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_bene_tipo PRIMARY KEY(ces_bene_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_bene_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_ammortamento_id)
		REFERENCES siac_d_evento (evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_incremento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (evento_decremento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_ammortamento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_incremento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_causale_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (causale_ep_decremento_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_ammortamento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_ammortamento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_fondo_ammortamento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_plusvalenza_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_plusvalenza_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_minusvalenza_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_minusvalenza_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_incremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_incremento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_decremento_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_decremento_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_alienazione_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_alienazione_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_pdce_conto_donazione_siac_d_cespiti_bene_tipo  FOREIGN KEY (pdce_conto_donazione_id)
		REFERENCES siac_t_pdce_conto(pdce_conto_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ( 'siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_ces_bene_tipo_code'::text,'ces_bene_tipo_code,ente_proprietario_id'::text,'data_cancellazione IS NULL'::text, true);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_evento_ammortamento_id_idx'::text,'evento_ammortamento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_causale_ep_ammortamento_id_idx'::text,'causale_ep_ammortamento_id'::text, '',false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text,'siac_d_cespiti_bene_tipo_fk_evento_incremento_id_idx'::text, 'evento_incremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_causale_ep_incremento_id_idx'::text,'causale_ep_incremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_evento_decremento_id_idx'::text,'evento_decremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text,'siac_d_cespiti_bene_tipo_fk_causale_ep_decremento_id_idx'::text, 'causale_ep_decremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_pdce_conto_ammortamento_id_idx'::text, 'pdce_conto_ammortamento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_pdce_conto_fondo_ammortamento_id_idx'::text,'pdce_conto_fondo_ammortamento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_pdce_conto_plusvalenza_id_idx'::text,'pdce_conto_plusvalenza_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_pdce_conto_minusvalenza_id_idx'::text,'pdce_conto_minusvalenza_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text, 'siac_d_cespiti_bene_tipo_fk_pdce_conto_incremento_id_idx'::text,'pdce_conto_incremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text,'siac_d_cespiti_bene_tipo_fk_pdce_conto_decremento_id_idx'::text,'pdce_conto_decremento_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text,'siac_d_cespiti_bene_tipo_fk_pdce_conto_alienazione_id_idx'::text,'pdce_conto_alienazione_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_bene_tipo'::text,'siac_d_cespiti_bene_tipo_fk_pdce_conto_donazione_id_idx'::text,'pdce_conto_donazione_id'::text, '', false);

--- CLASSIFICAZIONE GIURIDICA
CREATE TABLE IF NOT EXISTS siac_d_cespiti_classificazione_giuridica (
	ces_class_giu_id SERIAL,
	ces_class_giu_code VARCHAR(200) NOT NULL,
	ces_class_giu_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_ces_class_giu_id PRIMARY KEY(ces_class_giu_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_classificazione_giuridica FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
SELECT fnc_dba_create_index ('siac_d_cespiti_classificazione_giuridica'::text, 'siac_d_cespiti_classificazione_giuridica_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_classificazione_giuridica'::text, ' siac_d_cespiti_classificazione_giuridica_fk_ces_class_giu_code'::text,'ces_class_giu_code,ente_proprietario_id'::text,'data_cancellazione IS NULL'::text, true);

-- STATO DISMISSIONI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_dismissioni_stato (
	ces_dismissioni_stato_id SERIAL,
	ces_dismissioni_stato_code VARCHAR(200) NOT NULL,
	ces_dismissioni_stato_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_dismissioni_stato PRIMARY KEY(ces_dismissioni_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_dismissioni_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_d_cespiti_dismissioni_stato'::text, 'siac_d_cespiti_dismissioni_stato_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
	
SELECT fnc_dba_create_index ('siac_d_cespiti_dismissioni_stato'::text, 'siac_d_cespiti_dismissioni_stato_fk_ces_var_stato_code'::text,'ces_dismissioni_stato_code,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);

--STATO VARIAZIONI
CREATE TABLE IF NOT EXISTS siac_d_cespiti_variazione_stato (
	ces_var_stato_id SERIAL,
	ces_var_stato_code VARCHAR(200) NOT NULL,
	ces_var_stato_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_cespiti_variazione_stato PRIMARY KEY(ces_var_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_cespiti_variazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_d_cespiti_variazione_stato'::text, 'siac_d_cespiti_variazione_stato_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_d_cespiti_variazione_stato'::text, 'siac_d_cespiti_variazione_stato_fk_ces_var_stato_code'::text,'ces_var_stato_code,ente_proprietario_id'::text,'data_cancellazione IS NULL'::text, true);
	
--STATO ACCETTAZIONE PRIMA NOTA PROVVISORIA
CREATE TABLE IF NOT EXISTS siac_d_pn_prov_accettazione_stato (
	pn_sta_acc_prov_id SERIAL,
	pn_sta_acc_prov_code VARCHAR(200) NOT NULL,
	pn_sta_acc_prov_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_pn_prov_accettazione_stato PRIMARY KEY(pn_sta_acc_prov_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_pn_prov_accettazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_d_pn_prov_accettazione_stato'::text,'siac_d_pn_prov_accettazione_stato_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);

--STATO ACCETTAZIONE PRIMA NOTA DEFINITIVA
CREATE TABLE IF NOT EXISTS siac_d_pn_def_accettazione_stato (
	pn_sta_acc_def_id SERIAL,
	pn_sta_acc_def_code VARCHAR(200) NOT NULL,
	pn_sta_acc_def_desc VARCHAR(500) NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_d_pn_def_accettazione_stato PRIMARY KEY(pn_sta_acc_def_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_pn_prov_accettazione_stato FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_d_pn_def_accettazione_stato'::text,'siac_d_pn_def_accettazione_stato_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '', false);
	
--CESPITI
--- DISMISSIONI
CREATE TABLE IF NOT EXISTS siac_t_cespiti_dismissioni (
	ces_dismissioni_id SERIAL,	
	ces_dismissioni_desc VARCHAR(500) NOT NULL,
	elenco_dismissioni_anno INTEGER NOT NULL,
	elenco_dismissioni_numero INTEGER  NOT NULL,	
	data_cessazione TIMESTAMP NOT NULL,
	ces_dismissioni_stato_id INTEGER NOT NULL,
	dismissioni_desc_stato VARCHAR(500) NOT NULL,
	evento_id INTEGER,
	causale_ep_id INTEGER  NOT NULL,
	attoamm_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	login_creazione VARCHAR(200) NOT NULL,
	login_modifica VARCHAR(200) NOT NULL,
	login_cancellazione VARCHAR(200),
	CONSTRAINT pk_siac_t_cespiti_dismissioni PRIMARY KEY(ces_dismissioni_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_dismissioni FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_atto_amm_siac_t_cespiti_dismissioni FOREIGN KEY (attoamm_id)
		REFERENCES siac_t_atto_amm(attoamm_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_evento_siac_t_cespiti_dismissioni FOREIGN KEY (evento_id)
		REFERENCES siac_d_evento(evento_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_cespiti_dismissioni_stato_siac_t_cespiti_dismissioni FOREIGN KEY (ces_dismissioni_stato_id)
		REFERENCES siac_d_cespiti_dismissioni_stato(ces_dismissioni_stato_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_causale_ep_siac_t_cespiti_dismissioni FOREIGN KEY (causale_ep_id)
		REFERENCES siac_t_causale_ep(causale_ep_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_dismissioni'::text,'siac_t_cespiti_dismissioni_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_t_cespiti_dismissioni'::text, 'siac_t_cespiti_dismissioni_fk_ces_dismissioni_code'::text,'ces_dismissioni_code,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);	
SELECT fnc_dba_create_index ( 'siac_t_cespiti_dismissioni'::text, 'siac_t_cespiti_dismissioni_fk_ces_dismissioni_stato_id_idx'::text,'ces_dismissioni_stato_id'::text, '', false);

CREATE TABLE IF NOT EXISTS siac_t_cespiti_elenco_dismissioni_num (
	elenco_dismissioni_num_id SERIAL,
	elenco_dismissioni_anno INTEGER NOT NULL,
	elenco_dismissioni_numero INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_dismissioni_elenco_num PRIMARY KEY(elenco_dismissioni_num_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_dismissioni_elenco_num FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_elenco_dismissioni_num'::text, 'siac_t_cespiti_elenco_dismissioni_num_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
	
--- CESPITI
CREATE TABLE IF NOT EXISTS siac_t_cespiti (
	ces_id SERIAL,
	ces_code VARCHAR(200) NOT NULL,
	ces_desc VARCHAR(500) NOT NULL,
	soggetto_beni_culturali boolean default false,
	num_inventario VARCHAR(10) NOT NULL,
	num_inventario_prefisso VARCHAR(25) NOT NULL,
	num_inventario_numero INTEGER NOT NULL,
	data_ingresso_inventario TIMESTAMP NOT NULL,
	data_cessazione TIMESTAMP,
	valore_iniziale NUMERIC NOT NULL,
	valore_attuale NUMERIC NOT NULL,
	descrizione_stato VARCHAR(200),
	ubicazione VARCHAR(2000),
	note VARCHAR(2000),
	flg_donazione_rinvenimento boolean default false,
	flg_stato_bene boolean default true,
	ces_dismissioni_id INTEGER,
	ces_class_giu_id INTEGER NOT NULL,
	ces_bene_tipo_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	login_creazione VARCHAR(200) NOT NULL,
	login_modifica VARCHAR(200) NOT NULL,
	login_cancellazione VARCHAR(200),
	CONSTRAINT pk_siac_t_cespiti PRIMARY KEY(ces_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_d_cespiti_bene_tipo FOREIGN KEY (ces_bene_tipo_id)
		REFERENCES siac_d_cespiti_bene_tipo(ces_bene_tipo_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_t_cespiti_dismissioni FOREIGN KEY (ces_dismissioni_id)
		REFERENCES siac_t_cespiti_dismissioni(ces_dismissioni_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_siac_d_cespiti_classificazione_giuridica FOREIGN KEY (ces_class_giu_id)
		REFERENCES siac_d_cespiti_classificazione_giuridica(ces_class_giu_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ( 'siac_t_cespiti'::text, 'siac_t_cespiti_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text,'', false);
SELECT fnc_dba_create_index ( 'siac_t_cespiti'::text, 'siac_t_cespiti_fk_ces_code'::text, 'ces_code,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);
SELECT fnc_dba_create_index ( 'siac_t_cespiti'::text,'siac_t_cespiti_fk_ces_bene_tipo_id_idx'::text, 'ces_bene_tipo_id'::text, '', false);
SELECT fnc_dba_create_index ( 'siac_t_cespiti'::text,'siac_t_cespiti_fk_ces_dismissioni_id_idx'::text, 'ces_dismissioni_id'::text, '', false);
SELECT fnc_dba_create_index ( 'siac_t_cespiti'::text, 'siac_t_cespiti_fk_ces_class_giu_id_idx'::text, 'ces_class_giu_id'::text, '', false);
	
CREATE TABLE IF NOT EXISTS siac_t_cespiti_num_inventario (
	num_inventario_id SERIAL,
	num_inventario_prefisso VARCHAR(25) NOT NULL,
	num_inventario_numero INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_num_inventario PRIMARY KEY(num_inventario_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_num_inventario FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_num_inventario'::text, 'siac_t_cespiti_num_inventario_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '', false);
--VARIAZIONI

CREATE TABLE IF NOT EXISTS siac_t_cespiti_variazione (
	ces_var_id SERIAL,
	ces_var_desc VARCHAR(500) NOT NULL,
	ces_var_anno VARCHAR(4) NOT NULL,
	ces_var_data TIMESTAMP NOT NULL,
	ces_var_importo NUMERIC not null,
	flg_tipo_variazione_incr boolean not null,
	ces_var_stato_id INTEGER NOT NULL,
	ces_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_variazione PRIMARY KEY(ces_var_id),
	CONSTRAINT siac_t_cespiti_variazione_siac_t_cespiti FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_variazione_siac_d_cespiti_variazione_stato FOREIGN KEY (ces_var_stato_id)
		REFERENCES siac_d_cespiti_variazione_stato(ces_var_stato_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_variazione_siac_t_ente_proprietario FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_variazione'::text, 'siac_t_cespiti_variazione_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_t_cespiti_variazione'::text, 'siac_t_cespiti_variazione_fk_ces_var_stato_id_idx'::text,'ces_var_stato_id'::text, '', false);

--AMMORTAMENTI 
CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento (
	ces_amm_id SERIAL,
	ces_id INTEGER NOT NULL,
	ces_amm_data TIMESTAMP NOT NULL,
	ces_amm_ultimo_anno INTEGER NOT NULL,
	ces_amm_importo NUMERIC,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento PRIMARY KEY(ces_amm_id),
	CONSTRAINT siac_t_cespiti_siac_t_cespiti_ammortamento FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_ammortamento'::text, 'siac_t_cespiti_ammortamento_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '',false);
SELECT fnc_dba_create_index ('siac_t_cespiti_ammortamento'::text, 'siac_t_cespiti_ammortamento_fk_ces_id_idx'::text, 'ces_id'::text, '', false);


CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento_dett (
	ces_amm_dett_id SERIAL,
	ces_amm_id INTEGER NOT NULL,
	ces_amm_dett_anno INTEGER,
	ces_amm_dett_importo NUMERIC,
	pnota_id INTEGER,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento_dett PRIMARY KEY(ces_amm_dett_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ces_amm_id)
		REFERENCES siac_t_cespiti_ammortamento(ces_amm_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_dett_siac_t_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_t_cespiti_ammortamento_dett'::text, 'siac_t_cespiti_ammortamento_dett_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text,'',false);
SELECT fnc_dba_create_index ('siac_t_cespiti_ammortamento_dett'::text, 'siac_t_cespiti_ammortamento_dett_fk_ces_amm_id_idx'::text,'ces_amm_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_t_cespiti_ammortamento_dett'::text, 'siac_t_cespiti_ammortamento_dett_fk_pnota_id_idx'::text,'pnota_id'::text,'', false);



-------------
--RELAZIONE
--------------
--- STORICIZZAZIONE
CREATE TABLE IF NOT EXISTS siac_r_cespiti_categoria_aliquota_calcolo_tipo (
	cescat_aliquota_calcolo_tipo_id SERIAL,
	cescat_id INTEGER,
	cescat_calcolo_tipo_id INTEGER,
	aliquota_annua NUMERIC,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_categoria_aliquota_calcolo_tipo PRIMARY KEY(cescat_aliquota_calcolo_tipo_id),
	CONSTRAINT siac_d_cespiti_categoria_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (cescat_id)
		REFERENCES siac.siac_d_cespiti_categoria(cescat_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_cespiti_categoria_calcolo_tipo_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (cescat_calcolo_tipo_id)
		REFERENCES siac.siac_d_cespiti_categoria_calcolo_tipo(cescat_calcolo_tipo_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_categoria_aliquota_calcolo_tipo FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_r_cespiti_categoria_aliquota_calcolo_tipo'::text , 'siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_cescat_calcolo_tipo_id_idx'::text, 'cescat_calcolo_tipo_id'::text, '',false);
	
SELECT fnc_dba_create_index ('siac_r_cespiti_categoria_aliquota_calcolo_tipo'::text,  'siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_cescat_id_idx'::text, 'cescat_id'::text, '',false);
	
SELECT fnc_dba_create_index ( 'siac_r_cespiti_categoria_aliquota_calcolo_tipo'::text,'siac_r_cespiti_categoria_aliquota_calcolo_tipo_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '',false);

CREATE TABLE IF NOT EXISTS siac_r_cespiti_bene_tipo_conto_patr_cat (
	ces_bene_tipo_conto_patr_cat_id SERIAL,
	ces_bene_tipo_id INTEGER,
	cescat_id INTEGER NOT NULL,
	pdce_conto_patrimoniale_id INTEGER,
	pdce_conto_patrimoniale_code VARCHAR(200),
	pdce_conto_patrimoniale_desc VARCHAR(500),
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_bene_tipo_conto_patr_cat PRIMARY KEY(ces_bene_tipo_conto_patr_cat_id),
	CONSTRAINT siac_d_cespiti_bene_tipo_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (ces_bene_tipo_id)
	    REFERENCES siac.siac_d_cespiti_bene_tipo(ces_bene_tipo_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_d_cespiti_categoria_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (cescat_id)
	    REFERENCES siac.siac_d_cespiti_categoria(cescat_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_bene_tipo_conto_patr_ca FOREIGN KEY (ente_proprietario_id)
	    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE,
	  CONSTRAINT siac_t_pdce_conto_patrimoniale_siac_r_cespiti_bene_tipo_conto_p FOREIGN KEY (pdce_conto_patrimoniale_id)
	    REFERENCES siac.siac_t_pdce_conto(pdce_conto_id)
	    ON DELETE NO ACTION
	    ON UPDATE NO ACTION
	    NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_r_cespiti_bene_tipo_conto_patr_cat'::text, 'siac_r_cespiti_bene_tipo_conto_patr_cat_fk_pdce_conto_patrimoniale_id_idx'::text, 'pdce_conto_patrimoniale_id'::text,'',false);  
SELECT fnc_dba_create_index ('siac_r_cespiti_bene_tipo_conto_patr_cat'::text,'siac_r_cespiti_bene_tipo_conto_patr_cat_fk_ces_bene_tipo_id_idx'::text,'ces_bene_tipo_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_r_cespiti_bene_tipo_conto_patr_cat'::text, 'siac_r_cespiti_bene_tipo_conto_patr_cat_fk_cescat_id_idx'::text,'cescat_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_r_cespiti_bene_tipo_conto_patr_cat'::text, 'siac_r_cespiti_bene_tipo_conto_patr_cat_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '', false);

--LEGAMI STATI ACCETTAZIONE PRIME NOTE 
CREATE TABLE IF NOT EXISTS siac_r_pn_def_accettazione_stato (
	pn_r_sta_acc_def_id SERIAL,
	pn_sta_acc_def_id INTEGER   NOT NULL,
	pnota_id INTEGER   NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_pn_def_accettazione_stato PRIMARY KEY(pn_r_sta_acc_def_id),
	CONSTRAINT siac_t_prima_nota_siac_r_pn_def_accettazione_stato FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_def_accettazione_stato_siac_r_pn_def_accettazione_stato FOREIGN KEY (pn_sta_acc_def_id)
		REFERENCES siac_d_pn_def_accettazione_stato(pn_sta_acc_def_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_d_pn_def_accettazione_stato'::text, 'siac_r_pn_stato_acc_def_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text,'',false);
SELECT fnc_dba_create_index ('siac_r_pn_def_accettazione_stato'::text, 'siac_r_pn_stato_acc_def_fk_pnota_id'::text, 'pnota_id,pn_sta_acc_def_id , ente_proprietario_id'::text,'data_cancellazione IS NULL'::text, true);


CREATE TABLE IF NOT EXISTS siac_r_pn_prov_accettazione_stato (
	pn_r_sta_acc_prov_id SERIAL,
	pn_sta_acc_prov_id INTEGER   NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_pn_prov_accettazione_stato PRIMARY KEY(pn_r_sta_acc_prov_id),
	CONSTRAINT siac_t_prima_nota_siac_r_pn_prov_accettazione_stato FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_prov_accettazione_stato_siac_r_pn_prov_accettazione_stato FOREIGN KEY (pn_sta_acc_prov_id)
		REFERENCES siac_d_pn_prov_accettazione_stato(pn_sta_acc_prov_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_r_pn_prov_accettazione_stato'::text, 'siac_r_pn_stato_acc_prov_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_r_pn_prov_accettazione_stato'::text, 'siac_r_pn_stato_acc_prov_fk_pnota_id'::text, 'pnota_id,pn_sta_acc_prov_id,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);

CREATE TABLE IF NOT EXISTS siac_r_cespiti_prima_nota (
	ces_pn_id SERIAL,
	ces_id INTEGER NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_prima_nota PRIMARY KEY(ces_pn_id),
	CONSTRAINT siac_t_prima_nota_siac_r_cespiti_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_d_pn_prov_accettazione_stato_siac_t_cespite FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_prima_nota FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);
SELECT fnc_dba_create_index ('siac_r_cespiti_prima_nota'::text, 'siac_r_cespiti_prima_nota_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '', false);
SELECT fnc_dba_create_index ('siac_r_cespiti_prima_nota'::text, 'siac_r_cespiti_prima_nota_fk_pnota_id'::text,'pnota_id,ces_id,ente_proprietario_id'::text,'data_cancellazione IS NULL'::text, true);


CREATE TABLE IF NOT EXISTS siac_r_cespiti_variazione_prima_nota (
	ces_var_pn_id SERIAL,
	ces_var_id INTEGER NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_variazione_prima_nota PRIMARY KEY(ces_var_pn_id),
	CONSTRAINT siac_t_prima_nota_siac_r_cespite_variazione_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespite_variazione_siac_r_cespite_variazione_prima_nota FOREIGN KEY (ces_var_id)
		REFERENCES siac_t_cespiti_variazione(ces_var_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_variazione_prima_nota FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_r_cespiti_variazione_prima_nota'::text, 'siac_r_cespiti_variazione_prima_nota_fk_ente_proprietario_id_idx'::text, 'ente_proprietario_id'::text, '',false);
SELECT fnc_dba_create_index ('siac_r_cespiti_variazione_prima_nota'::text, 'siac_r_cespiti_variazione_prima_nota_fk_pnota_id'::text,'pnota_id,ces_var_id,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);

	
--LEGAME PNOTA-DISMISSIONI
CREATE TABLE IF NOT EXISTS siac_r_cespiti_dismissioni_prima_nota (
	ces_dismissioni_pn_id SERIAL,
	ces_dismissioni_id INTEGER NOT NULL,
	pnota_id INTEGER NOT NULL,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_r_cespiti_dismissioni_prima_nota PRIMARY KEY(ces_dismissioni_pn_id),
	CONSTRAINT siac_t_prima_nota_siac_r_cespite_dismissioni_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_prima_nota_siac_r_cespite_dismissionii_prima_nota FOREIGN KEY (ces_dismissioni_id)
		REFERENCES siac_t_cespiti_dismissioni(ces_dismissioni_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_r_cespiti_dismissioni_prima_nota FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

SELECT fnc_dba_create_index ('siac_r_cespiti_dismissioni_prima_nota'::text, 'siac_r_cespiti_dismissioni_prima_nota_fk_ente_proprietario_id_idx'::text,'ente_proprietario_id'::text, '',false);
SELECT fnc_dba_create_index ('siac_r_cespiti_dismissioni_prima_nota'::text, 'siac_r_cespiti_dismissioni_prima_nota_fk_pnota_id'::text, 'pnota_id,ces_dismissioni_id,ente_proprietario_id'::text, 'data_cancellazione IS NULL'::text, true);

--DDL FINE