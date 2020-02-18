/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  
  capitolo_anno integer,
  capitolo_numero integer,
  capitolo_articolo integer,
  
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar,
  -- 12.07.2018 Sofia jira siac-6193
  attoamm_oggetto varchar

) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	stringaTest character varying := 'stringa di test';
BEGIN

	RETURN QUERY
		with attoammsac as (
			with attoamm as (
				select g.movgest_id uid,
					g.movgest_anno accertamento_anno,
					g.movgest_numero accertamento_numero,
					g.movgest_desc accertamento_desc,
					m.movgest_stato_desc accertamento_stato_desc,
					n.movgest_ts_det_importo accertamento_importo,
					a.attoamm_numero,
					a.attoamm_anno,
					b.attoamm_tipo_code,
					b.attoamm_tipo_desc,
					d.attoamm_stato_desc,
					f.movgest_ts_id,
					a.attoamm_id,
					q.classif_code pdc_code,
					q.classif_desc pdc_desc,
                    -- 12.07.2018 Sofia jira siac-6193
                    a.attoamm_oggetto

				from siac_t_atto_amm a
				join siac_d_atto_amm_tipo b ON (b.attoamm_tipo_id=a.attoamm_tipo_id and b.data_cancellazione is null and a.data_cancellazione is null)
				join siac_r_atto_amm_stato c ON (c.attoamm_id=a.attoamm_id and c.data_cancellazione IS NULL and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now()))
				join siac_d_atto_amm_stato d on (d.attoamm_stato_id=c.attoamm_stato_id and d.data_cancellazione is null)
				join siac_r_movgest_ts_atto_amm e on (e.attoamm_id=a.attoamm_id and e.data_cancellazione is null and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now()))
				join siac_t_movgest_ts f ON (f.movgest_ts_id=e.movgest_ts_id and f.data_cancellazione is null)
				join siac_t_movgest g on (g.movgest_id=f.movgest_id and g.data_cancellazione is null)
				join siac_d_movgest_tipo h on (h.movgest_tipo_id=g.movgest_tipo_id and h.data_cancellazione is null)
				join siac_d_movgest_ts_tipo i on (i.movgest_ts_tipo_id=f.movgest_ts_tipo_id and i.data_cancellazione is null)
				join siac_r_movgest_ts_stato l on (l.movgest_ts_id=f.movgest_ts_id and l.data_cancellazione is null and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now()))
				join siac_d_movgest_stato m on (l.movgest_stato_id=m.movgest_stato_id and m.data_cancellazione is null)
				join siac_t_movgest_ts_det n on (n.movgest_ts_id=f.movgest_ts_id and n.data_cancellazione is null)
				join siac_d_movgest_ts_det_tipo o on (o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id and o.data_cancellazione is null)
				join siac_r_movgest_class p on (p.movgest_ts_id = f.movgest_ts_id and p.data_cancellazione is null and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine, now()))
				join siac_t_class q on (q.classif_id = p.classif_id and q.data_cancellazione is null)
				join siac_d_class_tipo r on (r.classif_tipo_id = q.classif_tipo_id and r.data_cancellazione is null)
				join siac_t_bil s on (s.bil_id = g.bil_id and s.data_cancellazione is null)
				join siac_t_periodo t on (t.periodo_id = s.periodo_id and t.data_cancellazione is null)
				where a.attoamm_id=_uid_provvedimento
				and h.movgest_tipo_code='A'
				and i.movgest_ts_tipo_code='T'
				and o.movgest_ts_det_tipo_code='A'
				and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
				and t.anno = _anno
			),
			sac as (
				select f.attoamm_id,
					g.classif_code,
					g.classif_desc
				from siac_r_atto_amm_class f
				join siac_t_class g on (f.classif_id=g.classif_id and g.data_cancellazione is null and f.data_cancellazione is null and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now()))
				join siac_d_class_tipo h on (h.classif_tipo_id=g.classif_tipo_id and h.data_cancellazione is null)
				where h.classif_tipo_code in ('CDR','CDC')
				and f.attoamm_id = _uid_provvedimento
			)
			select attoamm.uid,
				attoamm.accertamento_anno,
				attoamm.accertamento_numero,
				attoamm.accertamento_desc,
				attoamm.accertamento_stato_desc,
				attoamm.accertamento_importo,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				attoamm.movgest_ts_id,
				sac.classif_code attoamm_sac_code,
				sac.classif_desc attoamm_sac_desc,
				attoamm.pdc_code,
				attoamm.pdc_desc,
                -- 12.07.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto
			from attoamm
			left outer join sac on attoamm.attoamm_id=sac.attoamm_id
		),
		sogg as (
			select z.movgest_ts_id,
				y.soggetto_code,
				y.soggetto_desc
			from siac_r_movgest_ts_sog z
			join siac_t_soggetto y on (z.soggetto_id=y.soggetto_id and y.data_cancellazione is null and z.data_cancellazione is null and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now()))
		),
		cap as (
			select
				a1.movgest_id,
				b1.elem_code as capitolo_numero,
				b1.elem_code2 as capitolo_articolo,
				d1.anno as capitolo_anno
			from siac_r_movgest_bil_elem a1
			join siac_t_bil_elem b1 on (a1.elem_id = b1.elem_id and a1.data_cancellazione IS NULL AND b1.data_cancellazione IS NULL)
			join siac_t_bil c1 on (c1.bil_id = b1.bil_id and c1.data_cancellazione is null)
			join siac_t_periodo d1 on (d1.periodo_id = c1.periodo_id and d1.data_cancellazione is null)
			WHERE now() BETWEEN a1.validita_inizio AND COALESCE(a1.validita_fine, now())
		)
		select attoammsac.uid,
			attoammsac.accertamento_anno,
			attoammsac.accertamento_numero,
			attoammsac.accertamento_desc,
			attoammsac.accertamento_stato_desc,
			attoammsac.accertamento_importo,
			sogg.soggetto_code,
			sogg.soggetto_desc,
			cap.capitolo_anno::integer,
			cap.capitolo_numero::integer,
			cap.capitolo_articolo::integer,
			attoammsac.attoamm_numero,
			attoammsac.attoamm_anno,
			attoammsac.attoamm_tipo_code,
			attoammsac.attoamm_tipo_desc,
			attoammsac.attoamm_stato_desc,
			attoammsac.attoamm_sac_code,
			attoammsac.attoamm_sac_desc,
			attoammsac.pdc_code,
			attoammsac.pdc_desc,
            -- 12.07.2018 Sofia jira siac-6193
            attoammsac.attoamm_oggetto
		from attoammsac
		left outer join sogg on attoammsac.movgest_ts_id=sogg.movgest_ts_id
		left outer join cap on attoammsac.uid = cap.movgest_id
		order by attoammsac.accertamento_anno,
			attoammsac.accertamento_numero
		LIMIT _limit
		OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;