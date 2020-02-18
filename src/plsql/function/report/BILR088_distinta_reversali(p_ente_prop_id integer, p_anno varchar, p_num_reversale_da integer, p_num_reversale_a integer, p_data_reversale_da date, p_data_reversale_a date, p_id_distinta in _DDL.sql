/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR088_distinta_reversali" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_reversale_da integer,
  p_num_reversale_a integer,
  p_data_reversale_da date,
  p_data_reversale_a date,
  p_id_distinta integer
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  importo_lordo_reversale numeric,
  numero_reversale integer,
  data_reversale date,
  desc_reversale varchar,
  nome_tesoriere varchar,
  debitore_cod_fiscale varchar,
  debitore_partita_iva varchar,
  debitore_nome varchar,
  importo_competenza numeric,
  importo_residui numeric,
  importo_prec_reversali numeric,
  importo_prec_residui numeric,
  importo_prec_competenza numeric,
  stato_reversale varchar,
  display_error varchar,
  code_distinta varchar,
  desc_distinta varchar
) AS
$body$
DECLARE
elencoReversali record;
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
annoImpegno VARCHAR;
numImpegno VARCHAR;
numSubImpegno VARCHAR;
dataMandatoStr VARCHAR;
numImpegnoApp VARCHAR;
numSubImpegnoApp VARCHAR;
cod_tipo_onere VARCHAR;
subDocumento VARCHAR;
elemTipoCode VARCHAR;
var_anno VARCHAR;
numFatturaApp VARCHAR;
ImportoApp numeric;
ordIdReversale	INTEGER;
anno_eser_int INTEGER;
importo_prec_reversali_app NUMERIC;
importo_prec_competenza_app NUMERIC;
importo_prec_residui_app NUMERIC;


BEGIN


nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_reversale=0;
numero_reversale=0;
data_reversale=NULL;
desc_reversale='';
nome_tesoriere='';
debitore_cod_fiscale='';
debitore_partita_iva='';
debitore_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_reversali=0;
importo_prec_competenza=0;
importo_prec_residui=0;

stato_reversale='';

importo_prec_reversali_app=0;
importo_prec_competenza_app=0;
importo_prec_residui_app=0;
code_distinta ='';
desc_distinta='';


RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';

raise notice 'Estrazione dei dati delle reversali';
raise notice 'ora: % ',clock_timestamp()::varchar;

anno_eser_int=p_anno :: INTEGER;

	/* 12/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca */
display_error='';
if p_num_reversale_da IS NULL AND p_num_reversale_a IS NULL AND p_data_reversale_da IS NULL AND
	p_data_reversale_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO REVERSALE DA/A" E "DATA REVERSALE DA/A".';
    return next;
    return;
end if;

/* calcolo gli importi relativi ai riporti ANNULLATI.
    	Prendo tutti gli importi dell'anno di esercizio dello stesso periodo
        o numero di reversale indicato dall'utente ma che hanno stato A/N */
/*BEGIN
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
			AND (p_num_reversale_da IS NOT NULL AND p_num_reversale_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_reversale_da AND p_num_reversale_a)
                OR (p_num_reversale_da IS  NULL AND p_num_reversale_a IS  NULL)
                OR (p_num_reversale_a IS  NULL AND p_num_reversale_da=t_ordinativo.ord_numero )
                OR (p_num_reversale_da IS  NULL AND p_num_reversale_a=t_ordinativo.ord_numero ))
			AND (p_data_reversale_da IS NOT NULL AND p_data_reversale_a IS NOT NULL
            		AND (t_ordinativo.ord_emissione_data between p_data_reversale_da AND p_data_reversale_a)
                    OR (p_data_reversale_da IS  NULL AND p_data_reversale_a IS  NULL)
                    OR (p_data_reversale_a IS NULL AND p_data_reversale_da IS NOT NULL
                    	AND p_data_reversale_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_reversale_da IS NULL AND p_data_reversale_a IS NOT NULL
                    	AND p_data_reversale_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
          AND d_ord_stato.ord_stato_code ='A' --Annullato
          AND d_ord_tipo.ord_tipo_code='I'  /* Ordinativi di incasso */
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
    	importo_annul_reversali_app= importo_annul_reversali_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        IF elencoImportiAnnul.ord_anno < anno_ese_finanz THEN
        	importo_annul_residui_app=importo_annul_residui_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        ELSE
        	importo_annul_competenza_app=importo_annul_competenza_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        END IF;
        
    end loop;   
END;*/

	/* calcolo gli importi relativi ai riporti PRECEDENTI.
    	Prendo tutti gli importi dell'anno di esercizio precedenti il periodo
        o i numeri di reversale indicati dall'utente */
