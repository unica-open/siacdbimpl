/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR223_anni_precedenti_gestione_capitolo" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  bil_elem_code varchar,
  bil_elem_desc varchar,
  bil_elem_code2 varchar,
  bil_elem_desc2 varchar,
  bil_elem_code3 varchar,
  imp_colonna_h numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR011_anni_precedenti_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR223.
        Richiama la BILR223_allegato_fpv_previsione_dati_gestione_capitolo con parametri 
        diversi a seconda dell'anno di prospetto.
		Rispetto all'analoga del report BILR011 questa restituisce anche i dati del 
        capitolo.
*/

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select proc1.missione_code, proc1.programma_code, 
    proc1.bil_elem_code, proc1.bil_elem_desc, proc1.bil_elem_code2, 
    proc1.bil_elem_desc2, proc1.bil_elem_code3,
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  ) proc1
  group by proc1.missione_code, proc1.programma_code,
  	proc1.bil_elem_code, proc1.bil_elem_desc, proc1.bil_elem_code2, 
    proc1.bil_elem_desc2, proc1.bil_elem_code3;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
    select a.missione_code, a.programma_code,
    a.bil_elem_code, a.bil_elem_desc, a.bil_elem_code2, a.bil_elem_desc2, a.bil_elem_code3,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select proc2.missione_code, 
         proc2.programma_code, 
         proc2.bil_elem_code, proc2.bil_elem_desc, proc2.bil_elem_code2, 
         proc2.bil_elem_desc2, proc2.bil_elem_code3,
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  ) proc2
  group by proc2.missione_code, proc2.programma_code,
  	proc2.bil_elem_code, proc2.bil_elem_desc, proc2.bil_elem_code2, 
    proc2.bil_elem_desc2, proc2.bil_elem_code3
  ) a, 
  (select proc3.missione_code, proc3.programma_code, 
  		proc3.bil_elem_code, proc3.bil_elem_desc, proc3.bil_elem_code2, 
        proc3.bil_elem_desc2, proc3.bil_elem_code3,
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR223_allegato_fpv_previsione_dati_gestione_capitolo" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  ) proc3
  group by proc3.missione_code, proc3.programma_code,
  	proc3.bil_elem_code, proc3.bil_elem_desc, proc3.bil_elem_code2, 
    proc3.bil_elem_desc2, proc3.bil_elem_code3
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code
  and   a.bil_elem_code  = b.bil_elem_code
  and   a.bil_elem_code2  = b.bil_elem_code2
  and	a.bil_elem_code3 = a.bil_elem_code3;

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
COST 100 ROWS 1000;