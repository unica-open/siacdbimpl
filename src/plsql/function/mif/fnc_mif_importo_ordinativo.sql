/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_importo_ordinativo (
  id_in integer,ordTsDetTipoId integer, mantieniDec boolean
  )
RETURNS varchar AS
$body$
DECLARE

-- constant
IMPORTO_ATT constant varchar:='A';


strMessaggio varchar(1500):=null;
totOrdinativo numeric:=0;


--ordRecId record;
--curImportoOrd numeric:=0;

BEGIN

 strMessaggio:='Calcolo totale ordinativo per ord_id='||id_in||'.';

 select coalesce(sum(ordDetImp.ord_ts_det_importo),0) into totOrdinativo
 from siac_t_ordinativo_ts ordDet, siac_t_ordinativo_ts_det ordDetImp
 where ordDet.ord_id=id_in
 and ordDet.data_cancellazione is null and ordDet.validita_fine is null
 and ordDetImp.ord_ts_id=ordDet.ord_ts_id
 and ordDetImp.ord_ts_det_tipo_id=ordTsDetTipoId
 and ordDetImp.data_cancellazione is null and ordDetImp.validita_fine is null;

 /*for ordRecId in
 (select ordDet.ord_ts_id
  from siac_t_ordinativo_ts ordDet
  where ordDet.ord_id=id_in
    and ordDet.data_cancellazione is null and ordDet.validita_fine is null
 )
 loop
   curImportoOrd :=0;

   select coalesce(sum(ordDetImp.ord_ts_det_importo),0) into curImportoOrd
   from siac_t_ordinativo_ts_det ordDetImp
   where ordDetImp.ord_ts_id=ordRecId.ord_ts_id
     and ordDetImp.ord_ts_det_tipo_id=ordTsDetTipoId;


   totOrdinativo:=totOrdinativo+curImportoOrd;

 end loop;*/

 if mantieniDec=false then
	totOrdinativo :=trunc(totOrdinativo*100);
 end if;

 return totOrdinativo::varchar;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totOrdinativo:=0;
        return totOrdinativo::varchar;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totOrdinativo:=0;
        return totOrdinativo::varchar;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;