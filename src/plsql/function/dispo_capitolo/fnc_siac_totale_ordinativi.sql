/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_totale_ordinativi (
  id_in integer,
  tipo_ord_in varchar
)
RETURNS numeric AS
$body$
DECLARE

-- constant
/*TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_EG constant varchar:='CAP-EG';*/
NVL_STR     constant varchar:='';

TIPO_ORD_P constant varchar:='P';
TIPO_ORD_I constant varchar:='I';

STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

tipoCapitolo varchar(10):=null;
strMessaggio varchar(1500):=NVL_STR;
totOrdinativi numeric:=0;

ordTipoId integer:=0;
enteProprietarioId integer :=0;
ordTsDetTipoId integer:=0;
ordStatoId integer:=0;
bilancioId integer:=0;
ordTsId integer:=0;

ordRecId record;
curImportoOrd numeric:=0;

BEGIN

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.';

/*
 if tipo_ord_in = TIPO_ORD_P then
 	  tipoCapitolo:=TIPO_CAP_UG;
 else tipoCapitolo:=TIPO_CAP_EG;
 end if;*/

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.Lettura enteProprietarioId.';

/* select bilElem.ente_proprietario_id, bilElem.bil_id
        into strict enteProprietarioId, bilancioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bilElem.validita_fine is null
 and   bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
 and   bilElemTipo.elem_tipo_code=tipoCapitolo;

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.Lettura ordTipoId per ord_tipo='||tipo_ord_in||'.';
 select ordTipo.ord_tipo_id into strict ordTipoId
 from siac_d_ordinativo_tipo ordTipo
 where ordTipo.ente_proprietario_id=enteProprietarioId
 and ordTipo.ord_tipo_code=tipo_ord_in;

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.Lettura ordTsDetTipoId per ordTsDetTipo='||IMPORTO_ATT||'.';
 select ordDetImpTipo.ord_ts_det_tipo_id into strict ordTsDetTipoId
 from siac_d_ordinativo_ts_det_tipo ordDetImpTipo
 where ordDetImpTipo.ente_proprietario_id=enteProprietarioId and
       ordDetImpTipo.ord_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.Lettura ordStatoId per ordStato='||STATO_A||'.';
 select  statoOrd.ord_stato_id into strict ordStatoId
 from siac_d_ordinativo_stato  statoOrd
 where statoOrd.ente_proprietario_id=enteProprietarioId
 and   statoOrd.ord_stato_code = STATO_A;

 strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in||'.Inizio ciclo.';
 for ordRecId in
 select ordBilElemRel.ord_id
  from siac_r_ordinativo_bil_elem ordBilElemRel,
  siac_t_ordinativo ord
  where ordBilElemRel.elem_id=id_in -- ordintativi di elem_id passato
  and ord.ord_id=ordBilElemRel.ord_id
  and   ord.bil_id=bilancioId
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   ord.ord_tipo_id=ordTipoId
  and   ordBilElemRel.data_cancellazione is null
  and   ord.data_cancellazione is null  
  and   now() between ord.validita_inizio and COALESCE(ord.validita_fine,now())
  and   now() between ordBilElemRel.validita_inizio and COALESCE(ordBilElemRel.validita_fine,now())
 */
/* (select ordBilElemRel.ord_id
  from siac_r_ordinativo_bil_elem ordBilElemRel
  where ordBilElemRel.elem_id=id_in -- ordintativi di elem_id passato
  and   ordBilElemRel.data_cancellazione is null
  and   ordBilElemRel.validita_fine is null
  and   exists (select 1
			    from siac_t_ordinativo ord
                where ord.ord_id=ordBilElemRel.ord_id
                and   ord.bil_id=bilancioId
                and   ord.data_cancellazione is null
                and   ord.validita_fine is null
                and   ord.ord_tipo_id=ordTipoId) -- ordinativi di un ordTipoId e di un bilancioId
 )
*/
--loop

   curImportoOrd :=0;
   
   select coalesce(sum(d.ord_ts_det_importo),0) into curImportoOrd
   from 
