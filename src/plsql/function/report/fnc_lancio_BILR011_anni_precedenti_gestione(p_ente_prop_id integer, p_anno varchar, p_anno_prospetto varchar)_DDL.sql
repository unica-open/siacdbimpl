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
  imp_colonna_h numeric
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

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
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
  and   a.programma_code = b.programma_code;

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