/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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