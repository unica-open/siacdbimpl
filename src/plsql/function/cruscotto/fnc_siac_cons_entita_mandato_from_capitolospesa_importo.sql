/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop function fnc_siac_cons_entita_mandato_from_capitolospesa_importo (integer);
drop function fnc_siac_cons_entita_mandato_from_capitolospesa_importo (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa_importo (
  _uid_capitolospesa integer,
  _filtro_crp varchar  -- 03.07.2018 Sofia jira siac-6193 C,R,altro per tutto
)
RETURNS numeric AS
$body$
DECLARE
	total numeric;
BEGIN

	SELECT coalesce(sum(ord_imp.importo),0)
	into total
	from (
          SELECT siac_t_ordinativo_ts_det.ord_ts_det_importo as importo
          from
              siac_r_ordinativo_bil_elem --r,
              ,siac_t_bil_elem --s,
              ,siac_t_ordinativo --y,
              ,siac_d_ordinativo_tipo --i

              ,siac_r_ordinativo_stato --d,
              ,siac_d_ordinativo_stato --e,
              ,siac_t_ordinativo_ts --f,
              ,siac_t_ordinativo_ts_det --g,
              ,siac_d_ordinativo_ts_det_tipo --h
              -- 03.07.2018 Sofia jira siac-6193
              ,siac_r_liquidazione_ord rord
              ,siac_r_liquidazione_movgest rmov
              ,siac_t_movgest_ts tsmov
              ,siac_t_movgest mov

          where
              siac_t_bil_elem.elem_id=siac_r_ordinativo_bil_elem.elem_id
          and siac_t_ordinativo.ord_id=siac_r_ordinativo_bil_elem.ord_id
          and siac_t_bil_elem.elem_id= _uid_capitolospesa
          and siac_d_ordinativo_tipo.ord_tipo_id=siac_t_ordinativo.ord_tipo_id
          and siac_d_ordinativo_tipo.ord_tipo_code='P'
          and siac_r_ordinativo_bil_elem.data_cancellazione is null
          and siac_t_bil_elem.data_cancellazione is null
          and siac_d_ordinativo_tipo.data_cancellazione is null
          and now() BETWEEN siac_r_ordinativo_bil_elem.validita_inizio and coalesce (siac_r_ordinativo_bil_elem.validita_fine,now())
		  and siac_t_ordinativo.data_cancellazione is null
          and siac_r_ordinativo_stato.ord_id=siac_t_ordinativo.ord_id
          and siac_r_ordinativo_stato.ord_stato_id=siac_d_ordinativo_stato.ord_stato_id
          and now() BETWEEN siac_r_ordinativo_stato.validita_inizio and COALESCE(siac_r_ordinativo_stato.validita_fine,now())
          and siac_t_ordinativo_ts.ord_id=siac_t_ordinativo.ord_id
          and siac_t_ordinativo_ts_det.ord_ts_id=siac_t_ordinativo_ts.ord_ts_id
          and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id=siac_t_ordinativo_ts_det.ord_ts_det_tipo_id
          and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
          -- 03.07.2018 Sofia jira siac-6193
          and rord.sord_id=siac_t_ordinativo_ts.ord_ts_id
          and rmov.liq_id=rord.liq_id
          and tsmov.movgest_ts_id=rmov.movgest_ts_id
          and mov.movgest_id=tsmov.movgest_id
          and ( case when coalesce(_filtro_crp,'')='C' then mov.movgest_anno::integer=siac_t_ordinativo.ord_anno::integer
                     when coalesce(_filtro_crp,'')='R' then mov.movgest_anno::integer<siac_t_ordinativo.ord_anno::integer
                     else true end )
          and siac_t_ordinativo.data_cancellazione is null
          and siac_r_ordinativo_stato.data_cancellazione is null
          and siac_d_ordinativo_stato.data_cancellazione is null
          and siac_t_ordinativo_ts.data_cancellazione is null
          and siac_t_ordinativo_ts_det.data_cancellazione is null
           -- 03.07.2018 Sofia jira siac-6193
          and rord.data_cancellazione is null
          and rord.validita_fine is null
          and rmov.data_cancellazione is null
          and rmov.validita_fine is null
          and tsmov.data_cancellazione is null
          and tsmov.validita_fine is null
          and mov.data_cancellazione is null
          and mov.validita_fine is null
	)
  	as ord_imp ;

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;