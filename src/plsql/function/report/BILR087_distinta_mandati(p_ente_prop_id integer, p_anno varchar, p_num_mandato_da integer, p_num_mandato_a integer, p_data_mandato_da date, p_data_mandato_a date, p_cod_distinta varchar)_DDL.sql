/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR087_distinta_mandati" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_cod_distinta varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  importo_lordo_mandato numeric,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  nome_tesoriere varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  importo_competenza numeric,
  importo_residui numeric,
  importo_prec_mandati numeric,
  importo_prec_residui numeric,
  importo_prec_competenza numeric,
  stato_mandato varchar,
  display_error varchar,
  cod_distinta varchar,
  desc_distinta varchar,
  richiedente_nome varchar,
  atto_tipo_code varchar,
  atto_tipo_desc varchar,
  atto_anno varchar,
  atto_numero integer,
  atto_struttura varchar,
  conto_tesoreria varchar,
  commissioni varchar,
  pnrr_code varchar,
  perimetro_sanitario varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoImpegni record;
elencoLiquidazioni record;
elencoOneri	record;
elencoImportiPrec record;
elencoImportiAnnul record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
posizione integer;
cod_atto_amm VARCHAR;
appStr VARCHAR;

cod_tipo_onere VARCHAR;
subDocumento VARCHAR;
elemTipoCode VARCHAR;
numFatturaApp VARCHAR;
ImportoApp numeric;
ordIdReversale	INTEGER;
anno_eser_int INTEGER;
importo_prec_mandati_app NUMERIC;
importo_prec_competenza_app NUMERIC;
importo_prec_residui_app NUMERIC;



BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
nome_tesoriere='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_mandati=0;
importo_prec_competenza=0;
importo_prec_residui=0;
stato_mandato='';
cod_distinta='';
desc_distinta='';

importo_prec_mandati_app=0;
importo_prec_competenza_app=0;
importo_prec_residui_app=0;
anno_eser_int=p_anno :: INTEGER;

--03/04/17 Daniela: nuovi campi per jira SIAC-4698
richiedente_nome='';
atto_tipo_code='';
atto_tipo_desc='';
atto_anno='';
atto_numero=0;
atto_struttura='';
conto_tesoreria='';
commissioni='';
pnrr_code:='';
perimetro_sanitario:='';

	/* 12/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca */
display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A" E "DATA MANDATO DA/A".';
    return next;
    return;
end if;

/* calcolo gli importi relativi ai riporti ANNULLATI.
    	Prendo tutti gli importi dell'anno di esercizio dello stesso periodo
        o numero di mandato indicato dall'utente ma che hanno stato A */
/*        
BEGIN
	for elencoImportiAnnul in
		SELECT t_ordinativo.ord_anno, 
        		SUM(t_ord_ts_det.ord_ts_det_importo) somma_importo
          FROM  siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_t_ordinativo t_ordinativo, 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                 siac_d_ordinativo_tipo d_ord_tipo       
          WHERE t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
			AND (p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_mandato_da AND p_num_mandato_a)
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                OR (p_num_mandato_a IS  NULL AND p_num_mandato_da=t_ordinativo.ord_numero )
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a=t_ordinativo.ord_numero ))
			AND (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_emissione_data between p_data_mandato_da AND p_data_mandato_a)
                    OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
                    OR (p_data_mandato_a IS NULL AND p_data_mandato_da IS NOT NULL
                    	AND p_data_mandato_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL
                    	AND p_data_mandato_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
          AND d_ord_stato.ord_stato_code ='A' --Annullato
          AND d_ord_tipo.ord_tipo_code='P'  /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            AND r_ord_stato.validita_fine IS NULL 
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL           
            GROUP BY t_ordinativo.ord_anno          
    loop    
    	importo_annul_mandati_app= importo_annul_mandati_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        IF elencoImportiAnnul.ord_anno  < anno_ese_finanz THEN
        	importo_annul_residui_app=importo_annul_residui_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        ELSE
        	importo_annul_competenza_app=importo_annul_competenza_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        END IF;
        
    end loop;   
END;*/


	/* calcolo gli importi relativi ai riporti PRECEDENTI.
    	Prendo tutti gli importi dell'anno di esercizio precedenti il periodo
        o i numeri di mandato indicati dall'utente */
/* 04/02/2016: estraggo  l'anno dell'impegno tramite la relativa liquidazione
	perche' per sapere se l'importo e' competenza o residuo devo confrontare 
    l'anno dell'impegno e non quello del mandato */        
