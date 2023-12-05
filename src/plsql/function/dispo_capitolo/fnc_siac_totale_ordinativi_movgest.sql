/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*drop FUNCTION fnc_siac_totale_ordinativi_movgest (
  movgest_id_in integer,
  movgest_ts_id_in integer)*/

CREATE OR REPLACE FUNCTION fnc_siac_totale_ordinativi_movgest (
  movgest_id_in integer,
  movgest_ts_id_in integer,
  out totOrdinativi numeric
)
RETURNS numeric AS
$body$
DECLARE

-- constant
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

--totOrdinativi numeric:=0;

curImportoOrd numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN

 strMessaggio:='Calcolo totale ordinativi per movgest_id_in='||movgest_id_in||'.';
 totOrdinativi:=0;

 if movgest_ts_id_in is not null then
 	strMessaggio:=strMessaggio||'Per movgest_ts_id_in='||movgest_ts_id_in||'.';
 end if;

 if movgest_ts_id_in is null then -- pagato,incasso su impegno/accertamento compresi tutti sub
    select coalesce(sum(det.ord_ts_det_importo),0) into curImportoOrd
    from siac_t_movgest_ts mov,siac_r_movgest_ts_stato rmstato, siac_d_movgest_stato statom,
         siac_r_liquidazione_movgest r,
         siac_r_liquidazione_ord ro,
         siac_t_ordinativo_ts ts, siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato,
         siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo dettipo
    where mov.movgest_id=movgest_id_in
    and   rmstato.movgest_ts_id=mov.movgest_ts_id
    and   statom.movgest_stato_id=rmstato.movgest_stato_id
    and   statom.movgest_stato_code!=STATO_A
    and   r.movgest_ts_id=mov.movgest_ts_id
    and   ro.liq_id=r.liq_id
    and   ts.ord_ts_id=ro.sord_id
    and   rs.ord_id=ts.ord_id
    and   stato.ord_stato_id=rs.ord_stato_id
    and   stato.ord_stato_code<>STATO_A
    and   det.ord_ts_id=ts.ord_ts_id
    and   dettipo.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
    and   dettipo.ord_ts_det_tipo_code=IMPORTO_ATT
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   rmstato.data_cancellazione is null
    and   rmstato.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   ro.data_cancellazione is null
    and   ro.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null;
 else -- pagato/incassato su impegno/accertamento o su un sub
    select coalesce(sum(det.ord_ts_det_importo),0) into curImportoOrd
    from siac_t_movgest_ts mov,siac_r_movgest_ts_stato rmstato, siac_d_movgest_stato statom,
         siac_r_liquidazione_movgest r,
         siac_r_liquidazione_ord ro,
         siac_t_ordinativo_ts ts, siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato,
         siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo dettipo
    where mov.movgest_ts_id=movgest_ts_id_in
    and   rmstato.movgest_ts_id=mov.movgest_ts_id
    and   statom.movgest_stato_id=rmstato.movgest_stato_id
    and   statom.movgest_stato_code!=STATO_A
    and   r.movgest_ts_id=mov.movgest_ts_id
    and   ro.liq_id=r.liq_id
    and   ts.ord_ts_id=ro.sord_id
    and   rs.ord_id=ts.ord_id
    and   stato.ord_stato_id=rs.ord_stato_id
    and   stato.ord_stato_code<>STATO_A
    and   det.ord_ts_id=ts.ord_ts_id
    and   dettipo.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
    and   dettipo.ord_ts_det_tipo_code=IMPORTO_ATT
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   rmstato.data_cancellazione is null
    and   rmstato.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   ro.data_cancellazione is null
    and   ro.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null;

 end if;

 if curImportoOrd is not null then
	 totOrdinativi:=curImportoOrd;
 end if;

 return;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totOrdinativi:=0;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totOrdinativi:=0;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;