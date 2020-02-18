/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿--- 20.04.2016 Sofia compilata in bilprodmult
-- 01.04.2016 Sofia
-- function di restituzione di un set di ordinativi
-- per ente e tipo
-- dato un elenco di ord_id passati in un array in input
/*drop  FUNCTION fnc_mif_ordinativo_get_cursor
( enteProprietarioId integer,
  ordTipoCode varchar,
  ordArray integer[])*/

drop function fnc_mif_ordinativo_get_cursor
( enteProprietarioId integer,
  ordTipoCode        varchar,
  ordArray           text);

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_get_cursor
( enteProprietarioId integer,
  ordTipoCode        varchar,
  ordArray           text)
RETURNS TABLE (ord_id integer, ord_tipo_id integer, ord_trasm_oil_data TIMESTAMP WITHOUT TIME ZONE,
-- 16.04.2018 Sofia SIAC-5934
               ord_emissione_data  TIMESTAMP WITHOUT TIME ZONE, ord_spostamento_data  TIMESTAMP WITHOUT TIME ZONE)  AS
$body$
DECLARE
 ordCursor refcursor;
 recOrdCursor record;
 strOrdCursor varchar:=null;
 cArray integer:=1;

begin


  strOrdCursor:='select ord.ord_id, ord.ord_tipo_id , ord.ord_trasm_oil_data , ord.ord_emissione_data, ord.ord_spostamento_data from siac_t_ordinativo ord , siac_d_ordinativo_tipo tipo  where ord.ente_proprietario_id='||enteProprietarioId||
                 ' and ord.ord_id::integer in (';
  /*while coalesce(ordArray[cArray],0)!=0
  loop
--	raise notice 'ord_id=% ',ordArray[cArray];
    strOrdCursor:=strOrdCursor||ordArray[cArray];
    if coalesce(ordArray[cArray+1],0)!=0 then
     strOrdCursor:=strOrdCursor||',';
    end if;
    cArray:=cArray+1;
  end loop;*/
  strOrdCursor:=strOrdCursor||ordArray;
  strOrdCursor:=strOrdCursor||') and ord.ord_tipo_id=tipo.ord_tipo_id and tipo.ord_tipo_code='''
                            ||ordTipoCode||''''
                            ||' and ord.data_cancellazione is null and ord.validita_fine is null'
                            ||' and tipo.data_cancellazione is null and tipo.validita_fine is null';
  raise notice 'strOrdCursor=%',strOrdCursor;
  open ordCursor for execute strOrdCursor;
  loop
    fetch ordCursor into recOrdCursor;
    exit when NOT FOUND;
    ord_id:=recOrdCursor.ord_id;
    ord_tipo_id:=recOrdCursor.ord_tipo_id;
    ord_trasm_oil_data:=recOrdCursor.ord_trasm_oil_data;
    ord_emissione_data:=recOrdCursor.ord_emissione_data; -- 16.04.2018 Sofia SIAC-5934
    ord_spostamento_data:=recOrdCursor.ord_spostamento_data; -- 16.04.2018 Sofia SIAC-5934
 --   raise notice 'ord_id=% ',ord_id;
 --   raise notice 'ord_id=% ',ord_tipo_id;
	return next;
  end loop;
  close  ordCursor;

  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;