BEGIN
	for elencoImportiPrec in              
          SELECT --t_ordinativo.ord_anno, 
          	t_movgest.movgest_anno,
          SUM(t_ord_ts_det.ord_ts_det_importo) somma_importo
          FROM  siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_t_ordinativo t_ordinativo, 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                siac_d_ordinativo_tipo d_ord_tipo  ,
                siac_r_liquidazione_ord r_liq_ord,
                siac_r_liquidazione_movgest r_liq_movgest,
                siac_t_movgest t_movgest,
                siac_t_movgest_ts t_movgest_ts   
          WHERE t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
            AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
           AND r_liq_movgest.liq_id=r_liq_ord.liq_id
           AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id
			AND ((p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
                      AND t_ordinativo.ord_numero < p_num_mandato_da )
                  --OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                  OR (p_num_mandato_a IS  NULL AND p_num_mandato_da IS NOT NULL 
                  		AND t_ordinativo.ord_numero < p_num_mandato_da)
                  OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS NOT NULL  
                  		AND t_ordinativo.ord_numero < p_num_mandato_a)
              OR (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                      AND t_ordinativo.ord_emissione_data < p_data_mandato_da )
                     -- OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
              	OR (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL
                	AND t_ordinativo.ord_emissione_data<p_data_mandato_da)                      	                        
                OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS NOT NULL
                      		AND t_ordinativo.ord_emissione_data <p_data_mandato_a ))                                                           			
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
           /* 01/03/2016: aggiunto il filtro per escludere i mandati annullati
           		nel calcolo dell'importo precedente */
          AND d_ord_stato.ord_stato_code <>'A' --Annullato
          AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            AND r_ord_stato.validita_fine IS NULL 
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL     
            AND r_liq_ord.data_cancellazione IS NULL 
            AND r_liq_movgest.data_cancellazione IS NULL 
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL                 
            GROUP BY t_movgest.movgest_anno--t_ordinativo.ord_anno             		 
    loop
    	importo_prec_mandati_app= importo_prec_mandati_app+COALESCE(elencoImportiPrec.somma_importo,0);
        /*04/02/2016: uso l'anno dell'impegno invece che quello dell'ordinativo */
        --IF elencoImportiPrec.ord_anno  < anno_eser_int THEN
        IF elencoImportiPrec.movgest_anno  < anno_eser_int THEN
        	importo_prec_residui_app=importo_prec_residui_app+COALESCE(elencoImportiPrec.somma_importo,0);
        ELSE
        	importo_prec_competenza_app=importo_prec_competenza_app+COALESCE(elencoImportiPrec.somma_importo,0);
        END IF;
        
    end loop;   
END;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;



--dataMandatoStr= to_date(p_data_mandato,'yyyy/MM/dd') ::varchar;


for elencoMandati in
/* 04/02/2016: estraggo anche l'anno dell'impegno tramite la relativa liquidazione
	perche' per sapere se l'importo e' competenza o residuo devo confrontare 
    l'anno dell'impegno e non quello del mandato */
select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
		t_periodo.anno anno_eser, t_ordinativo.ord_anno,
		 t_ordinativo.ord_desc,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
        t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,        
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        t_movgest.movgest_anno anno_impegno, d_distinta.dist_code, d_distinta.dist_desc
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698 
        , t_soggetto1.soggetto_desc soggetto1_desc
        , d_commisione.comm_tipo_desc
        , d_contotes.contotes_code
        -- in assenza di atto per ordinativo prendo quello legato alla liquidazione
		,case when r_ord_atto.attoamm_id is not null then COALESCE(d_ord_atto_amm_tipo.attoamm_tipo_code,'')
        	else COALESCE(d_liq_atto_amm_tipo.attoamm_tipo_code,'') end atto_tipo_code
		,case when r_ord_atto.attoamm_id is not null then COALESCE(d_ord_atto_amm_tipo.attoamm_tipo_desc,'')
        	else COALESCE(d_liq_atto_amm_tipo.attoamm_tipo_desc,'') end atto_tipo_desc
		,case when r_ord_atto.attoamm_id is not null then COALESCE(t_ord_atto.attoamm_anno,'')
        	else COALESCE(t_liq_atto.attoamm_anno,'') end attoamm_anno
		,case when r_ord_atto.attoamm_id is not null then t_ord_atto.attoamm_numero
        	else t_liq_atto.attoamm_numero end attoamm_numero
		,case when r_ord_atto.attoamm_id is not null then COALESCE(t_class.classif_code,'')||' ' ||COALESCE(t_ord_atto.attoamm_oggetto,'')
        	else COALESCE(t_class1.classif_code,'')||' ' ||COALESCE(t_liq_atto.attoamm_oggetto,'') end attoamm_struttura,
 -- 03/04/17 Daniela fine
                --siac-tasks-Issues#70 20/04/2023.
                --Aggiunta selezione del falg PNRR e Perimetro Sanitario 
 		case when COALESCE(pnrr.pnrr_code,'') ='1' then 'SI'
        	else 'NO' end pnrr_code,