siac_r_ordinativo_bil_elem a, siac_t_ordinativo b, siac_t_ordinativo_ts c,
siac_t_ordinativo_ts_det d,siac_r_ordinativo_stato e,siac_d_ordinativo_stato f
, siac_d_ordinativo_tipo g,
siac_d_ordinativo_ts_det_tipo h
where a.ord_id=b.ord_id
and c.ord_id=b.ord_id
and d.ord_ts_id=c.ord_ts_id
and e.ord_id=b.ord_id
and e.ord_stato_id=f.ord_stato_id
and f.ord_stato_code<>STATO_A
and g.ord_tipo_id=b.ord_tipo_id
and g.ord_tipo_code=tipo_ord_in
and a.elem_id=id_in
and h.ord_ts_det_tipo_id=d.ord_ts_det_tipo_id
and h.ord_ts_det_tipo_code=IMPORTO_ATT
and   now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and   now() between e.validita_inizio and COALESCE(e.validita_fine,now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null;

  /* strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in
                ||'.Lettura siac_t_ordinativo_ts per ord_id='||ordRecId.ord_id||'.Stato non annullato.';
   select ordDet.ord_ts_id into ordTsId
   from siac_t_ordinativo_ts ordDet
   where  ordDet.ord_id=ordRecId.ord_id
   and    ordDet.data_cancellazione is null and ordDet.validita_fine is null
   and    exists (select 1
                  from siac_r_ordinativo_stato statoOrdRel
                  where statoOrdRel.ord_id=ordDet.ord_id
                  and   statoOrdRel.ord_stato_id!=ordStatoId
                  and   statoOrdRel.data_cancellazione is null
                  and   statoOrdRel.validita_fine is null); -- ordinativi non annullati

   strMessaggio:='Calcolo totale ordinativi per elem_id='||id_in
                ||'.Sum  siac_t_ordinativo_ts_det per ord_id='||ordRecId.ord_id||'.';
   if NOT FOUND then
   else
    select coalesce(sum(ordDetImp.ord_ts_det_importo),0) into curImportoOrd
    from siac_t_ordinativo_ts_det ordDetImp
    where ordDetImp.ord_ts_id=ordTsId
    and   ordDetImp.ord_ts_det_tipo_id=ordTsDetTipoId;
   end if;*/


   totOrdinativi:=totOrdinativi+curImportoOrd;

 --end loop;

 /* mancava filtro per bilancioId
 select coalesce(sum (ordDetImp.ord_ts_det_importo),0) into strict totOrdinativi
 from siac_t_ordinativo ord, siac_t_ordinativo_ts ordDet,
 	  siac_t_ordinativo_ts_det ordDetImp,siac_d_ordinativo_ts_det_tipo ordDetImpTipo,
 	  siac_d_ordinativo_stato statoOrd, siac_r_ordinativo_stato statoOrdRel,
      siac_d_ordinativo_tipo ordTipo,
 	  siac_t_bil_elem bilElem , siac_d_bil_elem_tipo bilElemTipo,siac_r_ordinativo_bil_elem ordBilElemRel
 where  bilElem.elem_id = id_in and
	    bilElem.data_cancellazione is null and bilElem.validita_fine is null and
        bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id and
        bilElemTipo.ente_proprietario_id=bilElem.ente_proprietario_id and
        bilElemTipo.elem_tipo_code =tipoCapitolo and
        ordBilElemRel.elem_id=bilElem.elem_id and
        ordBilElemRel.ente_proprietario_id=bilElem.ente_proprietario_id and
        ordBilElemRel.data_cancellazione is null and ordBilElemRel.validita_fine is null and
        ord.ord_id=ordBilElemRel.ord_id AND
        ord.data_cancellazione is null and ord.validita_fine is null and
        ord.ente_proprietario_id=ordBilElemRel.ente_proprietario_id and
        ordTipo.ord_tipo_id=ord.ord_tipo_id and
        ordTipo.ente_proprietario_id=ord.ente_proprietario_id and
        ordTipo.ord_tipo_code=tipo_ord_in and
        statoOrdRel.ord_id = ord.ord_id and
        statoOrdRel.data_cancellazione is null and statoOrdRel.validita_fine is null and
        statoOrdRel.ente_proprietario_id=ord.ente_proprietario_id AND
        statoOrd.ord_stato_id=statoOrdRel.ord_stato_id and
        statoOrd.ente_proprietario_id=statoOrdRel.ente_proprietario_id and
        statoOrd.ord_stato_code != STATO_A and
        ordDet.ord_id=ord.ord_id and
        ordDet.data_cancellazione is null and ordDet.validita_fine is null and
        ordDetImp.ord_ts_id=ordDet.ord_ts_id and
        ordDetImp.data_cancellazione is null and ordDetImp.validita_fine is null and
        ordDetImpTipo.ord_ts_det_tipo_id=ordDetImp.ord_ts_det_tipo_id and
        ordDetImpTipo.ente_proprietario_id=ordDetImp.ente_proprietario_id and
        ordDetImpTipo.ord_ts_det_tipo_code=IMPORTO_ATT;*/



 return totOrdinativi;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totOrdinativi:=0;
        return totOrdinativi;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totOrdinativi:=0;
        return totOrdinativi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;