/* 04/02/2016: estraggo anche l'anno dell'accertamento 
	perchè per sapere se l'importo è competenza o residuo devo confrontare 
    l'anno dell'accertamento e non quello della reversale */      
BEGIN
	for elencoImportiPrec in
           SELECT --t_ordinativo.ord_anno, 
           t_movgest.movgest_anno anno_accertamento,
           SUM(t_ord_ts_det.ord_ts_det_importo) somma_importo
          FROM  siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_t_ordinativo t_ordinativo, 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts,
				siac_t_movgest_ts t_movgest_ts,
    			siac_t_movgest t_movgest,
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
           AND r_ord_ts_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
		   AND t_movgest.movgest_id=t_movgest_ts.movgest_id
		   AND r_ord_ts_movgest_ts.ord_ts_id=t_ord_ts.ord_ts_id
			AND ((p_num_reversale_da IS NOT NULL AND p_num_reversale_a IS NOT NULL
                      AND t_ordinativo.ord_numero < p_num_reversale_da )
                  OR (p_num_reversale_a IS  NULL AND p_num_reversale_da IS NOT NULL 
                  		AND t_ordinativo.ord_numero < p_num_reversale_da)
                  OR (p_num_reversale_da IS  NULL AND p_num_reversale_a IS NOT NULL  
                  		AND t_ordinativo.ord_numero < p_num_reversale_a)
              OR (p_data_reversale_da IS NOT NULL AND p_data_reversale_a IS NOT NULL
                      AND t_ordinativo.ord_emissione_data < p_data_reversale_da )
              	OR (p_data_reversale_da IS NOT NULL AND p_data_reversale_a IS  NULL
                	AND t_ordinativo.ord_emissione_data<p_data_reversale_da)                      	                        
                OR (p_data_reversale_da IS  NULL AND p_data_reversale_a IS NOT NULL
                      		AND t_ordinativo.ord_emissione_data <p_data_reversale_a ))                                                           			
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
          AND d_ord_stato.ord_stato_code <>'A' --Annullato
          AND d_ord_tipo.ord_tipo_code='I' /* Ordinativi di incasso */
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
            AND r_ord_ts_movgest_ts.data_cancellazione IS NULL
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL   
            GROUP BY t_movgest.movgest_anno-- t_ordinativo.ord_anno     
    loop
    	importo_prec_reversali_app= importo_prec_reversali_app+COALESCE(elencoImportiPrec.somma_importo,0);
        --IF elencoImportiPrec.ord_anno ::INTEGER < anno_eser_int THEN
        IF elencoImportiPrec.anno_accertamento  < anno_eser_int THEN        
        	importo_prec_residui_app=importo_prec_residui_app+COALESCE(elencoImportiPrec.somma_importo,0);
        ELSE
        	importo_prec_competenza_app=importo_prec_competenza_app+COALESCE(elencoImportiPrec.somma_importo,0);
        END IF;
        
    end loop;   
END;

for elencoReversali in
/* 04/02/2016: estraggo anche l'anno dell'accertamento 
	perchè per sapere se l'importo è competenza o residuo devo confrontare 
    l'anno dell'accertamento e non quello della reversale */
