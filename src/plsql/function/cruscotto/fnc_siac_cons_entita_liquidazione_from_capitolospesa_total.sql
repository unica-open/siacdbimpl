/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (integer,varchar);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (integer,varchar,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (
  _capitolo_spesa_id integer,
  _anno varchar,
  _filtro_crp varchar  -- 29.06.2018 Sofia jira siac-6193 C,R,altro per tutto

)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT
	coalesce(count(*),0) into total
	from (
		select
			a.liq_id
		from
			siac_t_liquidazione a,
			siac_r_liquidazione_movgest b,
			siac_t_movgest_ts c,
			siac_t_movgest d,
			siac_r_movgest_bil_elem e,
			siac_t_bil_elem f,
			siac_t_bil g,
			siac_t_periodo h,
			siac_r_liquidazione_soggetto i,
			siac_t_soggetto l,
			siac_r_liquidazione_atto_amm m,
			siac_t_atto_amm n,
			siac_d_atto_amm_tipo o,
			siac_r_atto_amm_stato p,
			siac_d_atto_amm_stato q,
			siac_r_liquidazione_stato r,
			siac_d_liquidazione_stato s
		where a.liq_id=b.liq_id
		and c.movgest_ts_id=b.movgest_ts_id
		and d.movgest_id=c.movgest_id
        and (case when coalesce(_filtro_crp,'X')='R' then d.movgest_anno<_anno::integer
                  when coalesce(_filtro_crp,'X')='C' then d.movgest_anno=_anno::integer
                  else true end ) -- 29.06.2018 Sofia jira siac-6193
		and e.movgest_id=d.movgest_id
		and f.elem_id=e.elem_id
		and g.bil_id=f.bil_id
		and h.periodo_id=g.periodo_id
		and i.liq_id=a.liq_id
		and l.soggetto_id=i.soggetto_id
		and m.liq_id=a.liq_id
		and n.attoamm_id=m.attoamm_id
		and o.attoamm_tipo_id=n.attoamm_tipo_id
		and p.attoamm_id=n.attoamm_id
		and p.attoamm_stato_id=q.attoamm_stato_id
		and r.liq_id=a.liq_id
		and r.liq_stato_id=s.liq_stato_id
		and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
		and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
		and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
		and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
		and a.data_cancellazione is null
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and q.attoamm_stato_code<>'ANNULLATO'
		AND f.elem_id = _capitolo_spesa_id
		AND h.anno = _anno
	) as liq_id;

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;