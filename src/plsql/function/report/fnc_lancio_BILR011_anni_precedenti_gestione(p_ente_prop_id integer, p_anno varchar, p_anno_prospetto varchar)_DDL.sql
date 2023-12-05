/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric,
  imp_colonna_d numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR171_anni_precedenti che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
        Richiama la BILR011_allegato_fpv_previsione_con_dati_gestione con parametri 
        diversi a seconda dell'anno di prospetto.
		Poiche' il report BILR171 viene eliminato per l'anno 2018 la funzione 
        fnc_lancio_BILR171_anni_precedenti rimane per gli anni precedenti.
*/

/*
	21/12/2020: SIAC-7933.
    	Questa funzione serve per calcolare i dati della colonna H dell'anno precedente
        quando l'anno di prospetto e' maggiore di quello del bilancio.
        In questo caso tale colonna diventa la colonna A del report.
    	La funzione e' stata rivista in quanto prima la colonna H dell'anno precedente 
        del report era calcolata usando solo i dati della Gestione.
        Invece ora viene calcolata sommando i dati della Gestione delle colonne
        A e B e quelli di Previsione delle colonne D, E, F e G dell'anno precedente 
        cosi' come avviene anche quando l'anno di prospetto e' uguale all'anno del Bilancio. 
        Per questo motivo le query sono state riviste e viene richiamata anche la funzione
        "BILR011_Allegato_B_Fondo_Pluriennale_vincolato" che prende i dati di Previsione.
        
        Inoltre la funzione restituisce anche l'importo della colonna D anno precedente,
        in quanto e' stato richiesto che quando l'anno prospetto e' maggiore di quello
        del bilancio tale importo sia sommato alla colonna B.        

	28/02/2023: SIAC-8866.
    	Quando l'anno prospetto e' uguale a quallo del bilancio + 2, occorre sottrare per la colonna A l'importo
        "spese_impegnate_da_prev" che contiene l'importo degli impegni utilizzati per il calcolo 
*/

	--anno prospetto = anno bilancio + 1
if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
 /*
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;*/  
  
  	--  FPV = dati di Previsione, anno_prec = dati di gestione    
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,    
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-(anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) imp_colonna_h,
    FPV.spese_da_impeg_anno1_d imp_colonna_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro;
 
	--anno prospetto = anno bilancio + 2
elsif p_anno_prospetto::integer = (p_anno::integer)+2 then
-- quando l'anno prospette e' anno bilancio + 2, devo calcolare l'importo della 
-- colonna H del report con anno -2 perche' diventa la colonna A dell'anno -1.
  return query
   select anno_meno2.missione_code, anno_meno2.programma_code,
   (anno_meno2.importo_colonna_h -
    (anno_meno1.importo_avanzo+anno_meno1.spese_impegnate+ 
    anno_meno2.spese_da_impeg_anno1_d -anno_meno1.spese_impegnate_da_prev) + --devo aggiungere anche la colonna_B.
    anno_meno1.spese_da_impeg_anno1_d + anno_meno1.spese_da_impeg_anno2_e +
   	anno_meno1.spese_da_impeg_anni_succ_f + anno_meno1.spese_da_impeg_non_def_g) imp_colonna_h,
    anno_meno1.spese_da_impeg_anno1_d imp_colonna_d
  from (
  	--  FPV = dati di Previsione, anno_prec = dati di gestione, Anno prospetto -2.
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma 
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g ) importo_colonna_h,
    anno_prec.importo_avanzo, anno_prec.spese_impegnate, FPV.spese_da_impeg_anno1_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno2,
 ( --  FPV = dati di Previsione, anno_prec = dati di gestione. Anno prospetto -1.
 	with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) importo_colonna_h,
    FPV.spese_da_impeg_anno1_d, FPV.spese_da_impeg_anno2_e,
    FPV.spese_da_impeg_anni_succ_f, FPV.spese_da_impeg_non_def_g,
    anno_prec.spese_impegnate, anno_prec.importo_avanzo, anno_prec.spese_impegnate_da_prev
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno1
where anno_meno2.missione_code = anno_meno1.missione_code
  and   anno_meno2.programma_code = anno_meno1.programma_code;
  
  /*
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;*/

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;