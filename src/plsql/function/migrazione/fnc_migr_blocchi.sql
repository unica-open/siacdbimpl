/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_blocchi (
  migr_id_min integer,
  migr_id_max integer,
  migr_commitsize integer
)
RETURNS TABLE (
  migr_id_da integer,
  migr_id_a integer
) AS
$body$
DECLARE
 migr_blocco INTEGER:=0;

begin

  migr_blocco:=migr_id_min;

  loop
 	 if migr_blocco<=migr_id_max then

      if migr_blocco!=migr_id_min then
           migr_id_da := migr_blocco+1;
      else migr_id_da := migr_blocco;
      end if;

      migr_id_a  := migr_blocco+migr_commitSize;

      migr_blocco:=migr_id_a;

      return next;
     end if;
--     exit when migr_blocco>=migr_id_max;
     exit when migr_blocco>=migr_id_max;
     --exit when migr_impegno_blocco>=migr_impegno_id_min+5000;
   end loop;


   return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