--da Canova: il perimetro sanitario correttamente espone due valori : 3 e 4 ma devono avere la descrizione differente in quanto 
--sono ambiti differenti.
--3 - per le spese delle gestione ordinaria della regione
--4 - per le spese della gestione sanitaria della regione
--quindi direi visto che la colonna è perimetro sanitario: se 3 esponi NO, se 4 esponi SI  
--e' NO anche se non definito (enti diversi da Regione).          
        case when COALESCE(perim_sanit.perim_sanitario,'') ='4' then 'SI'
        	else 'NO' end    perimetro_sanitario       	
		FROM  	siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
				siac_t_bil_elem t_bil_elem
                --siac-tasks-Issues#70 20/04/2023.
                --Aggiunta selezione del falg PNRR e Perimetro Sanitario
                	left join (select r_bil_class.elem_id, class.classif_code pnrr_code
                        from siac_t_class class,
                          siac_d_class_tipo tipo_class,
                          siac_r_bil_elem_class r_bil_class
                        where class.classif_tipo_id=tipo_class.classif_tipo_id
                        and r_bil_class.classif_id=class.classif_id
                        and class.ente_proprietario_id=p_ente_prop_id
                        and tipo_class.classif_tipo_code in ('CLASSIFICATORE_4',
                                                              'CLASSIFICATORE_40')) pnrr
                    on t_bil_elem.elem_id=pnrr.elem_id
                      left join (select r_bil_class.elem_id, class.classif_code perim_sanitario
                        from siac_t_class class,
                          siac_d_class_tipo tipo_class,
                          siac_r_bil_elem_class r_bil_class
                        where class.classif_tipo_id=tipo_class.classif_tipo_id
                        and r_bil_class.classif_id=class.classif_id
                        and class.ente_proprietario_id=p_ente_prop_id
                        and tipo_class.classif_tipo_code in ('PERIMETRO_SANITARIO_SPESA')) perim_sanit
                    on t_bil_elem.elem_id=perim_sanit.elem_id,                  
                siac_t_ordinativo t_ordinativo
                LEFT JOIN siac_d_distinta d_distinta
                	on (d_distinta.dist_id=t_ordinativo.dist_id
                    	AND d_distinta.data_cancellazione IS NULL)
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
				-- Operatore che ha registrato il mandato, ha senso l'outer join? Direi di si perche' non si trova sempre il codice nella tabella dei soggetti
				LEFT JOIN siac_t_soggetto t_soggetto1 on (t_soggetto1.soggetto_code=t_ordinativo.login_creazione and t_soggetto1.data_cancellazione is NULL)
				-- Commissioni  e conto corrente 
				LEFT JOIN siac_d_commissione_tipo d_commisione on (d_commisione.comm_tipo_id = t_ordinativo.comm_tipo_id and d_commisione.data_cancellazione is null)
				LEFT JOIN siac_d_contotesoreria d_contotes on (d_contotes.contotes_id = t_ordinativo.contotes_id and d_contotes.data_cancellazione is null)
				-- Atto amministrativo ordinativo
				LEFT JOIN siac_r_ordinativo_atto_amm r_ord_atto on (r_ord_atto.ord_id = t_ordinativo.ord_id and r_ord_atto.data_cancellazione is null)
                LEFT JOIN siac_t_atto_amm t_ord_atto ON (t_ord_atto.attoamm_id=r_ord_atto.attoamm_id AND t_ord_atto.data_cancellazione IS NULL)
				LEFT JOIN siac_d_atto_amm_tipo d_ord_atto_amm_tipo ON (d_ord_atto_amm_tipo.attoamm_tipo_id=t_ord_atto.attoamm_tipo_id AND d_ord_atto_amm_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_r_atto_amm_class r_ord_atto_amm_class ON (r_ord_atto_amm_class.attoamm_id=t_ord_atto.attoamm_id AND r_ord_atto_amm_class.data_cancellazione IS NULL)
                LEFT JOIN siac_t_class t_class ON (t_class.classif_id= r_ord_atto_amm_class.classif_id AND t_class.data_cancellazione IS NULL),
 -- 03/04/17 Daniela fine
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_liquidazione_ord r_liq_ord
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
				-- Atto amministrativo liquidazione
                LEFT JOIN siac_r_liquidazione_atto_amm r_liq_atto on (r_liq_atto.liq_id = r_liq_ord.liq_id and r_liq_atto.data_cancellazione is null)
                LEFT JOIN siac_t_atto_amm t_liq_atto ON (t_liq_atto.attoamm_id=r_liq_atto.attoamm_id AND t_liq_atto.data_cancellazione IS NULL)
				LEFT JOIN siac_d_atto_amm_tipo d_liq_atto_amm_tipo ON (d_liq_atto_amm_tipo.attoamm_tipo_id=t_liq_atto.attoamm_tipo_id AND d_liq_atto_amm_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_r_atto_amm_class r_liq_atto_amm_class ON (r_liq_atto_amm_class.attoamm_id=t_liq_atto.attoamm_id AND r_liq_atto_amm_class.data_cancellazione IS NULL)
                LEFT JOIN siac_t_class t_class1 ON (t_class1.classif_id= r_liq_atto_amm_class.classif_id AND t_class1.data_cancellazione IS NULL),
 -- 03/04/17 Daniela fine 
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
        	AND OL.ente_proprietario_id=ep.ente_proprietario_id
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
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id
           	/* valorizzo le condizioni in base al fatto che i parametri
            	- numero mandato DA A
                - data mandato DA A
            	siano valorizzati o meno */
		   AND ((p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_mandato_da 
                    AND p_num_mandato_a))
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                OR (p_num_mandato_a IS  NULL 
                	AND p_num_mandato_da=t_ordinativo.ord_numero )
                OR (p_num_mandato_da IS  NULL 
                	AND p_num_mandato_a=t_ordinativo.ord_numero ))
			AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            			AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                        between p_data_mandato_da AND p_data_mandato_a))
                    OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
                    OR (p_data_mandato_a IS NULL AND p_data_mandato_da IS NOT NULL
                    	AND p_data_mandato_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL
                    	AND p_data_mandato_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))
		--AND p_data_mandato_da =to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
           --14/04/2017: aggiunto anche il test su  p_cod_distinta =''
           AND (p_cod_distinta is null OR p_cod_distinta ='' or d_distinta.dist_code=trim(p_cod_distinta))
            AND t_ordinativo.ente_proprietario_id= p_ente_prop_id
            AND t_periodo.anno=p_anno
            	/* Gli stati possibili sono:
                	I = INSERITO
                    T = TRASMESSO 
                    Q = QUIETANZIATO
                    F = FIRMATO
                    A = ANNULLATO 
                  Sono estratti tutti gli stati, se e' annullato e' segnalato sulla stampa */
            --AND d_ord_stato.ord_stato_code IN ('I', 'A', 'N') 
            AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            	/* devo testare la data di fine validita' perche'
                	quando un ordinativo e' annullato, lo trovo 2 volte,
                    uno con stato inserito e l'altro annullato */
            AND r_ord_stato.validita_fine IS NULL 
            AND ep.data_cancellazione IS NULL
            AND OL.data_cancellazione IS NULL
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
            --SIAC-8413 20/10/2021.
            --Non si deve fare il test sualla data cancellazione del soggetto
            --perche' il soggetto era valido al momento della creazione del 
            --mandato e quindi deve essere estratto.
            --AND t_soggetto.data_cancellazione IS NULL
            AND r_liq_ord.data_cancellazione IS NULL 
            AND r_liq_movgest.data_cancellazione IS NULL 
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL
            GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
              t_periodo.anno , t_ordinativo.ord_anno,
               t_ordinativo.ord_desc,
              t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
              t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
              OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,        
              t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
              t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno,
              d_distinta.dist_code, d_distinta.dist_desc
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
            , t_soggetto1.soggetto_desc
            , d_commisione.comm_tipo_desc
            , d_contotes.contotes_code
            , r_ord_atto.attoamm_id
            , d_ord_atto_amm_tipo.attoamm_tipo_code,d_ord_atto_amm_tipo.attoamm_tipo_desc, t_ord_atto.attoamm_anno,t_ord_atto.attoamm_numero,t_class.classif_code, t_ord_atto.attoamm_oggetto
            , d_liq_atto_amm_tipo.attoamm_tipo_code,d_liq_atto_amm_tipo.attoamm_tipo_desc, t_liq_atto.attoamm_anno,t_liq_atto.attoamm_numero,t_class1.classif_code, t_liq_atto.attoamm_oggetto,
            pnrr.pnrr_code, perim_sanit.perim_sanitario
 -- 03/04/17 Daniela fine
            ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data            
