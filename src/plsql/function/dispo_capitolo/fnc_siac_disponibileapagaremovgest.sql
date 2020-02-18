/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibileapagaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
disponibileapagare numeric;
disponibileapagare_sub numeric;
disponibileapagare_new numeric;
BEGIN



disponibileapagare :=0.0; 
disponibileapagare_sub :=0.0;


select sum(g.ord_ts_det_importo) into disponibileapagare 
 --s.movgest_ts_code
from siac_t_movgest a,
     siac_t_movgest_ts b, 
     siac_r_liquidazione_movgest c,
     siac_t_liquidazione d,
     siac_r_liquidazione_ord e,
     siac_t_ordinativo_ts f,
     siac_t_ordinativo_ts_det  g,
     siac_d_ordinativo_ts_det_tipo h,
     siac_r_ordinativo_stato i, siac_d_ordinativo_stato l
where 
a.movgest_id = b.movgest_id and
      c.movgest_ts_id = b.movgest_ts_id and
      d.liq_id = c.liq_id and
      e.liq_id = d.liq_id and
      f.ord_ts_id=e.sord_id and
      g.ord_ts_id = f.ord_ts_id and
      h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id and 
      h.ord_ts_det_tipo_code='A' and-- importo attuale
      now() BETWEEN d.validita_inizio and COALESCE (d.validita_fine,now()) and 
      i.ord_id=f.ord_id and
      l.ord_stato_id=i.ord_stato_id and 
      now() BETWEEN i.validita_inizio and COALESCE (i.validita_fine,now()) and 
      l.ord_stato_code<>'A' and
      a.data_cancellazione is NULL and 
      b.data_cancellazione is NULL and 
      c.data_cancellazione is NULL and 
      d.data_cancellazione is NULL and 
      e.data_cancellazione is NULL and 
      f.data_cancellazione is NULL and 
      g.data_cancellazione is NULL and 
      h.data_cancellazione is NULL and 
      i.data_cancellazione is NULL and 
      l.data_cancellazione is NULL      
      and b.movgest_ts_id = movgest_ts_id_in ; --11890 -- id movgest da parametrizzare
      -- aggiungere la ricerca e la IF su stato ordinativo
/*group by 
a.movgest_id;*/


select sum(g.ord_ts_det_importo) into disponibileapagare_sub 
 --s.movgest_ts_code
from siac_t_movgest a,
     siac_t_movgest_ts b, 
     siac_r_liquidazione_movgest c,
     siac_t_liquidazione d,
     siac_r_liquidazione_ord e,
     siac_t_ordinativo_ts f,
     siac_t_ordinativo_ts_det  g,
     siac_d_ordinativo_ts_det_tipo h,
     siac_r_ordinativo_stato i, siac_d_ordinativo_stato l
where 
a.movgest_id = b.movgest_id and
      c.movgest_ts_id = b.movgest_ts_id and
      d.liq_id = c.liq_id and
      e.liq_id = d.liq_id and
      f.ord_ts_id=e.sord_id and
      g.ord_ts_id = f.ord_ts_id and
      h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id and 
      h.ord_ts_det_tipo_code='A' and-- importo attuale
      now() BETWEEN d.validita_inizio and COALESCE (d.validita_fine,now()) and 
      i.ord_id=f.ord_id and
      l.ord_stato_id=i.ord_stato_id and 
      now() BETWEEN i.validita_inizio and COALESCE (i.validita_fine,now()) and 
      l.ord_stato_code<>'A' and
      a.data_cancellazione is NULL and 
      b.data_cancellazione is NULL and 
      c.data_cancellazione is NULL and 
      d.data_cancellazione is NULL and 
      e.data_cancellazione is NULL and 
      f.data_cancellazione is NULL and 
      g.data_cancellazione is NULL and 
      h.data_cancellazione is NULL and 
      i.data_cancellazione is NULL and 
      l.data_cancellazione is NULL      
      and b.movgest_ts_id_padre =movgest_ts_id_in;



if disponibileapagare is null then disponibileapagare:=0; end if;

if disponibileapagare_sub is null then disponibileapagare_sub:=0; end if;



select a.movgest_ts_det_importo - disponibileapagare - disponibileapagare_sub into disponibileapagare_new
from siac_t_movgest_ts_det a,siac_d_movgest_ts_det_tipo b where a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is NULL
and b.movgest_ts_det_tipo_id=a.movgest_ts_det_tipo_id
and b.movgest_ts_det_tipo_code='A'
and b.data_cancellazione is NULL;

disponibileapagare:=disponibileapagare_new;

return disponibileapagare;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;