select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
		t_periodo.anno anno_eser, t_ordinativo.ord_anno,
		 t_ordinativo.ord_desc,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
        t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,        
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
        t_movgest.movgest_anno anno_accertamento,
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        d_distinta.dist_code, d_distinta.dist_desc
		FROM  	siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
				siac_t_bil_elem t_bil_elem,  
                siac_t_ordinativo t_ordinativo
                left join siac_d_distinta d_distinta on (t_ordinativo.dist_id= d_distinta.dist_id and d_distinta.data_cancellazione is NULL), 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts,
				siac_t_movgest_ts t_movgest_ts,
    			siac_t_movgest t_movgest,
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
           AND r_ord_ts_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
		   AND t_movgest.movgest_id=t_movgest_ts.movgest_id
		   AND r_ord_ts_movgest_ts.ord_ts_id=t_ord_ts.ord_ts_id
           	/* valorizzo le condizioni in base al fatto che i parametri
            	- numero reversale DA A
                - data reversale DA A
            	siano valorizzati o meno */
		   AND ((p_num_reversale_da IS NOT NULL AND p_num_reversale_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_reversale_da 
                    	AND p_num_reversale_a))
                OR (p_num_reversale_da IS  NULL AND p_num_reversale_a IS  NULL)
                OR (p_num_reversale_a IS  NULL AND p_num_reversale_da=t_ordinativo.ord_numero )
                OR (p_num_reversale_da IS  NULL AND p_num_reversale_a=t_ordinativo.ord_numero ))
			AND ((p_data_reversale_da IS NOT NULL AND p_data_reversale_a IS NOT NULL
            		AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') )
                    	 between p_data_reversale_da AND p_data_reversale_a)
                    OR (p_data_reversale_da IS  NULL AND p_data_reversale_a IS  NULL)
                    OR (p_data_reversale_a IS NULL AND p_data_reversale_da IS NOT NULL
                    	AND p_data_reversale_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_reversale_da IS NULL AND p_data_reversale_a IS NOT NULL
                    	AND p_data_reversale_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))    
            AND (p_id_distinta = 0 or t_ordinativo.dist_id=p_id_distinta)
            AND t_ordinativo.ente_proprietario_id= p_ente_prop_id
            AND t_periodo.anno=p_anno
            	/* Prendo tutti gli stati possibili:
                	I = INSERITO
                    T = TRASMESSO 
                    Q = QUIETANZIATO
                    F = FIRMATO
                    A = ANNULLATO 
                Sono estratti tutti gli stati, se è annullato è segnalato sulla stampa */
            --AND d_ord_stato.ord_stato_code IN ('I', 'A', 'N') 
            AND d_ord_tipo.ord_tipo_code='I' /* Ordinativi di incasso */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            	/* devo testare la data di fine validità perchè
                	quando un ordinativo è annullato, lo trovo 2 volte,
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
            AND t_soggetto.data_cancellazione IS NULL
            AND r_ord_ts_movgest_ts.data_cancellazione IS NULL
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
            ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data            
loop

--raise notice 'numero reversale % ',elencoReversali.mif_ord_numero;

importo_prec_reversali=COALESCE(importo_prec_reversali_app,0);
importo_prec_residui=COALESCE(importo_prec_residui_app,0);
importo_prec_competenza=COALESCE(importo_prec_competenza_app,0);

--importo_annul_reversali=COALESCE(importo_annul_reversali_app,0);
--importo_annul_residui=COALESCE(importo_annul_residui_app,0);
--importo_annul_competenza=COALESCE(importo_annul_competenza_app,0);

stato_reversale= elencoReversali.ord_stato_code;

nome_ente=elencoReversali.ente_denominazione;
partita_iva_ente=elencoReversali.cod_fisc_ente;
anno_ese_finanz=elencoReversali.anno_eser;
anno_capitolo=elencoReversali.ord_anno;

cod_capitolo=elencoReversali.cod_cap;
cod_articolo=elencoReversali.cod_art;
desc_reversale=COALESCE(elencoReversali.ord_desc,'');

numero_reversale=elencoReversali.ord_numero;
data_reversale=elencoReversali.ord_emissione_data;

if(stato_reversale='A') THEN
	importo_lordo_reversale= COALESCE(-elencoReversali.IMPORTO_TOTALE,0);
else
	importo_lordo_reversale= COALESCE(elencoReversali.IMPORTO_TOTALE,0);
end if;


	/* se l'ordinativo è di un anno precedente l'anno di esercizio, 
    	l'importo è un residuo, altrimenti è di competenza */
--IF elencoReversali.ord_anno < anno_eser_int THEN
IF elencoReversali.anno_accertamento < anno_eser_int THEN
  importo_competenza=0;
  importo_residui=importo_lordo_reversale;
ELSE
  importo_competenza=importo_lordo_reversale;
  importo_residui=0;
END IF;


nome_tesoriere=COALESCE(elencoReversali.ente_oil_tes_desc,'');

debitore_cod_fiscale=COALESCE(elencoReversali.codice_fiscale,'');
debitore_partita_iva=COALESCE(elencoReversali.partita_iva,'');
debitore_nome=COALESCE(elencoReversali.soggetto_desc,'');
       
code_distinta=COALESCE(elencoReversali.dist_code,'');
desc_distinta=COALESCE(elencoReversali.dist_desc,'');

return next;


nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_reversale=0;
numero_reversale=0;
data_reversale=NULL;
desc_reversale='';
nome_tesoriere='';
debitore_cod_fiscale='';
debitore_partita_iva='';
debitore_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_reversali=0;
importo_prec_competenza=0;
importo_prec_residui=0;
stato_reversale='';
code_distinta='';
desc_distinta='';

--raise notice 'fine numero reversale % ',elencoReversali.ord_numero;
end loop;

raise notice 'fine estrazione dei dati e preparazione dati in output ';  
raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'nessun reversale trovato' ;
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