loop

--raise notice 'numero mandato % ',elencoMandati.ord_numero;

  stato_mandato= elencoMandati.ord_stato_code;

  importo_prec_mandati=COALESCE(importo_prec_mandati_app,0);
  importo_prec_residui=COALESCE(importo_prec_residui_app,0);
  importo_prec_competenza=COALESCE(importo_prec_competenza_app,0);

  nome_ente=elencoMandati.ente_denominazione;
  partita_iva_ente=elencoMandati.cod_fisc_ente;
  anno_ese_finanz=elencoMandati.anno_eser;
  anno_capitolo=elencoMandati.ord_anno;
  desc_mandato=COALESCE(elencoMandati.ord_desc,'');

  cod_capitolo=elencoMandati.cod_cap;
  cod_articolo=elencoMandati.cod_art;

  numero_mandato=elencoMandati.ord_numero;
  data_mandato=elencoMandati.ord_emissione_data;

      /* se il mandato e' ANNULLATO l'importo deve essere riportato
          come negativo */
  if(stato_mandato='A') THEN
      importo_lordo_mandato= COALESCE(-elencoMandati.IMPORTO_TOTALE,0);
  else
      importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);
  end if;

  /*  04/02/2016: se l'ordinativo ha un impegno che e' di un anno precedente 
          l'anno di esercizio, l'importo e' un residuo, altrimenti e' di competenza.
          Prima confrontavo l'anno dell'ordinativo invece che dell'impegno. */        
  --IF elencoMandati.ord_anno  < anno_eser_int THEN
  IF elencoMandati.anno_impegno  < anno_eser_int THEN
    importo_competenza=0;
    importo_residui=importo_lordo_mandato;
  ELSE
    importo_competenza=importo_lordo_mandato;
    importo_residui=0;
  END IF;

  nome_tesoriere=COALESCE(elencoMandati.ente_oil_tes_desc,'');

  benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
  benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
  benef_nome=COALESCE(elencoMandati.soggetto_desc,'');

  cod_distinta=COALESCE(elencoMandati.dist_code,'');
  desc_distinta=COALESCE(elencoMandati.dist_desc,'');
  
  richiedente_nome=COALESCE(elencoMandati.soggetto1_desc,'');
  atto_tipo_code=COALESCE(elencoMandati.atto_tipo_code,'');
  atto_tipo_desc=COALESCE(elencoMandati.atto_tipo_desc,'');
  atto_anno=COALESCE(elencoMandati.attoamm_anno,'');
  atto_numero=COALESCE(elencoMandati.attoamm_numero,0);
  atto_struttura=COALESCE(elencoMandati.attoamm_struttura,'');
  conto_tesoreria=COALESCE(elencoMandati.contotes_code,'');
  commissioni=COALESCE(elencoMandati.comm_tipo_desc,'');
  pnrr_code = elencoMandati.pnrr_code;
  perimetro_sanitario = elencoMandati.perimetro_sanitario;
  
return next;


nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
nome_tesoriere='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_mandati=0;
importo_prec_competenza=0;
importo_prec_residui=0;
stato_mandato='';
cod_distinta='';
desc_distinta='';
richiedente_nome='';
atto_tipo_code='';
atto_tipo_desc='';
atto_anno='';
atto_numero=0;
atto_struttura='';
conto_tesoreria='';
commissioni='';
pnrr_code:='';
perimetro_sanitario:='';

raise notice 'fine numero mandato % ',elencoMandati.ord_numero;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR087_distinta_mandati" (p_ente_prop_id integer, p_anno varchar, p_num_mandato_da integer, p_num_mandato_a integer, p_data_mandato_da date, p_data_mandato_a date, p_cod_distinta varchar)
  OWNER TO siac;