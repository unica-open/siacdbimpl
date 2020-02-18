/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR105_stampa_versamenti_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
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
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_split_comm varchar,
  importo_iva_comm numeric,
  tipo_split_istituz varchar,
  importo_iva_istituz numeric,
  tipo_split_reverse varchar,
  importo_iva_reverse numeric,
  num_riscoss varchar,
  display_error varchar,
  cartacont varchar,
  aliquota varchar,
  data_quietanza date
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
numeroParametriData Integer;
cartacont_pk Integer;
id_bil INTEGER;
nome_ente_str VARCHAR;
partita_iva_ente_str VARCHAR;

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

importo_lordo_mandato=0;
tipo_split_comm='';
importo_iva_comm=0;
tipo_split_istituz='';
importo_iva_istituz=0;
tipo_split_reverse='';
importo_iva_reverse=0;

num_riscoss='';

numeroParametriData=0;
display_error='';

cartacont_pk=0;
cartacont='';
aliquota='';
data_quietanza=NULL;

/* SIAC-7014 18/09/2019.
	Procedura rivista per problemi di prestazioni; modifiche effettate:
    - tolto il cursore con il relativo ciclo e trasformata in return query;
    - query principale chimata con istruzione with;
    - tolte le query su ogni singolo mandato estratto per estrarre gli oneri e le reversali;
      E' stata inserita la procedura "fnc_bilr105_tab_oneri_reversali" che estrae per 
      tutti i mandati i relativi oneri e le reversali;
	- inserita le query iniziale per leggere l'id bilancio ed i dati dell'ente proprietario.
    
*/


if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A" E "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;
if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI DUE INTERVALLI DI DATA "DATA MANDATO DA/A" E "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;*/

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


select a.bil_id, c.ente_denominazione, c.codice_fiscale 
into id_bil, nome_ente_str, partita_iva_ente_str
from siac_t_bil a,
	siac_t_periodo b,
    siac_t_ente_proprietario c
where a.periodo_id=b.periodo_id
	and a.ente_proprietario_id=c.ente_proprietario_id
	and a.ente_proprietario_id = p_ente_prop_id
    and b.anno = p_anno   
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL
    and c.data_cancellazione IS NULL;
    
    
return query
with mandati as (
select 	 t_ordinativo.ord_anno,
		 t_ordinativo.ord_desc, t_ordinativo.ord_id,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
        t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        d_ord_stato.ord_stato_code, 
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        t_movgest.movgest_anno anno_impegno,
        r_ord_quietanza.ord_quietanza_data
		FROM   siac_t_ordinativo t_ordinativo
                --10/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                    on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                        and r_ord_quietanza.data_cancellazione IS NULL
                        --SIAC-6718 Aggiunto il test sulla data di fine validita'
                        and r_ord_quietanza.validita_fine IS NULL),
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
        WHERE  t_ordinativo.ord_id=r_ord_stato.ord_id          
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
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id            
			AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            	AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                	between p_data_mandato_da AND p_data_mandato_a))
                OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
            AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
            	AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                	between p_data_trasm_da AND p_data_trasm_a))
                OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))   
				--10/02/2017: aggiunto test sulla data quietanza
                -- se specificata in input.
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))                         		
            AND t_ordinativo.ente_proprietario_id= p_ente_prop_id
            AND t_ordinativo.bil_id = id_bil
            	/* Gli stati possibili sono:
                	I = INSERITO
                    T = TRASMESSO 
                    Q = QUIETANZIATO
                    F = FIRMATO
                    A = ANNULLATO 
                    Prendo tutti tranne gli annullati.
                   */
            AND d_ord_stato.ord_stato_code <> 'A'
            AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            	/* devo testare la data di fine validita' perche'
                	quando un ordinativo e' annullato, lo trovo 2 volte,
                    uno con stato inserito e l'altro annullato */
            AND r_ord_stato.validita_fine IS NULL 
            AND r_ord_stato.data_cancellazione IS NULL
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
            GROUP BY t_ordinativo.ord_anno,
               t_ordinativo.ord_desc, t_ordinativo.ord_id,
              t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
              t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
             d_ord_stato.ord_stato_code, t_movgest.movgest_anno
             ,r_ord_quietanza.ord_quietanza_data
            ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data),
oneri as (SELECT * from "fnc_bilr105_tab_oneri_reversali"(p_ente_prop_id,id_bil))   
select nome_ente_str::varchar nome_ente,
	   partita_iva_ente_str::varchar partita_iva_ente,
       p_anno::integer anno_ese_finanz,
       mandati.ord_anno::integer anno_mandato,
       mandati.ord_numero::integer numero_mandato,
       mandati.ord_emissione_data::date data_mandato,
       COALESCE(mandati.ord_desc,'')::varchar desc_mandato,
       COALESCE(mandati.codice_fiscale,'')::varchar benef_cod_fiscale,
       COALESCE(mandati.partita_iva,'')::varchar benef_partita_iva,
       COALESCE(mandati.soggetto_desc,'')::varchar benef_nome,
       mandati.ord_stato_code::varchar stato_mandato,
       COALESCE(mandati.IMPORTO_TOTALE,0)::numeric importo_lordo_mandato,
       oneri.tipo_split_comm::varchar tipo_split_comm,
       oneri.importo_iva_comm::numeric importo_iva_comm,
       oneri.tipo_split_istituz::varchar tipo_split_istituz,
       oneri.importo_iva_istituz::numeric importo_iva_istituz,
       oneri.tipo_split_reverse::varchar tipo_split_reverse,
       oneri.importo_iva_reverse::numeric importo_iva_reverse,
       oneri.num_riscoss::varchar num_riscoss,
       ''::varchar display_error,
       oneri.cartacont::varchar cartacont,
       oneri.aliquota::varchar aliquota,
       mandati.ord_quietanza_data::date data_quietanza
	from mandati 
    	LEFT JOIN oneri ON mandati.ord_id= oneri.ord_id
    where (oneri.tipo_split_comm <> '' OR oneri.tipo_split_istituz <> '' OR
    	oneri.tipo_split_reverse <> '') AND
        oneri.num_riscoss <> ''
    order by mandati.ord_numero, mandati.ord_emissione_data;                                             


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