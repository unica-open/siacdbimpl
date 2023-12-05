/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  bil_ele_code3 varchar,
  code_cofog varchar,
  code_transaz_ue varchar,
  pdc_iv varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  cup varchar,
  ord_id integer,
  ord_importo numeric,
  movgest_id integer,
  anno_movgest integer,
  movgest_importo numeric,
  fondo_plur_vinc numeric,
  movgest_importo_app numeric,
  tupla_group varchar
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
anno_succ varchar;

BEGIN

/*
  SIAC-7702 16/09/2020.
  La funzione e' stata trasformata in funzione chiamante delle funzioni che
  estraggono i dati:
  - BILR153_struttura_dca_spese_dati_anno; estrae i dati come faceva prima 
    la funzione "BILR153_struttura_dca_spese";
  - BILR153_struttura_dca_spese_fpv_anno_succ; estrae i dati dell'FPV per 
    l'anno di bilancio successivo (come richiesto dalla jira SIAC-7702).
*/

anno_succ:=(p_anno::integer + 1);

return query
      select dati.bil_anno ,  
        COALESCE(dati.missione_tipo_code,'') missione_tipo_code,
        COALESCE(dati.missione_tipo_desc,'') missione_tipo_desc, 
--SIAC-8734 24/05/2022.
--Estraendo con FULL JOIN se il dato non esiste nell'anno bilancio (dati) prendo quello
--dell'anno successivo (dati_fpv_anno_succ).         
        COALESCE(dati.missione_code,
        	COALESCE(dati_fpv_anno_succ.missione_code,'')) missione_code,
        COALESCE(dati.missione_desc,'') missione_desc,  
        COALESCE(dati.programma_tipo_code, '') programma_tipo_code,
        COALESCE(dati.programma_tipo_desc, '') programma_tipo_desc , 
        --29/04/2021 INC000005001587
        --Presi solo gli ultimi 2 caratteri del programma per risolvere un errore
        --nella generazione del file XBRL.
        --dati.programma_code,
--SIAC-8734 24/05/2022.
--Estraendo con FULL JOIN se il dato non esiste nell'anno bilancio (dati) prendo quello
--dell'anno successivo (dati_fpv_anno_succ).         
        COALESCE(right(dati.programma_code,2)::varchar, 
        	COALESCE(right(dati_fpv_anno_succ.programma_code,2)::varchar, '')) programma_code,
        COALESCE(dati.programma_desc,'') programma_desc,  
        COALESCE(dati.titusc_tipo_code,'') titusc_tipo_code,
        COALESCE(dati.titusc_tipo_desc,'') titusc_tipo_desc,  
        COALESCE(dati.titusc_code,'') titusc_code,
        COALESCE(dati.titusc_desc,'') titusc_desc,  
        COALESCE(dati.macroag_tipo_code,'') macroag_tipo_code,
        COALESCE(dati.macroag_tipo_desc,'') macroag_tipo_desc,  
        COALESCE(dati.macroag_code,'') macroag_code,
        COALESCE(dati.macroag_desc,'') macroag_desc,  
        COALESCE(dati.bil_ele_code,'') bil_ele_code,
        COALESCE(dati.bil_ele_desc,'') bil_ele_desc,  
        COALESCE(dati.bil_ele_code2,'') bil_ele_code2,
        COALESCE(dati.bil_ele_desc2,'') bil_ele_desc2,  
        COALESCE(dati.bil_ele_id, 0) bil_ele_id,
        COALESCE(dati.bil_ele_id_padre, 0) bil_ele_id_padre, 
        COALESCE(dati.bil_ele_code3,'') bil_ele_code3,
--SIAC-8734 24/05/2022.
--Estraendo con FULL JOIN se il dato non esiste nell'anno bilancio (dati) prendo quello
--dell'anno successivo (dati_fpv_anno_succ).         
        COALESCE(dati.code_cofog, 
        	COALESCE(dati_fpv_anno_succ.cofog,'')) code_cofog ,  
        COALESCE(dati.code_transaz_ue,
        	COALESCE(dati_fpv_anno_succ.transaz_ue, '')) code_transaz_ue ,
        COALESCE(dati.pdc_iv,
        	COALESCE(dati_fpv_anno_succ.pdc,'')) pdc_iv ,  
        COALESCE(dati.perim_sanitario_spesa,
        	COALESCE(dati_fpv_anno_succ.per_sanitario, '')) pdc_iv ,
        COALESCE(dati.ricorrente_spesa,
        	COALESCE(dati_fpv_anno_succ.ricorr_spesa, '')) ricorrente_spesa ,  
        --29/04/2021 INC000005001587
        --il cup deve essere NULL se non definito per evitare problemi all'XBRL.
--SIAC-8734 24/05/2022.
--Estraendo con FULL JOIN se il dato non esiste nell'anno bilancio (dati) prendo quello
--dell'anno successivo (dati_fpv_anno_succ).         
        case when COALESCE(dati.cup, dati_fpv_anno_succ.code_cup)
        	 = '' then null else dati.cup end cup ,
        dati.ord_id ,  
        dati.ord_importo ,
        dati.movgest_id ,  
        dati.anno_movgest ,
        COALESCE(dati.movgest_importo,0) movgest_importo,  
        case when LAG(dati.tupla_group,1) 
              OVER (order by dati.tupla_group) = dati.tupla_group then 0
              	else coalesce(dati_fpv_anno_succ.fondo_plur_vinc,0) 
              end fondo_plur_vinc,
        COALESCE(dati.movgest_importo_app, 0) movgest_importo_app, 
        COALESCE(dati.tupla_group, 
        	COALESCE(dati_fpv_anno_succ.tupla_group,'')) tupla_group
    from "BILR153_struttura_dca_spese_dati_anno"(p_ente_prop_id, p_anno) dati
--SIAC-8734 24/05/2022.
--Devo estrarre con FULL JOIN per non escludere alcuni impegni la cui tupla non esiste
--nell'anno bilancio ma in quello successivo.    
	 -- left join (select *
     full join (select *
    	from "BILR153_struttura_dca_spese_fpv_anno_succ" (p_ente_prop_id, 
        				anno_succ)) dati_fpv_anno_succ
    on dati.tupla_group=dati_fpv_anno_succ.tupla_group  ;

exception
	when no_data_found THEN
      raise notice 'Nessun dato trovato per per il DCD spese.';
      return;
	when others  THEN
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR153_struttura_dca_spese" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;