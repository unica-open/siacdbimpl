/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_get_array
( enteProprietarioId integer,
  ordTipoCode varchar,
  ordIdDa integer,
  ordIdA integer)
RETURNS INTEGER[]  AS
$body$
DECLARE
 ordCursor refcursor;
 recOrdCursor record;
 strOrdCursor varchar:=null;
 cArray integer:=1;

 arrayOrdin integer[];
begin


  strOrdCursor:='select ord.ord_id from siac_t_ordinativo ord , siac_d_ordinativo_tipo tipo  where ord.ente_proprietario_id='||enteProprietarioId||
                 ' and ord.ord_id::integer BETWEEN '||ordIdDa||' and '||ordIdA;
  strOrdCursor:=strOrdCursor||' and ord.ord_tipo_id=tipo.ord_tipo_id and tipo.ord_tipo_code='''
                            ||ordTipoCode||''''
                            ||' and ord.data_cancellazione is null and ord.validita_fine is null'
                            ||' and tipo.data_cancellazione is null and tipo.validita_fine is null';
  raise notice 'strOrdCursor=%',strOrdCursor;
  open ordCursor for execute strOrdCursor;
  loop
    fetch ordCursor into recOrdCursor;
    exit when NOT FOUND;
    arrayOrdin[cArray]:=recOrdCursor.ord_id;
    cArray:=cArray+1;
  end loop;
  close  ordCursor;

  return arrayOrdin;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;