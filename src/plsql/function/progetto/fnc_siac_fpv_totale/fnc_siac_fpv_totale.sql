/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_fpv_totale(
    programma_id_in integer,
    anno_in varchar)
  RETURNS TABLE( 
 anno_out varchar,
  entrata_prevista numeric,
  fpv_entrata numeric, 
  spesa_prevista numeric,
  fpv_spesa numeric,
  totale numeric
   )
  AS
$body$
DECLARE

begin 

anno_out :='2015';
  entrata_prevista :=0;
  fpv_entrata :=0;
  spesa_prevista :=0;
  fpv_spesa  :=0;
  fpv_spesa :=0;
  
  return;

exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
        --RTN_MESSAGGIO:='capitolo altro errore';
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,SQLERRM;
return;
END;
$body$
  LANGUAGE 'plpgsql'
  VOLATILE
  CALLED ON NULL INPUT
  SECURITY DEFINER;
 

 