/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_res_attivo (
  movgest_ts_id_in integer,
  ente_proprietario_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
residuoattivo numeric;
residuoattivo_sub numeric;
residuoattivo_new numeric;
BEGIN



residuoattivo :=0.0; 
residuoattivo_sub :=0.0;


select sum(importo_ord.ord_ts_det_importo) into residuoattivo 
from siac_t_movgest movgest,
     siac_t_movgest_ts ts, 
     siac_r_ordinativo_ts_movgest_ts r_ordinativo_ts,
     siac_t_ordinativo_ts ordinativo,
     siac_t_ordinativo_ts_det  importo_ord,
     siac_d_ordinativo_ts_det_tipo tipo_importo_ord,
     siac_r_ordinativo_stato r_ord_stato, siac_d_ordinativo_stato ord_stato
where 
movgest.ente_proprietario_id = ente_proprietario_id_in and
movgest.movgest_id = ts.movgest_id and
      r_ordinativo_ts.movgest_ts_id = ts.movgest_ts_id and
      ordinativo.ord_ts_id=r_ordinativo_ts.ord_ts_id and
      importo_ord.ord_ts_id = ordinativo.ord_ts_id and
      tipo_importo_ord.ord_ts_det_tipo_id=importo_ord.ord_ts_det_tipo_id and 
      tipo_importo_ord.ord_ts_det_tipo_code='A' and-- importo attuale
      r_ord_stato.ord_id=ordinativo.ord_id and
      ord_stato.ord_stato_id=r_ord_stato.ord_stato_id and 
      now() BETWEEN r_ord_stato.validita_inizio and COALESCE (r_ord_stato.validita_fine,now()) and 
      ord_stato.ord_stato_code<>'A' and
      movgest.data_cancellazione is NULL and 
      ts.data_cancellazione is NULL and  
      r_ordinativo_ts.data_cancellazione is NULL and 
      ordinativo.data_cancellazione is NULL and 
      importo_ord.data_cancellazione is NULL and 
      tipo_importo_ord.data_cancellazione is NULL and 
      r_ord_stato.data_cancellazione is NULL and 
      ord_stato.data_cancellazione is NULL      
      and ts.movgest_ts_id = movgest_ts_id_in;



select sum(importo_ord.ord_ts_det_importo) into residuoattivo_sub
from siac_t_movgest movgest,
     siac_t_movgest_ts ts, 
     siac_r_ordinativo_ts_movgest_ts r_ordinativo_ts,
     siac_t_ordinativo_ts ordinativo,
     siac_t_ordinativo_ts_det  importo_ord,
     siac_d_ordinativo_ts_det_tipo tipo_importo_ord,
     siac_r_ordinativo_stato r_ord_stato, siac_d_ordinativo_stato ord_stato
where 
movgest.ente_proprietario_id = ente_proprietario_id_in and
movgest.movgest_id = ts.movgest_id and
      r_ordinativo_ts.movgest_ts_id = ts.movgest_ts_id and
      ordinativo.ord_ts_id=r_ordinativo_ts.ord_ts_id and
      importo_ord.ord_ts_id = ordinativo.ord_ts_id and
      tipo_importo_ord.ord_ts_det_tipo_id=importo_ord.ord_ts_det_tipo_id and 
      tipo_importo_ord.ord_ts_det_tipo_code='A' and-- importo attuale
      r_ord_stato.ord_id=ordinativo.ord_id and
      ord_stato.ord_stato_id=r_ord_stato.ord_stato_id and 
      now() BETWEEN r_ord_stato.validita_inizio and COALESCE (r_ord_stato.validita_fine,now()) and 
      ord_stato.ord_stato_code<>'A' and
      movgest.data_cancellazione is NULL and 
      ts.data_cancellazione is NULL and  
      r_ordinativo_ts.data_cancellazione is NULL and 
      ordinativo.data_cancellazione is NULL and 
      importo_ord.data_cancellazione is NULL and 
      tipo_importo_ord.data_cancellazione is NULL and 
      r_ord_stato.data_cancellazione is NULL and 
      ord_stato.data_cancellazione is NULL      
      and ts.movgest_ts_id_padre = movgest_ts_id_in;



if residuoattivo is null then residuoattivo:=0; end if;

if residuoattivo_sub is null then residuoattivo_sub:=0; end if;



select a.movgest_ts_det_importo - residuoattivo - residuoattivo_sub into residuoattivo_new
from siac_t_movgest_ts_det a,siac_d_movgest_ts_det_tipo b 
where a.movgest_ts_id=movgest_ts_id_in
and a.ente_proprietario_id = ente_proprietario_id_in
and a.data_cancellazione is NULL
and b.movgest_ts_det_tipo_id=a.movgest_ts_det_tipo_id
and b.movgest_ts_det_tipo_code='A'
and b.data_cancellazione is NULL;

residuoattivo:=residuoattivo_new;

return residuoattivo;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;