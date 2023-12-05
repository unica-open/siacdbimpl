/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5152 - INIZIO

-- fnc_siac_cons_entita_accertamento_from_capitoloentrata_total
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (
  _uid_capitoloentrata integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_t_bil m,
		siac_t_periodo n
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.bil_id = c.bil_id
	and n.periodo_id = m.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
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
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and a.elem_id=_uid_capitoloentrata
	and n.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_accertamento_from_capitoloentrata
-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata (
  _uid_capitoloentrata integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  soggetto_code varchar,
  soggetto_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero,
			c.movgest_desc,
			f.movgest_ts_det_importo,
			l.movgest_stato_desc,
			c.movgest_id,
			n.classif_code pdc_code,
			n.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_class m,
			siac_t_class n,
			siac_d_class_tipo o,
			siac_t_bil p,
			siac_t_periodo q
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and l.movgest_stato_id=i.movgest_stato_id
		and i.movgest_ts_id=e.movgest_ts_id
		and m.movgest_ts_id = e.movgest_ts_id
		and n.classif_id = m.classif_id
		and o.classif_tipo_id = n.classif_tipo_id
		and p.bil_id = c.bil_id
		and q.periodo_id = p.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
		and d.movgest_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and h.movgest_ts_det_tipo_code='A'
		and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and a.elem_id=_uid_capitoloentrata
		and q.anno = _anno
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;

			--classe di soggetti
			if soggetto_code is null then

				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc
			from
				siac_r_movgest_ts_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;

		end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_accertamento_from_provvedimento_total
-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total BIGINT;
BEGIN
			
	SELECT COALESCE(COUNT(*),0) INTO total
	FROM siac_t_atto_amm a,
		siac_d_atto_amm_tipo b,
		siac_r_atto_amm_stato c,
		siac_d_atto_amm_stato d,
		siac_r_movgest_ts_atto_amm e,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	WHERE b.attoamm_tipo_id=a.attoamm_tipo_id
	AND c.attoamm_id=a.attoamm_id
	AND d.attoamm_stato_id=c.attoamm_stato_id
	AND e.attoamm_id=a.attoamm_id
	AND f.movgest_ts_id=e.movgest_ts_id
	AND g.movgest_id=f.movgest_id
	AND h.movgest_tipo_id=g.movgest_tipo_id
	AND i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	AND l.movgest_ts_id=f.movgest_ts_id
	AND l.movgest_stato_id=m.movgest_stato_id
	AND n.movgest_ts_id=f.movgest_ts_id
	AND o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	AND p.bil_id = g.bil_id
	AND q.periodo_id = p.periodo_id
	AND now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine,now())
	AND now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine,now())
	AND now() BETWEEN l.validita_inizio AND COALESCE(l.validita_fine,now())
	AND p.data_cancellazione IS NULL
	AND q.data_cancellazione IS NULL
	AND a.data_cancellazione IS NULL
	AND b.data_cancellazione IS NULL
	AND c.data_cancellazione IS NULL
	AND d.data_cancellazione IS NULL
	AND e.data_cancellazione IS NULL
	AND f.data_cancellazione IS NULL
	AND g.data_cancellazione IS NULL
	AND h.data_cancellazione IS NULL
	AND i.data_cancellazione IS NULL
	AND l.data_cancellazione IS NULL
	AND m.data_cancellazione IS NULL
	AND n.data_cancellazione IS NULL
	AND o.data_cancellazione IS NULL  
	AND h.movgest_tipo_code='A'
	AND i.movgest_ts_tipo_code='T'
	AND o.movgest_ts_det_tipo_code='A'
	AND a.attoamm_id=_uid_provvedimento
	AND q.anno = _anno;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_accertamento_from_provvedimento

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
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
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
					q.classif_desc pdc_desc
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
				attoamm.pdc_desc
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
			cap.capitolo_anno,
			cap.capitolo_numero,
			cap.capitolo_articolo,
			attoammsac.attoamm_numero,
			attoammsac.attoamm_anno,
			attoammsac.attoamm_tipo_code,
			attoammsac.attoamm_tipo_desc,
			attoammsac.attoamm_stato_desc,
			attoammsac.attoamm_sac_code,
			attoammsac.attoamm_sac_desc,
			attoammsac.pdc_code,
			attoammsac.pdc_desc
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

-- fnc_siac_cons_entita_accertamento_from_soggetto_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*), 0)
	into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_ts_sog m,
		siac_t_soggetto n,
		siac_t_bil o,
		siac_t_periodo p
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id 
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id=e.movgest_ts_id
	and n.soggetto_id=m.soggetto_id
	and o.bil_id = c.bil_id
	and p.periodo_id = o.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and m.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and n.soggetto_id=_uid_soggetto
	and p.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_accertamento_from_soggetto

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  soggetto_code varchar,
  soggetto_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero  ,
			c.movgest_desc ,
			f.movgest_ts_det_importo ,
			l.movgest_stato_desc,
			c.movgest_id,
			n.soggetto_code,
			n.soggetto_desc,
			p.classif_code pdc_code,
			p.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_ts_sog m,
			siac_t_soggetto n,
			siac_r_movgest_class o,
			siac_t_class p,
			siac_d_class_tipo q,
			siac_t_bil r,
			siac_t_periodo s
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id 
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and i.movgest_ts_id=e.movgest_ts_id
		and l.movgest_stato_id=i.movgest_stato_id
		and m.movgest_ts_id=e.movgest_ts_id
		and n.soggetto_id=m.soggetto_id
		and o.movgest_ts_id=e.movgest_ts_id
		and p.classif_id=o.classif_id
		and q.classif_tipo_id=p.classif_tipo_id
		and r.bil_id = c.bil_id
		and s.periodo_id = r.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
		and m.data_cancellazione is null
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
		and d.movgest_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and h.movgest_ts_det_tipo_code='A'
		and q.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and n.soggetto_id=_uid_soggetto
		and s.anno = _anno
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset
		
		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			soggetto_code:=rec.soggetto_code;
			soggetto_desc:=rec.soggetto_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;
			
			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio 
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;
			
			--classe di soggetti
			if soggetto_code is null then
			
				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;
			
			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc
			from
				siac_r_movgest_ts_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;
			
			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;
		end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_impegno_from_capitolospesa_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (
  _uid_capitolospesa integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_t_bil m,
		siac_t_periodo n
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.bil_id = c.bil_id
	and n.periodo_id = m.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
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
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and a.elem_id=_uid_capitolospesa
	and n.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_impegno_from_capitolospesa

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa (
  _uid_capitolospesa integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc
				from (
					with za as (
						select
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.soggetto_code zzz_soggetto_code,
							zzz.soggetto_desc zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=_uid_capitolospesa
								and t.anno = _anno
							),
							soggetto as (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzz
					),
					zb as (
						select
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
								select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sogclasse h,
									siac_r_soggetto_classe i,
									siac_d_soggetto_classe l
								where g.soggetto_id=i.soggetto_id
								and h.soggetto_classe_id=l.soggetto_classe_id
								and i.soggetto_classe_id=l.soggetto_classe_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
								and now() between i.validita_inizio and coalesce(i.validita_fine, now())
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),
			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_movgest_ts_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc
			from imp_sogg
			left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero
		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_impegno_from_provvedimento_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*),0) into total
	from
		siac_t_atto_amm a,
		siac_d_atto_amm_tipo b,
		siac_r_atto_amm_stato c,
		siac_d_atto_amm_stato d,
		siac_r_movgest_ts_atto_amm e,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_r_movgest_class p,
		siac_t_class q,
		siac_d_class_tipo r,
		siac_t_bil s,
		siac_t_periodo t
	where b.attoamm_tipo_id=a.attoamm_tipo_id
	and c.attoamm_id=a.attoamm_id
	and d.attoamm_stato_id=c.attoamm_stato_id
	and e.attoamm_id=a.attoamm_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_id=f.movgest_id
	and h.movgest_tipo_id=g.movgest_tipo_id
	and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	and l.movgest_ts_id=f.movgest_ts_id
	and l.movgest_stato_id=m.movgest_stato_id
	and n.movgest_ts_id=f.movgest_ts_id
	and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	and p.movgest_ts_id = f.movgest_ts_id
	and q.classif_id = p.classif_id
	and r.classif_tipo_id = q.classif_tipo_id
	and s.bil_id = g.bil_id
	and t.periodo_id = s.periodo_id
	and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
	and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
	and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
	and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
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
	and t.data_cancellazione is null
	and h.movgest_tipo_code='I'
	and i.movgest_ts_tipo_code='T'
	and o.movgest_ts_det_tipo_code='A'
	and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.attoamm_id=_uid_provvedimento
	and t.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_impegno_from_provvedimento

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_provvedimento (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with attoammsac as (
			with attoamm as (
				select
					g.movgest_id uid,
					g.movgest_anno  impegno_anno,
					g.movgest_numero impegno_numero,
					g.movgest_desc impegno_desc,
					m.movgest_stato_desc impegno_stato,
					n.movgest_ts_det_importo impegno_importo,
					a.attoamm_numero,
					a.attoamm_anno,
					b.attoamm_tipo_code,
					b.attoamm_tipo_desc,
					d.attoamm_stato_desc,
					f.movgest_ts_id,
					a.attoamm_id,
					q.classif_code pdc_code,
					q.classif_desc pdc_desc
				from
					siac_t_atto_amm a,
					siac_d_atto_amm_tipo b,
					siac_r_atto_amm_stato c,
					siac_d_atto_amm_stato d,
					siac_r_movgest_ts_atto_amm e,
					siac_t_movgest_ts f,
					siac_t_movgest g,
					siac_d_movgest_tipo h,
					siac_d_movgest_ts_tipo i,
					siac_r_movgest_ts_stato l,
					siac_d_movgest_stato m,
					siac_t_movgest_ts_det n,
					siac_d_movgest_ts_det_tipo o,
					siac_r_movgest_class p,
					siac_t_class q,
					siac_d_class_tipo r,
					siac_t_bil s,
					siac_t_periodo t
				where b.attoamm_tipo_id=a.attoamm_tipo_id
				and c.attoamm_id=a.attoamm_id
				and d.attoamm_stato_id=c.attoamm_stato_id
				and e.attoamm_id=a.attoamm_id
				and f.movgest_ts_id=e.movgest_ts_id
				and g.movgest_id=f.movgest_id
				and h.movgest_tipo_id=g.movgest_tipo_id
				and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
				and l.movgest_ts_id=f.movgest_ts_id
				and l.movgest_stato_id=m.movgest_stato_id
				and n.movgest_ts_id=f.movgest_ts_id
				and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
				and p.movgest_ts_id = f.movgest_ts_id
				and q.classif_id = p.classif_id
				and r.classif_tipo_id = q.classif_tipo_id
				and s.bil_id = g.bil_id
				and t.periodo_id = s.periodo_id
				and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
				and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
				and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
				and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
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
				and t.data_cancellazione is null
				and a.attoamm_id=_uid_provvedimento
				and h.movgest_tipo_code='I'
				and i.movgest_ts_tipo_code='T'
				and o.movgest_ts_det_tipo_code='A'
				and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
				and t.anno = _anno
			),
			sac as (
				select
					f.attoamm_id,
					g.classif_code,
					g.classif_desc
				from
					siac_r_atto_amm_class f,
					siac_t_class g,
					siac_d_class_tipo h
				where f.classif_id=g.classif_id
				and h.classif_tipo_id=g.classif_tipo_id
				and h.classif_tipo_code in ('CDR','CDC')
				and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and h.data_cancellazione is null
			)
			select
				attoamm.uid,
				attoamm.impegno_anno,
				attoamm.impegno_numero,
				attoamm.impegno_desc,
				attoamm.impegno_stato,
				attoamm.impegno_importo,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				attoamm.movgest_ts_id,
				sac.classif_code attoamm_sac_code,
				sac.classif_desc attoamm_sac_desc,
				attoamm.pdc_code pdc_code,
				attoamm.pdc_desc pdc_desc
			from attoamm
			left outer join sac on attoamm.attoamm_id=sac.attoamm_id
		),
		sogg as (
			select
				z.movgest_ts_id,
				y.soggetto_code,
				y.soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
		)
		select
			attoammsac.uid,
			attoammsac.impegno_anno,
			attoammsac.impegno_numero,
			attoammsac.impegno_desc,
			attoammsac.impegno_stato,
			attoammsac.impegno_importo,
			sogg.soggetto_code,
			sogg.soggetto_desc,
			attoammsac.attoamm_numero,
			attoammsac.attoamm_anno,
			attoammsac.attoamm_tipo_code,
			attoammsac.attoamm_tipo_desc,
			attoammsac.attoamm_stato_desc,
			attoammsac.attoamm_sac_code,
			attoammsac.attoamm_sac_desc,
			attoammsac.pdc_code pdc_code,
			attoammsac.pdc_desc pdc_desc
		from attoammsac
		left outer join sogg on attoammsac.movgest_ts_id=sogg.movgest_ts_id
		order by
			attoammsac.impegno_anno,
			attoammsac.impegno_numero
		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_impegno_from_soggetto_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*),0) into total
	from
		siac_r_movgest_ts_sog z,
		siac_t_soggetto y,
		siac_t_movgest_ts f,
		siac_t_movgest g,
		siac_d_movgest_tipo h,
		siac_d_movgest_ts_tipo i,
		siac_r_movgest_ts_stato l,
		siac_d_movgest_stato m,
		siac_t_movgest_ts_det n,
		siac_d_movgest_ts_det_tipo o,
		siac_r_movgest_class a,
		siac_t_class b,
		siac_d_class_tipo c,
		siac_t_bil d,
		siac_t_periodo e
	where z.soggetto_id=y.soggetto_id
	and z.movgest_ts_id=f.movgest_ts_id
	and g.movgest_id=f.movgest_id
	and h.movgest_tipo_id=g.movgest_tipo_id
	and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
	and l.movgest_ts_id=f.movgest_ts_id
	and l.movgest_stato_id=m.movgest_stato_id
	and a.movgest_ts_id = f.movgest_ts_id
	and b.classif_id = a.classif_id
	and c.classif_tipo_id = b.classif_tipo_id
	and n.movgest_ts_id=f.movgest_ts_id
	and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
	and d.bil_id = g.bil_id
	and e.periodo_id = d.periodo_id
	and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
	and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
	and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and i.data_cancellazione is null
	and l.data_cancellazione is null
	and m.data_cancellazione is null
	and n.data_cancellazione is null
	and o.data_cancellazione is null
	and z.data_cancellazione is null
	and y.data_cancellazione is null
	and a.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and h.movgest_tipo_code='I'
	and i.movgest_ts_tipo_code='T'
	and o.movgest_ts_det_tipo_code='A'
	and c.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and y.soggetto_id=_uid_soggetto
	and e.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_impegno_from_soggetto

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with attoammsac as (
		with attoamm as (
			select
				a.attoamm_numero,
				a.attoamm_anno,
				b.attoamm_tipo_code,
				b.attoamm_tipo_desc,
				d.attoamm_stato_desc,
				e.movgest_ts_id,
				a.attoamm_id
			from
				siac_t_atto_amm a,
				siac_d_atto_amm_tipo b,
				siac_r_atto_amm_stato c,
				siac_d_atto_amm_stato d,
				siac_r_movgest_ts_atto_amm e
			where b.attoamm_tipo_id=a.attoamm_tipo_id
			and c.attoamm_id=a.attoamm_id
			and d.attoamm_stato_id=c.attoamm_stato_id
			and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
			and e.attoamm_id=a.attoamm_id
			and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
			and a.data_cancellazione is null
			and b.data_cancellazione is null
			and c.data_cancellazione is null
			and d.data_cancellazione is null
			and e.data_cancellazione is null
		),
		sac as (
			select
				f.attoamm_id,
				g.classif_code,
				g.classif_desc
			from
				siac_r_atto_amm_class f,
				siac_t_class g,
				siac_d_class_tipo h
			where f.classif_id=g.classif_id
			and h.classif_tipo_id=g.classif_tipo_id
			and h.classif_tipo_code in ('CDR','CDC')
			and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
			and f.data_cancellazione is null
			and g.data_cancellazione is null
			and h.data_cancellazione is null
		)
		select
			attoamm.attoamm_numero,
			attoamm.attoamm_anno,
			attoamm.attoamm_tipo_code,
			attoamm.attoamm_tipo_desc,
			attoamm.attoamm_stato_desc,
			attoamm.movgest_ts_id,
			sac.classif_code attoamm_sac_code,
			sac.classif_desc attoamm_sac_desc
		from attoamm
		left outer join sac on attoamm.attoamm_id=sac.attoamm_id
	),
	sogg as (
		select
			g.movgest_id uid,
			g.movgest_anno  impegno_anno,
			g.movgest_numero impegno_numero,
			g.movgest_desc impegno_desc,
			m.movgest_stato_desc impegno_stato,
			n.movgest_ts_det_importo impegno_importo,
			z.movgest_ts_id,
			y.soggetto_code,
			y.soggetto_desc,
			b.classif_code pdc_code,
			b.classif_desc pdc_desc
		from
			siac_r_movgest_ts_sog z,
			siac_t_soggetto y,
			siac_t_movgest_ts f,
			siac_t_movgest g,
			siac_d_movgest_tipo h,
			siac_d_movgest_ts_tipo i,
			siac_r_movgest_ts_stato l,
			siac_d_movgest_stato m,
			siac_t_movgest_ts_det n,
			siac_d_movgest_ts_det_tipo o,
			siac_r_movgest_class a,
			siac_t_class b,
			siac_d_class_tipo c,
			siac_t_bil d,
			siac_t_periodo e
		where z.soggetto_id=y.soggetto_id
		and z.movgest_ts_id=f.movgest_ts_id
		and g.movgest_id=f.movgest_id
		and h.movgest_tipo_id=g.movgest_tipo_id
		and i.movgest_ts_tipo_id=f.movgest_ts_tipo_id
		and l.movgest_ts_id=f.movgest_ts_id
		and l.movgest_stato_id=m.movgest_stato_id
		and a.movgest_ts_id = f.movgest_ts_id
		and b.classif_id = a.classif_id
		and c.classif_tipo_id = b.classif_tipo_id
		and n.movgest_ts_id=f.movgest_ts_id
		and o.movgest_ts_det_tipo_id=n.movgest_ts_det_tipo_id
		and d.bil_id = g.bil_id
		and e.periodo_id = d.periodo_id
		and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
		and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
		and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and z.data_cancellazione is null
		and y.data_cancellazione is null
		and a.data_cancellazione is null
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and o.movgest_ts_det_tipo_code='A'
		and h.movgest_tipo_code='I'
		and i.movgest_ts_tipo_code='T'
		and c.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and y.soggetto_id=_uid_soggetto
		and e.anno = _anno
	)
	select
		sogg.uid,
		sogg.impegno_anno,
		sogg.impegno_numero,
		sogg.impegno_desc,
		sogg.impegno_stato,
		sogg.impegno_importo,
		sogg.soggetto_code,
		sogg.soggetto_desc,
		attoammsac.attoamm_numero,
		attoammsac.attoamm_anno,
		attoammsac.attoamm_tipo_code,
		attoammsac.attoamm_tipo_desc,
		attoammsac.attoamm_stato_desc,
		attoammsac.attoamm_sac_code,
		attoammsac.attoamm_sac_desc,
		sogg.pdc_code,
		sogg.pdc_desc
	from sogg
	left outer join attoammsac on attoammsac.movgest_ts_id=sogg.movgest_ts_id
	order by
		sogg.impegno_anno,
		sogg.impegno_numero
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_capitolospesa_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa_total (
  _capitolo_spesa_id integer,
  _anno varchar
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

-- fnc_siac_cons_entita_liquidazione_from_capitolospesa

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (
  _capitolo_spesa_id integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_num varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_num,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,sac.classif_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_impegno_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (
  _uid_impegno integer,
  _anno varchar
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
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		AND d.movgest_id=_uid_impegno
		and h.anno = _anno
	) as liq_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_liquidazione_from_impegno

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_impegno (
  _uid_impegno integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		AND d.movgest_id=_uid_impegno
		and h.anno = _anno
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,sac.classif_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_provvedimento_total

-- DROP FUNZIONE CON DUE (vecchia versione) E TRE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
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
		AND n.attoamm_id=_uid_provvedimento
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

-- fnc_siac_cons_entita_liquidazione_from_provvedimento

-- DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (integer,integer,integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (integer,varchar,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with liq as (
		select
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		AND n.attoamm_id=_uid_provvedimento
		AND h.anno = _anno
	),
	sac as (
		select
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	)
	select
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,sac.classif_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_soggetto_total

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
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
		and q.attoamm_stato_code<>'ANNULLATO'
		AND l.soggetto_id=_uid_soggetto
		and h.anno = _anno
	) as liq_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_liquidazione_from_soggetto

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  num_ueb varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		and q.attoamm_stato_code<>'ANNULLATO'
		AND l.soggetto_id=_uid_soggetto
		and h.anno = _anno
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,sac.classif_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_mmgeimp_from_provvedimento_total

-- DROP FUNZIONE CON DUE (vecchia versione) E TRE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT COALESCE(COUNT(*), 0) INTO total
	FROM (
		SELECT
			tmtdm.movgest_ts_det_mod_id AS uid
		FROM siac_t_movgest_ts_det_mod tmtdm
		JOIN siac_t_movgest_ts tmt ON (tmt.movgest_ts_id = tmtdm.movgest_ts_id AND tmtdm.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL)
		JOIN siac_d_movgest_ts_tipo dmtt ON (dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id AND dmtt.data_cancellazione IS NULL)
		JOIN siac_t_movgest tm ON (tm.movgest_id = tmt.movgest_id AND tm.data_cancellazione IS NULL)
		JOIN siac_d_movgest_tipo dmt ON (dmt.movgest_tipo_id = tm.movgest_tipo_id AND dmt.data_cancellazione IS NULL)
		JOIN siac_r_modifica_stato rms ON (rms.mod_stato_r_id = tmtdm.mod_stato_r_id AND rms.data_cancellazione IS NULL AND now() BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, now()))
		JOIN siac_d_modifica_stato dms ON (dms.mod_stato_id = rms.mod_stato_id AND dms.data_cancellazione IS NULL)
		JOIN siac_t_modifica tmo ON (tmo.mod_id = rms.mod_id AND tmo.data_cancellazione IS NULL)
		JOIN siac_d_modifica_tipo dmot ON (dmot.mod_tipo_id = tmo.mod_tipo_id AND dmot.data_cancellazione IS NULL)
		JOIN siac_t_atto_amm taa ON taa.attoamm_id = tmo.attoamm_id
		JOIN siac_t_bil tb ON (tb.bil_id = tm.bil_id AND tb.data_cancellazione IS NULL)
		JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
		WHERE taa.attoamm_id = _uid_provvedimento
		AND dmt.movgest_tipo_code = 'A'
		AND tp.anno = _anno
	) AS mmge;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_mmgeimp_from_provvedimento

-- DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento (integer,integer,integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento (integer,varchar,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mmgeimp_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  subaccertamento_numero varchar,
  accertamento_subaccertamento varchar,
  accertamento_desc varchar,
  modifica_desc varchar,
  modifica_tipo_code varchar,
  modifica_tipo_desc varchar,
  modifica_stato_code varchar,
  modifica_stato_desc varchar,
  importo numeric,
  modifica_numero integer
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		SELECT
			tmtdm.movgest_ts_det_mod_id AS uid,
			tm.movgest_anno AS accertamento_anno,
			tm.movgest_numero AS accertamento_numero,
			tmt.movgest_ts_code AS subaccertamento_numero,
			dmtt.movgest_ts_tipo_code AS accertamento_subaccertamento,
			tm.movgest_desc AS accertamento_desc,
			tmo.mod_desc AS modifica_desc,
			dmot.mod_tipo_code AS modifica_tipo_code,
			dmot.mod_tipo_desc AS modifica_tipo_desc,
			dms.mod_stato_code AS modifica_stato_code,
			dms.mod_stato_desc AS modifica_stato_desc,
			tmtdm.movgest_ts_det_importo AS importo,
			tmo.mod_num AS modifica_numero
		FROM siac_t_movgest_ts_det_mod tmtdm
		JOIN siac_t_movgest_ts tmt ON (tmt.movgest_ts_id = tmtdm.movgest_ts_id AND tmtdm.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL)
		JOIN siac_d_movgest_ts_tipo dmtt ON (dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id AND dmtt.data_cancellazione IS NULL)
		JOIN siac_t_movgest tm ON (tm.movgest_id = tmt.movgest_id AND tm.data_cancellazione IS NULL)
		JOIN siac_d_movgest_tipo dmt ON (dmt.movgest_tipo_id = tm.movgest_tipo_id AND dmt.data_cancellazione IS NULL)
		JOIN siac_r_modifica_stato rms ON (rms.mod_stato_r_id = tmtdm.mod_stato_r_id AND rms.data_cancellazione IS NULL AND now() BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, now()))
		JOIN siac_d_modifica_stato dms ON (dms.mod_stato_id = rms.mod_stato_id AND dms.data_cancellazione IS NULL)
		JOIN siac_t_modifica tmo ON (tmo.mod_id = rms.mod_id AND tmo.data_cancellazione IS NULL)
		JOIN siac_d_modifica_tipo dmot ON (dmot.mod_tipo_id = tmo.mod_tipo_id AND dmot.data_cancellazione IS NULL)
		JOIN siac_t_atto_amm taa ON taa.attoamm_id = tmo.attoamm_id
		JOIN siac_t_bil tb ON (tb.bil_id = tm.bil_id AND tb.data_cancellazione IS NULL)
		JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
		WHERE taa.attoamm_id = _uid_provvedimento
		AND dmt.movgest_tipo_code = 'A'
		AND tp.anno = _anno
		ORDER BY accertamento_anno, accertamento_numero, accertamento_subaccertamento DESC, subaccertamento_numero, modifica_numero
		LIMIT _limit
		OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_mmgsimp_from_provvedimento_total

-- DROP FUNZIONE CON DUE (vecchia versione) E TRE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT COALESCE(COUNT(*), 0) INTO total
	FROM (
		SELECT
			tmtdm.movgest_ts_det_mod_id AS uid
		FROM siac_t_movgest_ts_det_mod tmtdm
		JOIN siac_t_movgest_ts tmt ON (tmt.movgest_ts_id = tmtdm.movgest_ts_id AND tmtdm.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL)
		JOIN siac_d_movgest_ts_tipo dmtt ON (dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id AND dmtt.data_cancellazione IS NULL)
		JOIN siac_t_movgest tm ON (tm.movgest_id = tmt.movgest_id AND tm.data_cancellazione IS NULL)
		JOIN siac_d_movgest_tipo dmt ON (dmt.movgest_tipo_id = tm.movgest_tipo_id AND dmt.data_cancellazione IS NULL)
		JOIN siac_r_modifica_stato rms ON (rms.mod_stato_r_id = tmtdm.mod_stato_r_id AND rms.data_cancellazione IS NULL AND now() BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, now()))
		JOIN siac_d_modifica_stato dms ON (dms.mod_stato_id = rms.mod_stato_id AND dms.data_cancellazione IS NULL)
		JOIN siac_t_modifica tmo ON (tmo.mod_id = rms.mod_id AND tmo.data_cancellazione IS NULL)
		JOIN siac_d_modifica_tipo dmot ON (dmot.mod_tipo_id = tmo.mod_tipo_id AND dmot.data_cancellazione IS NULL)
		JOIN siac_t_atto_amm taa ON taa.attoamm_id = tmo.attoamm_id
		JOIN siac_t_bil tb ON (tb.bil_id = tm.bil_id AND tb.data_cancellazione IS NULL)
		JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
		WHERE taa.attoamm_id = _uid_provvedimento
		AND dmt.movgest_tipo_code = 'I'
		AND tp.anno = _anno
	) AS mmgs;
	
	RETURN total;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- fnc_siac_cons_entita_mmgsimp_from_provvedimento

-- DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (integer,integer,integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (integer,varchar,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mmgsimp_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  subimpegno_numero varchar,
  impegno_subimpegno varchar,
  impegno_desc varchar,
  modifica_desc varchar,
  modifica_tipo_code varchar,
  modifica_tipo_desc varchar,
  modifica_stato_code varchar,
  modifica_stato_desc varchar,
  importo numeric,
  modifica_numero integer
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		SELECT
			tmtdm.movgest_ts_det_mod_id AS uid,
			tm.movgest_anno AS impegno_anno,
			tm.movgest_numero AS impegno_numero,
			tmt.movgest_ts_code AS subimpegno_numero,
			dmtt.movgest_ts_tipo_code AS impegno_subimpegno,
			tm.movgest_desc AS impegno_desc,
			tmo.mod_desc AS modifica_desc,
			dmot.mod_tipo_code AS modifica_tipo_code,
			dmot.mod_tipo_desc AS modifica_tipo_desc,
			dms.mod_stato_code AS modifica_stato_code,
			dms.mod_stato_desc AS modifica_stato_desc,
			tmtdm.movgest_ts_det_importo AS importo,
			tmo.mod_num AS modifica_numero
		FROM siac_t_movgest_ts_det_mod tmtdm
		JOIN siac_t_movgest_ts tmt ON (tmt.movgest_ts_id = tmtdm.movgest_ts_id AND tmtdm.data_cancellazione IS NULL AND tmt.data_cancellazione IS NULL)
		JOIN siac_d_movgest_ts_tipo dmtt ON (dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id AND dmtt.data_cancellazione IS NULL)
		JOIN siac_t_movgest tm ON (tm.movgest_id = tmt.movgest_id AND tm.data_cancellazione IS NULL)
		JOIN siac_d_movgest_tipo dmt ON (dmt.movgest_tipo_id = tm.movgest_tipo_id AND dmt.data_cancellazione IS NULL)
		JOIN siac_r_modifica_stato rms ON (rms.mod_stato_r_id = tmtdm.mod_stato_r_id AND rms.data_cancellazione IS NULL AND now() BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, now()))
		JOIN siac_d_modifica_stato dms ON (dms.mod_stato_id = rms.mod_stato_id AND dms.data_cancellazione IS NULL)
		JOIN siac_t_modifica tmo ON (tmo.mod_id = rms.mod_id AND tmo.data_cancellazione IS NULL)
		JOIN siac_d_modifica_tipo dmot ON (dmot.mod_tipo_id = tmo.mod_tipo_id AND dmot.data_cancellazione IS NULL)
		JOIN siac_t_atto_amm taa ON taa.attoamm_id = tmo.attoamm_id
		JOIN siac_t_bil tb ON (tb.bil_id = tm.bil_id AND tb.data_cancellazione IS NULL)
		JOIN siac_t_periodo tp ON (tp.periodo_id = tb.periodo_id AND tp.data_cancellazione IS NULL)
		WHERE taa.attoamm_id = _uid_provvedimento
		AND dmt.movgest_tipo_code = 'I'
		AND tp.anno = _anno
		ORDER BY impegno_anno, impegno_numero, impegno_subimpegno DESC, subimpegno_numero, modifica_numero
		LIMIT _limit
		OFFSET _offset;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5152 - FINE

-- SIAC-5164 - INIZIO

-- fnc_siac_cons_entita_liquidazione_from_soggetto

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  num_ueb varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_stato_code varchar,
  ord_stato_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		and q.attoamm_stato_code<>'ANNULLATO'
		AND l.soggetto_id=_uid_soggetto
		and h.anno = _anno
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	), ordi as (
		-- SIAC-5164
		SELECT
			rlo.liq_id,
			tor.ord_anno,
			tor.ord_numero,
			dos.ord_stato_code,
			dos.ord_stato_desc
		FROM
			siac_r_liquidazione_ord rlo,
			siac_t_ordinativo_ts tot,
			siac_t_ordinativo tor,
			siac_r_ordinativo_stato ros,
			siac_d_ordinativo_stato dos
		WHERE rlo.sord_id = tot.ord_ts_id
		AND tot.ord_id = tor.ord_id
		AND ros.ord_id = tor.ord_id
		AND dos.ord_stato_id = ros.ord_stato_id
		AND now() BETWEEN rlo.validita_inizio AND COALESCE (rlo.validita_fine, now())
		AND now() BETWEEN ros.validita_inizio AND COALESCE (ros.validita_fine, now())
		AND rlo.data_cancellazione IS NULL
		AND tot.data_cancellazione IS NULL
		AND tor.data_cancellazione IS NULL
		AND ros.data_cancellazione IS NULL
		AND dos.data_cancellazione IS NULL
		AND dos.ord_stato_code <> 'A'
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,
		sac.classif_desc,
		ordi.ord_anno,
		ordi.ord_numero,
		ordi.ord_stato_code,
		ordi.ord_stato_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	left outer join ordi on ordi.liq_id = liq.liq_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_provvedimento

-- DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (integer,integer,integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (integer,varchar,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_provvedimento (
  _uid_provvedimento integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_stato_code varchar,
  ord_stato_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with liq as (
		select
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		AND n.attoamm_id=_uid_provvedimento
		AND h.anno = _anno
	),
	sac as (
		select
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	), ordi as (
		-- SIAC-5164
		SELECT
			rlo.liq_id,
			tor.ord_anno,
			tor.ord_numero,
			dos.ord_stato_code,
			dos.ord_stato_desc
		FROM
			siac_r_liquidazione_ord rlo,
			siac_t_ordinativo_ts tot,
			siac_t_ordinativo tor,
			siac_r_ordinativo_stato ros,
			siac_d_ordinativo_stato dos
		WHERE rlo.sord_id = tot.ord_ts_id
		AND tot.ord_id = tor.ord_id
		AND ros.ord_id = tor.ord_id
		AND dos.ord_stato_id = ros.ord_stato_id
		AND now() BETWEEN rlo.validita_inizio AND COALESCE (rlo.validita_fine, now())
		AND now() BETWEEN ros.validita_inizio AND COALESCE (ros.validita_fine, now())
		AND rlo.data_cancellazione IS NULL
		AND tot.data_cancellazione IS NULL
		AND tor.data_cancellazione IS NULL
		AND ros.data_cancellazione IS NULL
		AND dos.data_cancellazione IS NULL
		AND dos.ord_stato_code <> 'A'
	)
	select
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,
		sac.classif_desc,
		ordi.ord_anno,
		ordi.ord_numero,
		ordi.ord_stato_code,
		ordi.ord_stato_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	left outer join ordi on ordi.liq_id = liq.liq_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_impegno

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_impegno (
  _uid_impegno integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_stato_code varchar,
  ord_stato_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
		AND d.movgest_id=_uid_impegno
		and h.anno = _anno
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	), ordi as (
		-- SIAC-5164
		SELECT
			rlo.liq_id,
			tor.ord_anno,
			tor.ord_numero,
			dos.ord_stato_code,
			dos.ord_stato_desc
		FROM
			siac_r_liquidazione_ord rlo,
			siac_t_ordinativo_ts tot,
			siac_t_ordinativo tor,
			siac_r_ordinativo_stato ros,
			siac_d_ordinativo_stato dos
		WHERE rlo.sord_id = tot.ord_ts_id
		AND tot.ord_id = tor.ord_id
		AND ros.ord_id = tor.ord_id
		AND dos.ord_stato_id = ros.ord_stato_id
		AND now() BETWEEN rlo.validita_inizio AND COALESCE (rlo.validita_fine, now())
		AND now() BETWEEN ros.validita_inizio AND COALESCE (ros.validita_fine, now())
		AND rlo.data_cancellazione IS NULL
		AND tot.data_cancellazione IS NULL
		AND tor.data_cancellazione IS NULL
		AND ros.data_cancellazione IS NULL
		AND dos.data_cancellazione IS NULL
		AND dos.ord_stato_code <> 'A'
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,
		sac.classif_desc,
		ordi.ord_anno,
		ordi.ord_numero,
		ordi.ord_stato_code,
		ordi.ord_stato_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	left outer join ordi on ordi.liq_id = liq.liq_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- fnc_siac_cons_entita_liquidazione_from_capitolospesa

-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_capitolospesa (
  _capitolo_spesa_id integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_num varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_stato_code varchar,
  ord_stato_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
    with liq as (
		select 
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id
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
	),
	sac as (
		select 
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_r_atto_amm_class z,
			siac_t_class y,
			siac_d_class_tipo x
		where z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	), ordi as (
		-- SIAC-5164
		SELECT
			rlo.liq_id,
			tor.ord_anno,
			tor.ord_numero,
			dos.ord_stato_code,
			dos.ord_stato_desc
		FROM
			siac_r_liquidazione_ord rlo,
			siac_t_ordinativo_ts tot,
			siac_t_ordinativo tor,
			siac_r_ordinativo_stato ros,
			siac_d_ordinativo_stato dos
		WHERE rlo.sord_id = tot.ord_ts_id
		AND tot.ord_id = tor.ord_id
		AND ros.ord_id = tor.ord_id
		AND dos.ord_stato_id = ros.ord_stato_id
		AND now() BETWEEN rlo.validita_inizio AND COALESCE (rlo.validita_fine, now())
		AND now() BETWEEN ros.validita_inizio AND COALESCE (ros.validita_fine, now())
		AND rlo.data_cancellazione IS NULL
		AND tot.data_cancellazione IS NULL
		AND tor.data_cancellazione IS NULL
		AND ros.data_cancellazione IS NULL
		AND dos.data_cancellazione IS NULL
		AND dos.ord_stato_code <> 'A'
	)
	select 
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_num,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,
		sac.classif_desc,
		ordi.ord_anno,
		ordi.ord_numero,
		ordi.ord_stato_code,
		ordi.ord_stato_desc
	from liq
	left outer join sac on liq.attoamm_id=sac.attoamm_id
	left outer join ordi on ordi.liq_id = liq.liq_id
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5164 - FINE

-- SIAC-5155 INIZIO

CREATE OR REPLACE VIEW siac.siac_v_dwh_carta_contabile (
    ente_proprietario_id,
    anno_bilancio,
    cartac_stato_code,
    cartac_stato_desc,
    crt_det_sogg_id,
    soggetto_code,
    soggetto_desc,
    attoamm_anno,
    attoamm_numero,
    attoamm_tipo_code,
    attoamm_tipo_desc,
    cod_sac,
    desc_sac,
    cartac_numero,
    cartac_importo,
    cartac_oggetto,
    causale_carta,
    cartac_data_scadenza,
    cartac_data_pagamento,
    note_carta,
    urgenza,
    flagisestera,
    est_causale,
    est_valuta,
    est_data_valuta,
    est_titolare_diverso,
    est_istruzioni,
    crt_det_numero,
    crt_det_desc,
    crt_det_importo,
    crt_det_valuta,
    crt_det_contotesoriere,
    crt_det_mdp_id,
    movgest_anno,
    movgest_numero,
    subimpegno,
    doc_anno,
    doc_numero,
    doc_tipo_code,
    doc_fam_tipo_code,
    doc_data_emissione,
    soggetto_doc,
    subdoc_numero,
    anno_elenco_doc,
    num_elenco_doc)
AS
SELECT tbb.ente_proprietario_id, tbb.anno_bilancio, tbb.cartac_stato_code,
    tbb.cartac_stato_desc, tbb.crt_det_sogg_id, tbb.soggetto_code,
    tbb.soggetto_desc, tbb.attoamm_anno, tbb.attoamm_numero,
    tbb.attoamm_tipo_code, tbb.attoamm_tipo_desc, tbb.cod_sac, tbb.desc_sac,
    tbb.cartac_numero, tbb.cartac_importo, tbb.cartac_oggetto,
    tbb.causale_carta, tbb.cartac_data_scadenza, tbb.cartac_data_pagamento,
    tbb.note_carta, tbb.urgenza, tbb.flagisestera, tbb.est_causale,
    tbb.est_valuta, tbb.est_data_valuta, tbb.est_titolare_diverso,
    tbb.est_istruzioni, tbb.crt_det_numero, tbb.crt_det_desc,
    tbb.crt_det_importo, tbb.crt_det_valuta, tbb.crt_det_contotesoriere,
    tbb.crt_det_mdp_id, tbb.movgest_anno, tbb.movgest_numero, tbb.subimpegno,
    tbb.doc_anno, tbb.doc_numero, tbb.doc_tipo_code, tbb.doc_fam_tipo_code,
    tbb.doc_data_emissione, tbb.soggetto_doc, tbb.subdoc_numero,
    tbb.anno_elenco_doc, tbb.num_elenco_doc
FROM ( WITH aa AS (
    SELECT DISTINCT a.ente_proprietario_id, d.anno,
                    f.cartac_stato_id, f.cartac_stato_code, f.cartac_stato_desc,
                    a.cartac_numero, a.cartac_importo, a.cartac_oggetto,
                    a.cartac_causale, a.cartac_data_scadenza,
                    a.cartac_data_pagamento, a.cartac_importo_valuta,
                    a.cartac_id, b.cartac_det_numero, b.cartac_det_desc,
                    b.cartac_det_importo, b.cartac_det_importo_valuta,
                    b.contotes_id, b.cartac_det_id, a.attoamm_id
    FROM siac_t_cartacont a, siac_t_cartacont_det b,
                    siac_t_bil c, siac_t_periodo d, siac_r_cartacont_stato e,
                    siac_d_cartacont_stato f
    WHERE a.cartac_id = b.cartac_id AND a.bil_id = c.bil_id AND d.periodo_id =
        c.periodo_id AND e.cartac_id = a.cartac_id AND e.cartac_stato_id = f.cartac_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT notes.contotes_code, notes.contotes_id
    FROM siac_d_contotesoreria notes
    WHERE notes.data_cancellazione IS NULL
    ), cc AS (
    SELECT i.cartacest_id, i.cartacest_causalepagamento,
                    i.cartacest_data_valuta, i.cartacest_diversotitolare,
                    i.cartacest_istruzioni, i.cartac_id
    FROM siac_t_cartacont_estera i
    WHERE i.data_cancellazione IS NULL
    ), dd AS (
    SELECT rmdp.modpag_id, rmdp.cartac_det_id
    FROM siac_r_cartacont_det_modpag rmdp
    WHERE rmdp.data_cancellazione IS NULL
    AND now() >= rmdp.validita_inizio
    AND now() <= COALESCE(rmdp.validita_fine::timestamp with time zone, now())  
    ), ee AS (
    SELECT rmvgest.cartac_det_id, mvgts.movgest_ts_id_padre,
                    movgest.movgest_anno, movgest.movgest_numero,
                    mvgts.movgest_ts_code
    FROM siac_r_cartacont_det_movgest_ts rmvgest,
                    siac_t_movgest_ts mvgts, siac_t_movgest movgest
    WHERE rmvgest.movgest_ts_id = mvgts.movgest_ts_id AND mvgts.movgest_id =
        movgest.movgest_id AND rmvgest.data_cancellazione IS NULL AND mvgts.data_cancellazione IS NULL AND movgest.data_cancellazione IS NULL
    AND now() >= rmvgest.validita_inizio 
    AND now() <= COALESCE(rmvgest.validita_fine::timestamp with time zone, now())    
    ), ff AS (
    SELECT rsog.soggetto_id, rsog.cartac_det_id, b.soggetto_code,
                    b.soggetto_desc
    FROM siac_r_cartacont_det_soggetto rsog, siac_t_soggetto b
    WHERE rsog.data_cancellazione IS NULL AND b.soggetto_id = rsog.soggetto_id
        AND rsog.validita_fine IS NULL
    ), gg AS (
    SELECT tb.doc_id, tb.cartac_det_id, tb.doc_anno, tb.doc_numero,
                    tb.doc_tipo_code, tb.doc_fam_tipo_code,
                    tb.doc_data_emissione, tb.soggetto_id, tb.subdoc_numero,
                    tb.anno_elenco_doc, tb.num_elenco_doc
    FROM ( WITH gg1 AS (
        SELECT doc.doc_id, rsubdoc.cartac_det_id,
                                    doc.doc_anno, doc.doc_numero,
                                    e.doc_tipo_code, d.doc_fam_tipo_code,
                                    doc.doc_data_emissione,
                                    subdoc.subdoc_numero, subdoc.subdoc_id
        FROM siac_r_cartacont_det_subdoc rsubdoc,
                                    siac_t_subdoc subdoc, siac_t_doc doc,
                                    siac_d_doc_fam_tipo d, siac_d_doc_tipo e
        WHERE subdoc.subdoc_id = rsubdoc.subdoc_id AND doc.doc_id =
            subdoc.doc_id AND rsubdoc.data_cancellazione IS NULL AND subdoc.data_cancellazione IS NULL AND doc.data_cancellazione IS NULL AND e.doc_tipo_id = doc.doc_tipo_id AND d.doc_fam_tipo_id = e.doc_fam_tipo_id AND e.data_cancellazione IS NULL AND d.data_cancellazione IS NULL
        ), gg2 AS (
        SELECT rsogd.soggetto_id, rsogd.doc_id
        FROM siac_r_doc_sog rsogd
        WHERE rsogd.data_cancellazione IS NULL
        ), gg3 AS (
        SELECT a.subdoc_id,
                                    b.eldoc_anno AS anno_elenco_doc,
                                    b.eldoc_numero AS num_elenco_doc
        FROM siac_r_elenco_doc_subdoc a,
                                    siac_t_elenco_doc b
        WHERE b.eldoc_id = a.eldoc_id AND a.data_cancellazione IS NULL AND
            b.data_cancellazione IS NULL AND a.validita_fine IS NULL
        )
        SELECT gg1.doc_id, gg1.cartac_det_id, gg1.doc_anno,
                            gg1.doc_numero, gg1.doc_tipo_code,
                            gg1.doc_fam_tipo_code, gg1.doc_data_emissione,
                            gg2.soggetto_id, gg1.subdoc_numero,
                            gg3.anno_elenco_doc, gg3.num_elenco_doc
        FROM gg1
                      LEFT JOIN gg2 ON gg1.doc_id = gg2.doc_id
                 LEFT JOIN gg3 ON gg1.subdoc_id = gg3.subdoc_id
        ) tb
    ), hh AS (
    SELECT rurg.testo, rurg.cartac_id
    FROM siac_r_cartacont_attr rurg, siac_t_attr atturg
    WHERE atturg.attr_id = rurg.attr_id AND atturg.attr_code::text =
        'motivo_urgenza'::text AND rurg.data_cancellazione IS NULL AND atturg.data_cancellazione IS NULL
    ), ii AS (
    SELECT rnote.testo, rnote.cartac_id
    FROM siac_r_cartacont_attr rnote, siac_t_attr attrnote
    WHERE attrnote.attr_id = rnote.attr_id AND attrnote.attr_code::text =
        'note'::text AND rnote.data_cancellazione IS NULL AND attrnote.data_cancellazione IS NULL
    ), ll AS (
    SELECT h.attoamm_id, h.attoamm_anno, h.attoamm_numero,
                    daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    FROM siac_t_atto_amm h, siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = h.attoamm_tipo_id AND h.data_cancellazione IS
        NULL AND daat.data_cancellazione IS NULL
    ), mm AS (
    SELECT i.attoamm_id, l.classif_id, l.classif_code,
                    l.classif_desc, m.classif_tipo_code
    FROM siac_r_atto_amm_class i, siac_t_class l,
                    siac_d_class_tipo m, siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o, siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id
        AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND m.data_cancellazione IS NULL AND n.data_cancellazione IS NULL AND o.data_cancellazione IS NULL AND p.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id, aa.anno AS anno_bilancio,
            aa.cartac_stato_code, aa.cartac_stato_desc,
            ff.soggetto_id AS crt_det_sogg_id, ff.soggetto_code,
            ff.soggetto_desc, ll.attoamm_anno, ll.attoamm_numero,
            ll.attoamm_tipo_code, ll.attoamm_tipo_desc,
            mm.classif_code AS cod_sac, mm.classif_desc AS desc_sac,
            aa.cartac_numero, aa.cartac_importo, aa.cartac_oggetto,
            aa.cartac_causale AS causale_carta, aa.cartac_data_scadenza,
            aa.cartac_data_pagamento, ii.testo AS note_carta,
            hh.testo AS urgenza,
                CASE
                    WHEN cc.cartacest_id IS NOT NULL THEN true
                    ELSE false
                END AS flagisestera,
            cc.cartacest_causalepagamento AS est_causale,
            aa.cartac_importo_valuta AS est_valuta,
            cc.cartacest_data_valuta AS est_data_valuta,
            cc.cartacest_diversotitolare AS est_titolare_diverso,
            cc.cartacest_istruzioni AS est_istruzioni,
            aa.cartac_det_numero AS crt_det_numero,
            aa.cartac_det_desc AS crt_det_desc,
            aa.cartac_det_importo AS crt_det_importo,
            aa.cartac_det_importo_valuta AS crt_det_valuta,
            bb.contotes_code AS crt_det_contotesoriere,
            dd.modpag_id AS crt_det_mdp_id, ee.movgest_anno, ee.movgest_numero,
                CASE
                    WHEN ee.movgest_ts_id_padre::character varying IS NOT NULL
                        THEN ee.movgest_ts_code
                    ELSE ee.movgest_ts_id_padre::character varying
                END AS subimpegno,
            gg.doc_anno, gg.doc_numero, gg.doc_tipo_code, gg.doc_fam_tipo_code,
            gg.doc_data_emissione, gg.soggetto_id AS soggetto_doc,
            gg.subdoc_numero, gg.anno_elenco_doc, gg.num_elenco_doc
    FROM aa
      LEFT JOIN bb ON aa.contotes_id = bb.contotes_id
   LEFT JOIN cc ON aa.cartac_id = cc.cartac_id
   LEFT JOIN dd ON aa.cartac_det_id = dd.cartac_det_id
   LEFT JOIN ee ON aa.cartac_det_id = ee.cartac_det_id
   LEFT JOIN ff ON aa.cartac_det_id = ff.cartac_det_id
   LEFT JOIN gg ON aa.cartac_det_id = gg.cartac_det_id
   LEFT JOIN hh ON aa.cartac_id = hh.cartac_id
   LEFT JOIN ii ON aa.cartac_id = ii.cartac_id
   LEFT JOIN ll ON aa.attoamm_id = ll.attoamm_id
   LEFT JOIN mm ON aa.attoamm_id = mm.attoamm_id
    ) tbb  
ORDER BY tbb.ente_proprietario_id, tbb.anno_bilancio, tbb.cartac_numero;

-- SIAC-5155 FINE

-- SIAC-5124 INIZIO

CREATE OR REPLACE VIEW siac.siac_v_dwh_vincoli_movgest (
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    programma_code,
    programma_desc,
    tipo_da,
    anno_da,
    numero_da,
    tipo_a,
    anno_a,
    numero_a,
    importo_vincolo,
    tipo_avanzo_vincolo)
AS
SELECT bil.ente_proprietario_id, 
       bil.bil_code, 
       periodo.anno AS anno_bilancio,
       progetto.programma_code, 
       progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da, 
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da, 
       movtipoa.movgest_tipo_code AS tipo_a,
       mova.movgest_anno AS anno_a, 
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo
FROM siac_r_movgest_ts a
INNER JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_b_id = movtsa.movgest_ts_id 
INNER JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
INNER JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
INNER JOIN siac_t_bil bil ON  bil.bil_id = mova.bil_id 
INNER JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id 
LEFT  JOIN siac_t_movgest_ts movtsda ON a.movgest_ts_a_id = movtsda.movgest_ts_id
                                     AND movtsda.data_cancellazione IS NULL 
LEFT  JOIN siac_t_movgest movda ON movda.movgest_id = movtsda.movgest_id 
                                AND movda.data_cancellazione IS NULL 
LEFT  JOIN siac_d_movgest_tipo movtipoda ON movtipoda.movgest_tipo_id = movda.movgest_tipo_id 
                                         AND movtipoda.data_cancellazione IS NULL
LEFT JOIN siac_r_movgest_ts_programma rprogramma ON rprogramma.movgest_ts_id = movtsa.movgest_ts_id
                                                 AND rprogramma.data_cancellazione IS NULL                                                                                                                  
LEFT JOIN siac_t_programma progetto ON progetto.programma_id = rprogramma.programma_id
                                    AND progetto.data_cancellazione IS NULL
LEFT JOIN siac_t_avanzovincolo ta ON ta.avav_id = a.avav_id
                                    AND ta.data_cancellazione IS NULL 
LEFT JOIN siac_d_avanzovincolo_tipo dat ON dat.avav_tipo_id = ta.avav_tipo_id
                                        AND dat.data_cancellazione IS NULL                                                                         
WHERE a.data_cancellazione IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   mova.data_cancellazione IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL;

-- SIAC-5124 FINE

-- SIAC-5187 INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_reversali (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  conta_reversali integer,
  split_reverse varchar,
  importo_split_reverse numeric,
  elenco_reversali varchar,
  cod_tributo varchar,
  importo_irpef_imponibile numeric,
  importo_imposta numeric,
  importo_inps_inponibile numeric,
  importo_ritenuta numeric,
  importo_reversale numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoReversali record;
ciclo integer;



BEGIN
ord_id:=null;

conta_reversali:=0;
importo_reversale:=0;
split_reverse:='';
elenco_reversali:='';
importo_split_reverse:=0;
cod_tributo:='';
importo_irpef_imponibile:=0;
importo_imposta:=0;
importo_inps_inponibile:=0;
importo_ritenuta:=0;

 for elencoReversali in     
        select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                r_ordinativo.ord_id_da ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord,
                r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
                d_onere_tipo.onere_tipo_code, d_onere.onere_code
        from  siac_r_ordinativo r_ordinativo, 
              siac_t_ordinativo t_ordinativo,
              siac_d_ordinativo_tipo d_ordinativo_tipo,
              siac_d_relaz_tipo d_relaz_tipo, 
              siac_t_ordinativo_ts t_ord_ts,
              siac_t_ordinativo_ts_det t_ord_ts_det, 
              siac_d_ordinativo_ts_det_tipo ts_det_tipo,
              siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
              siac_r_doc_onere r_doc_onere, 
              siac_d_onere d_onere,
              siac_d_onere_tipo  d_onere_tipo
              where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                AND t_ord_ts.ord_id=t_ordinativo.ord_id
                AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                AND d_ordinativo_tipo.ord_tipo_code ='I'
                AND ts_det_tipo.ord_ts_det_tipo_code='A'
                    /* cerco tutte le tipologie di relazione,
                        non solo RIT_ORD */          
              /* ord_id_da contiene l'ID del mandato
                 ord_id_a contiene l'ID della reversale */
            --AND r_ordinativo.ord_id_da = elencoMandati.ord_id
            AND r_ordinativo.ente_proprietario_id=p_ente_prop_id
            AND r_ordinativo.data_cancellazione IS NULL
            AND t_ordinativo.data_cancellazione IS NULL
            AND d_ordinativo_tipo.data_cancellazione IS NULL            
            AND d_relaz_tipo.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND ts_det_tipo.data_cancellazione IS NULL            
            AND r_doc_onere_ord_ts.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
      order by r_ordinativo.ord_id_da  ,r_ordinativo.ord_id_a     
      loop
--raise notice 'Tipo rev=%, Importo rev=%, Imponibile=%' , elencoReversali.onere_tipo_code, elencoReversali.importo_ord, elencoReversali.importo_imponibile;          
             if ord_id is not null and 
            	ord_id <> elencoReversali.ord_id THEN
                  return next;
                  conta_reversali:=0;
                  importo_reversale:=0;
                  split_reverse:='';
                  elenco_reversali:='';
                  importo_split_reverse:=0;
                  cod_tributo:='';
                  importo_irpef_imponibile:=0;
                  importo_imposta:=0;
                  importo_inps_inponibile:=0;
                  importo_ritenuta:=0;
                end if;
            ord_id:=elencoReversali.ord_id;
            conta_reversali=conta_reversali+1;
            importo_reversale=elencoReversali.importo_ord;
                /* se il tipo di relazione e' SPR, e' SPLIT/REVERSE, carico l'importo */            
            if upper(elencoReversali.relaz_tipo_code)='SPR' THEN
                importo_split_reverse=importo_split_reverse+elencoReversali.importo_ord;
                if split_reverse = '' THEN
                    split_reverse=elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                else
                    split_reverse=split_reverse||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
                end if;
            end if;
             /* anche split/reverse e' una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti 
                (possono essere piu' di 1) */
              
--raise notice 'elencoReversali.ord_numero =%', elencoReversali.ord_numero;              
              if elenco_reversali = '' THEN
                  elenco_reversali = elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              else
                  elenco_reversali = elenco_reversali||', '||elencoReversali.ord_numero ::VARCHAR ||' del '|| to_char(elencoReversali.ord_emissione_data,'dd/mm/yyyy');
              end if;
              /* utilizzando il legame con la tabella siac_r_doc_onere_ordinativo_ts
              	si puo' capire se la reversale ha un onere INPS/IRPEF e recuperarne
                gli importi */
              /* devono essere considerati gli importi di tutte le
              	reversali, quindi li sommo */
              IF upper(elencoReversali.onere_tipo_code) = 'IRPEF' THEN
              	cod_tributo=elencoReversali.onere_code;            
              	importo_irpef_imponibile= importo_irpef_imponibile+elencoReversali.importo_imponibile;
                importo_imposta=importo_imposta+elencoReversali.importo_ord;
              elsif upper(elencoReversali.onere_tipo_code) = 'INPS' THEN
                importo_inps_inponibile=importo_inps_inponibile+elencoReversali.importo_imponibile;
                importo_ritenuta=importo_ritenuta+elencoReversali.importo_ord;
              END IF;
          end loop; 
        
        return next;



exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
        return;
    when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR144_Stampa_giorn_mandati_pagamento_emessi" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_numero_distinta varchar,
  p_stato_mandato varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  cod_gestione varchar,
  num_impegno varchar,
  num_subimpegno varchar,
  importo_lordo_mandato numeric,
  numero_mandato integer,
  data_mandato date,
  importo_stanz_cassa numeric,
  importo_tot_mandati_emessi numeric,
  importo_tot_mandati_dopo_emiss numeric,
  importo_dispon numeric,
  nome_tesoriere varchar,
  desc_causale varchar,
  desc_provvedimento varchar,
  estremi_provvedimento varchar,
  numero_fattura_completa varchar,
  num_fattura varchar,
  anno_fattura integer,
  importo_documento numeric,
  num_sub_doc_fattura integer,
  importo_fattura numeric,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  benef_indirizzo varchar,
  benef_cap varchar,
  benef_localita varchar,
  benef_provincia varchar,
  desc_mod_pagamento varchar,
  bollo varchar,
  banca_appoggio varchar,
  banca_abi varchar,
  banca_cab varchar,
  banca_cc varchar,
  banca_cc_estero varchar,
  banca_cc_posta varchar,
  banca_cin varchar,
  banca_iban varchar,
  banca_bic varchar,
  quietanzante varchar,
  importo_irpef_imponibile numeric,
  importo_imposta numeric,
  importo_inps_inponibile numeric,
  importo_ritenuta numeric,
  importo_netto numeric,
  cup varchar,
  cig varchar,
  resp_sett_amm varchar,
  cod_tributo varchar,
  resp_amm varchar,
  tit_miss_progr varchar,
  transaz_elementare varchar,
  elenco_reversali varchar,
  split_reverse varchar,
  importo_split_reverse numeric,
  anno_primo_impegno varchar,
  display_error varchar,
  cod_stato_mandato varchar,
  banca_cc_bitalia varchar,
  tipo_doc varchar,
  num_doc_ncd varchar,
  importo_da_dedurre_ncd numeric
) AS
$body$
DECLARE
elencoMandati record;
elencoImpegni record;
elencoLiquidazioni record;
elencoOneri	record;
elencoReversali record;
elencoNoteCredito record;
elencoClass record;
elencoAttr record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
posizione integer;
cod_atto_amm VARCHAR;
appStr VARCHAR;
annoImpegno VARCHAR;
numImpegno VARCHAR;
numSubImpegno VARCHAR;
dataMandatoStr VARCHAR;
numImpegnoApp VARCHAR;
numSubImpegnoApp VARCHAR;
cod_tipo_onere VARCHAR;
subDocumento VARCHAR;
numFatturaApp VARCHAR;
ImportoApp numeric;
anno_eser_int INTEGER;
conta_mandati_succ INTEGER;
max_data_flusso TIMESTAMP;
contaReversali INTEGER;
importoReversale NUMERIC;
importoSubDoc NUMERIC;
contaRecord INTEGER;
importoDaDedurre NUMERIC;
cod_programma VARCHAR;
cod_cofog VARCHAR;
cod_trans_europea VARCHAR;
cod_v_livello VARCHAR;
ricorrente_spesa VARCHAR;
perimetro_sanitario VARCHAR;
politiche_reg_unitarie VARCHAR;
cod_siope VARCHAR;
cod_titolo VARCHAR;
cod_missione VARCHAR;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
user_table	varchar;
sqlQuery varchar;
            
BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
cod_gestione='';
num_impegno='';
num_subimpegno='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
importo_stanz_cassa=0;
importo_tot_mandati_emessi=0;
importo_tot_mandati_dopo_emiss=0;
importo_dispon=0;
nome_tesoriere='';
desc_causale='';
desc_provvedimento='';
estremi_provvedimento='';
num_fattura='';
anno_fattura=0;
importo_fattura =0;
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
benef_indirizzo='';
benef_cap='';
benef_localita='';
benef_provincia='';
desc_mod_pagamento='';
bollo='';
banca_appoggio='';
banca_abi='';
banca_cab='';
banca_cc='';
banca_cc_estero='';
banca_cc_posta='';
banca_cc_bitalia='';
banca_cin='';
banca_iban='';
banca_bic='';
quietanzante='';
importo_irpef_imponibile=0;
importo_imposta=0;
importo_inps_inponibile=0;
importo_ritenuta=0;
importo_netto=0;
cup='';
cig='';
resp_sett_amm='';
cod_tributo='';
resp_amm='';
numero_fattura_completa='';
importo_documento=0;
transaz_elementare='';
num_sub_doc_fattura=0;
tit_miss_progr='';
cod_stato_mandato='';
tipo_doc='';
num_doc_ncd='';
importo_da_dedurre_ncd=0;

elenco_reversali='';
split_reverse='';
importo_split_reverse=0;
anno_primo_impegno='';
cod_programma='';
cod_cofog='';
cod_trans_europea='';
cod_v_livello='';
ricorrente_spesa='';
perimetro_sanitario='';
politiche_reg_unitarie='';
cod_siope='';

importoSubDoc=0;

anno_eser_int=p_anno ::INTEGER;

display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND 
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A", "DATA MANDATO DA/A" e "NUMERO DISTINTA".';
    return next;
    return;
end if;

select fnc_siac_random_user()
into	user_table;

contaRecord=0;

sqlQuery='with ord as (
	select  t_ordinativo.ord_id, 
		t_ordinativo_ts.ord_ts_id ,
		t_ordinativo.ente_proprietario_id,
		t_ordinativo.ord_anno, 
        COALESCE(t_ordinativo.ord_desc,'''') ord_desc,      
          -- se l''ordinativo e'' annullato l''importo e'' 0
        case when d_ord_stato.ord_stato_code <>''A''
        	then COALESCE(t_ord_ts_det.ord_ts_det_importo,0) 
            else 0 end ord_ts_det_importo,
        t_periodo.anno anno_eser,
        t_ordinativo.ord_numero,
        t_ordinativo.ord_emissione_data,
        COALESCE(t_ordinativo.ord_cast_emessi,0) ord_cast_emessi,
        d_ord_stato.ord_stato_code,
        COALESCE(cod_bollo.codbollo_code,'''') codbollo_code, 
        case when COALESCE(cod_bollo.codbollo_desc,'''') = '''' 
        	then ''ESENTE BOLLO'' 
            ELSE  cod_bollo.codbollo_desc end codbollo_desc,
        d_distinta.dist_code
from  siac_t_bil t_bil,
    siac_t_periodo t_periodo ,
    siac_t_ordinativo_ts t_ordinativo_ts,
	siac_t_ordinativo_ts_det t_ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_d_ordinativo_tipo d_ordinativo_tipo,
	siac_t_ordinativo t_ordinativo
    	LEFT  join siac_d_codicebollo cod_bollo
            on (cod_bollo.codbollo_id =t_ordinativo.codbollo_id 
                AND cod_bollo.data_cancellazione IS NULL)
        LEFT JOIN siac_d_distinta d_distinta
                	ON (d_distinta.dist_id=t_ordinativo.dist_id
                    	AND d_distinta.data_cancellazione IS NULL),
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato d_ord_stato
       /* LEFT JOIN siac_r_ordinativo_stato r_ord_stato
            ON (r_ord_stato.ord_id=t_ordinativo.ord_id
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ord_stato.validita_fine IS NULL)
        LEFT JOIN siac_d_ordinativo_stato d_ord_stato
            ON (d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
                AND d_ord_stato.data_cancellazione IS NULL)*/
where  t_bil.bil_id=t_ordinativo.bil_id
	AND t_periodo.periodo_id= t_bil.periodo_id   
	and t_ordinativo_ts.ord_id=t_ordinativo.ord_id
	and t_ord_ts_det.ord_ts_id=t_ordinativo_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id= t_ord_ts_det.ord_ts_det_tipo_id    
    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
    and r_ord_stato.ord_id=t_ordinativo.ord_id
    and d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
	and t_ordinativo.ente_proprietario_id ='||p_ente_prop_id;
    sqlQuery=sqlQuery|| ' AND t_ordinativo.ord_anno='||anno_eser_int;
    sqlQuery=sqlQuery|| ' and t_periodo.anno='''||p_anno||'''';
    if p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero between '||p_num_mandato_da;
        sqlQuery=sqlQuery|| ' and ' ||p_num_mandato_a;   
    elsif p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS  NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_mandato_da;
    elsif p_num_mandato_da IS  NULL AND p_num_mandato_a IS NOT NULL then
		sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_mandato_a;
    end if;  
    
    if p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') between to_timestamp('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')' || ' and to_timestamp(''' ||p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')';    	
    elsif  p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_mandato_da||'''::varchar,''yyyy-mm-dd'')';    
 	elsif  p_data_mandato_da IS  NULL AND p_data_mandato_a IS NOT NULL then
    	sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_mandato_a||'''::varchar,''yyyy-mm-dd'')';    	        	
    end if;
    
    if p_numero_distinta IS NOT NULL AND  p_numero_distinta <>'' then 
    	sqlQuery=sqlQuery|| ' and d_distinta.dist_code='''||p_numero_distinta||'''';
    end if;
    if p_stato_mandato <> 'TT' then
    	sqlQuery=sqlQuery|| ' and d_ord_stato.ord_stato_code='''||p_stato_mandato||'''';
    end if;
    
    sqlQuery=sqlQuery|| ' AND d_ordinativo_tipo.ord_tipo_code=''P'' /* PAGAMENTO */
    AND d_ord_ts_det_tipo.ord_ts_det_tipo_code =''A'' -- Importo Attuale
    AND t_periodo.data_cancellazione IS NULL 
    AND t_bil.data_cancellazione IS NULL 
    and t_ordinativo.data_cancellazione IS NULL   
    and t_ordinativo_ts.data_cancellazione IS NULL
    and t_ord_ts_det.data_cancellazione IS NULL
    and d_ord_ts_det_tipo.data_cancellazione IS NULL
    and d_ordinativo_tipo.data_cancellazione IS NULL
    AND r_ord_stato.data_cancellazione IS NULL
    AND r_ord_stato.validita_fine IS NULL
    AND d_ord_stato.data_cancellazione IS NULL),
strut_bil as (
  select *  
      from fnc_bilr_struttura_cap_bilancio_spese ('||p_ente_prop_id||',
      		'''||p_anno||''','''||user_table||''')  ) ,
ele_cap as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code=''PROGRAMMA'' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code=''MACROAGGREGATO''						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id='||p_ente_prop_id||' 						and
   	anno_eserc.anno='''|| p_anno||'''										and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = ''CAP-UG''						     		and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	''VA''								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		--and    	
	--cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null),
cap as (
	select r_ordinativo_bil_elem.ord_id,
		COALESCE(a.elem_code,'''') elem_code,
        COALESCE(b.missione_code,'''') missione_code, 
        COALESCE(b.programma_code,'''') programma_code,
        COALESCE(b.titusc_code,'''') titusc_code,
        COALESCE(t_bil_elem.elem_code,'''') cod_cap, 
        COALESCE(t_bil_elem.elem_code2,'''') cod_art,
        t_bil_elem.elem_id
	from siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
        siac_t_bil_elem t_bil_elem  
        left join ele_cap a
          ON (a.elem_id=t_bil_elem.elem_id)             
      LEFT JOIN strut_bil   b 
          ON (b.programma_id = a.programma_id    
          and	b.macroag_id	= a.macroaggregato_id
          and b.ente_proprietario_id='||p_ente_prop_id;
          sqlQuery=sqlQuery|| ' and	b.ente_proprietario_id	=a.ente_proprietario_id          
          and b.utente='''|| user_table||''')';              
    sqlQuery=sqlQuery|| ' where r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id 
    	and r_ordinativo_bil_elem.ente_proprietario_id ='||p_ente_prop_id;
    	sqlQuery=sqlQuery|| ' and r_ordinativo_bil_elem.data_cancellazione IS NULL
        and t_bil_elem.data_cancellazione IS NULL),
ente as (
	select  COALESCE(OL.ente_oil_resp_ord,'''') ente_oil_resp_ord, 
        COALESCE(OL.ente_oil_tes_desc,'''') ente_oil_tes_desc, 
        COALESCE(OL.ente_oil_resp_amm,'''') ente_oil_resp_amm,  
        ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente,
        ep.ente_proprietario_id
		from siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL
    where  ep.ente_proprietario_id =OL.ente_proprietario_id
        and ep.ente_proprietario_id='||p_ente_prop_id;
        sqlQuery=sqlQuery|| ' and ep.data_cancellazione IS NULL
        and ol.data_cancellazione IS NULL) ,
doc as (
      select r_subdoc_ordinativo_ts.ord_ts_id,
          COALESCE(t_doc.doc_numero,'''') doc_numero, 
          COALESCE(t_doc.doc_anno,0) doc_anno, 
          COALESCE(t_doc.doc_importo,0) doc_importo,
          t_doc.doc_id, t_subdoc.subdoc_id,
          COALESCE(t_subdoc.subdoc_numero,0) subdoc_numero, 
          COALESCE(t_subdoc.subdoc_importo,0) subdoc_importo, 
          COALESCE(d_doc_tipo.doc_tipo_code,'''') doc_tipo_code
    from siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
            siac_t_subdoc t_subdoc,
            siac_t_doc 	t_doc
            LEFT JOIN siac_d_doc_tipo d_doc_tipo
                ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                    AND d_doc_tipo.data_cancellazione IS NULL)
    where t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
        AND t_doc.doc_id=  t_subdoc.doc_id
        and r_subdoc_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id;   
        sqlQuery=sqlQuery|| ' AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
        AND t_subdoc.data_cancellazione IS NULL
        AND t_doc.data_cancellazione IS NULL),
sogg as (
	select r_ord_soggetto.ord_id,
        COALESCE(t_soggetto.codice_fiscale,'''') codice_fiscale,
        COALESCE(t_soggetto.partita_iva,'''') partita_iva, 
        COALESCE(t_soggetto.soggetto_desc,'''') soggetto_desc,                 
        COALESCE(d_via_tipo.via_tipo_desc,'''') via_tipo_desc, COALESCE(t_ind_soggetto.toponimo,'''') toponimo, 
        COALESCE(t_ind_soggetto.numero_civico,'''') numero_civico,
        COALESCE(t_ind_soggetto.zip_code,'''') zip_code, COALESCE(t_comune.comune_desc,'''') comune_desc, 
        COALESCE(t_provincia.sigla_automobilistica,'''') sigla_automobilistica
    from  siac_r_ordinativo_soggetto r_ord_soggetto,
          siac_t_soggetto t_soggetto
            LEFT JOIN siac_t_indirizzo_soggetto t_ind_soggetto
                ON (t_ind_soggetto.soggetto_id=t_soggetto.soggetto_id
                    AND t_ind_soggetto.principale=''S''
                    AND t_ind_soggetto.data_cancellazione IS NULL)
            LEFT JOIN siac_d_via_tipo d_via_tipo
                ON (d_via_tipo.via_tipo_id=t_ind_soggetto.via_tipo_id
                    AND d_via_tipo.data_cancellazione IS NULL)
            LEFT JOIN siac_t_comune t_comune
                ON (t_comune.comune_id=t_ind_soggetto.comune_id
                    AND t_comune.data_cancellazione IS NULL)
            LEFT JOIN siac_r_comune_provincia r_comune_provincia
                ON (r_comune_provincia.comune_id=t_comune.comune_id
                    AND r_comune_provincia.data_cancellazione IS NULL)
            LEFT JOIN siac_t_provincia t_provincia
                ON (t_provincia.provincia_id=r_comune_provincia.provincia_id
                    AND t_provincia.data_cancellazione IS NULL)   
    where t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
    	and r_ord_soggetto.ente_proprietario_id='||p_ente_prop_id;                  	
        sqlQuery=sqlQuery|| ' AND t_soggetto.data_cancellazione IS NULL 
        and r_ord_soggetto.data_cancellazione IS NULL ),
attoamm as (
	select r_liquid_ord.sord_id, r_liquid_ord.liq_id,
    	t_atto_amm.attoamm_numero,t_atto_amm.attoamm_anno,
        t_atto_amm.attoamm_note attoamm_note,
    	t_atto_amm1.attoamm_numero attoamm_numero_movgest,
        t_atto_amm1.attoamm_anno attoamm_anno_movgest,
        t_atto_amm1.attoamm_note attoamm_note,
        COALESCE(t_class.classif_code,'''') strut_amm_resp,
        COALESCE(t_class1.classif_code,'''') strut_amm_resp_movgest,
        COALESCE(d_atto_amm_tipo.attoamm_tipo_code,'''') attoamm_tipo_code,
        COALESCE(d_atto_amm_tipo.attoamm_tipo_desc,'''') attoamm_tipo_desc,
        COALESCE(d_atto_amm_tipo1.attoamm_tipo_code,'''') attoamm_tipo_code_movgest,
        COALESCE(d_atto_amm_tipo1.attoamm_tipo_desc,'''') attoamm_tipo_desc_movgest
    from siac_r_liquidazione_ord r_liquid_ord                	
          LEFT JOIN siac_r_liquidazione_atto_amm r_liquid_att_amm
              ON (r_liquid_att_amm.liq_id= r_liquid_ord.liq_id
                  AND r_liquid_att_amm.data_cancellazione IS NULL)
          LEFT JOIN siac_t_atto_amm t_atto_amm
              ON (t_atto_amm.attoamm_id=r_liquid_att_amm.attoamm_id
                  AND t_atto_amm.data_cancellazione IS NULL)
          LEFT JOIN siac_d_atto_amm_tipo d_atto_amm_tipo
              ON (d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
                  AND d_atto_amm_tipo.data_cancellazione IS NULL)
          LEFT JOIN siac_r_atto_amm_class r_atto_amm_class
              ON (r_atto_amm_class.attoamm_id=t_atto_amm.attoamm_id
                  AND r_atto_amm_class.data_cancellazione IS NULL)
          LEFT JOIN siac_t_class t_class
              ON (t_class.classif_id= r_atto_amm_class.classif_id
                  AND t_class.data_cancellazione IS NULL)
          LEFT JOIN siac_d_class_tipo d_class_tipo
              ON (d_class_tipo.classif_tipo_id= t_class.classif_tipo_id
                  AND d_class_tipo.data_cancellazione IS NULL)       
          LEFT JOIN siac_r_liquidazione_movgest r_liq_movgest
              ON (r_liq_movgest.liq_id=r_liquid_ord.liq_id
                  AND  r_liq_movgest.data_cancellazione IS NULL)                                
          LEFT JOIN siac_r_movgest_ts_atto_amm  r_movgest_ts_atto_amm
              ON (r_movgest_ts_atto_amm.movgest_ts_id=r_liq_movgest.movgest_ts_id                                         
                  AND r_movgest_ts_atto_amm.data_cancellazione IS NULL) 
          LEFT JOIN siac_t_atto_amm t_atto_amm1
              ON (t_atto_amm1.attoamm_id=r_movgest_ts_atto_amm.attoamm_id
                  AND t_atto_amm1.data_cancellazione IS NULL)
          LEFT JOIN siac_d_atto_amm_tipo d_atto_amm_tipo1
              ON (d_atto_amm_tipo1.attoamm_tipo_id=t_atto_amm1.attoamm_tipo_id
                  AND d_atto_amm_tipo1.data_cancellazione IS NULL)
          LEFT JOIN siac_r_atto_amm_class r_atto_amm_class1
              ON (r_atto_amm_class1.attoamm_id=t_atto_amm1.attoamm_id
                  AND r_atto_amm_class1.data_cancellazione IS NULL)
          LEFT JOIN siac_t_class t_class1
              ON (t_class1.classif_id= r_atto_amm_class1.classif_id
                  AND t_class1.data_cancellazione IS NULL)
          LEFT JOIN siac_d_class_tipo d_class_tipo1
              ON (d_class_tipo1.classif_tipo_id= t_class1.classif_tipo_id
                  AND d_class_tipo1.data_cancellazione IS NULL) 
	where r_liquid_ord.ente_proprietario_id ='||p_ente_prop_id;
sqlQuery=sqlQuery|| ' and r_liquid_ord.data_cancellazione IS NULL),
cigord as (
		select  t_attr.attr_code attr_code_cig_ord, 
        		r_ordinativo_attr.testo testo_cig_ord,
				r_ordinativo_attr.ord_id
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id          
                  and t_attr.ente_proprietario_id='||p_ente_prop_id;         
             sqlQuery=sqlQuery|| ' AND upper(t_attr.attr_code) = ''CIG''           
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL),
cupord as (
		select  t_attr.attr_code attr_code_cup_ord, 
        		r_ordinativo_attr.testo testo_cup_ord,
				r_ordinativo_attr.ord_id
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id          
                  and t_attr.ente_proprietario_id='||p_ente_prop_id;         
             sqlQuery=sqlQuery|| ' AND upper(t_attr.attr_code) = ''CUP''            
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL),
cigliq as ( 
			SELECT t_attr.attr_code attr_code_cig_liq, 
            	r_liquidazione_attr.testo testo_cig_liq,
                r_liqu_ord.sord_id           
            FROM siac_t_liquidazione	liquidazione, 
                    siac_r_liquidazione_ord r_liqu_ord,
                    siac_r_liquidazione_attr r_liquidazione_attr,
                    siac_t_attr t_attr                                                
            WHERE liquidazione.liq_id=r_liqu_ord.liq_id
                    AND r_liquidazione_attr.liq_id=liquidazione.liq_id
                    AND t_attr.attr_id=r_liquidazione_attr.attr_id                                
                    AND upper(t_attr.attr_code) = ''CIG''  
                    /* Da usare l''ID della testata dell''ordinativo e 
                          non quello dell''ordinativo */ 
                   AND   r_liqu_ord.ente_proprietario_id='||p_ente_prop_id;  
  sqlQuery=sqlQuery|| ' AND  liquidazione.data_cancellazione IS NULL   
                   AND  r_liquidazione_attr.data_cancellazione IS NULL 
                   AND  t_attr.data_cancellazione IS NULL),
cupliq as ( 
			SELECT t_attr.attr_code attr_code_cup_liq, 
            	r_liquidazione_attr.testo testo_cup_liq,
                r_liqu_ord.sord_id           
            FROM siac_t_liquidazione	liquidazione, 
                    siac_r_liquidazione_ord r_liqu_ord,
                    siac_r_liquidazione_attr r_liquidazione_attr,
                    siac_t_attr t_attr                                                
            WHERE liquidazione.liq_id=r_liqu_ord.liq_id
                    AND r_liquidazione_attr.liq_id=liquidazione.liq_id
                    AND t_attr.attr_id=r_liquidazione_attr.attr_id                                
                    AND upper(t_attr.attr_code) = ''CUP''  
                    /* Da usare l''ID della testata dell''ordinativo e 
                          non quello dell''ordinativo */ 
                   AND   r_liqu_ord.ente_proprietario_id='||p_ente_prop_id;  
  sqlQuery=sqlQuery|| ' AND  liquidazione.data_cancellazione IS NULL   
                   AND  r_liquidazione_attr.data_cancellazione IS NULL 
                   AND  t_attr.data_cancellazione IS NULL),
  impegni as (
  	select  *
    	from fnc_bilr144_tab_impegni ('||p_ente_prop_id||')  ),
  ncd as ( 
  	select *  
    from fnc_bilr144_tab_reversali  ('||p_ente_prop_id||')  ) ,
  classif as ( 
  	select *  
    from fnc_bilr144_tab_classif  ('||p_ente_prop_id||')  )  ,
  elenco_ncd as ( 
  	select *  
    from fnc_bilr144_tab_ncd  ('||p_ente_prop_id||')  )  , 
  modpag as ( 
  	select *  
    from fnc_bilr144_tab_modpag  ('||p_ente_prop_id||')  )  ,            
importo_ncd as (
select  t_ordinativo_ts.ord_id, 
		sum(COALESCE(t_subdoc.subdoc_importo_da_dedurre,0)) 
        		subdoc_importo_da_dedurre            
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
                siac_t_subdoc t_subdoc            
            where r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id
            AND t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id             
            AND r_subdoc_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id; 
sqlQuery=sqlQuery|| ' AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL                                 
            group by t_ordinativo_ts.ord_id)                                                               			          
select 
	ente.ente_denominazione::varchar nome_ente ,
	ente.cod_fisc_ente::varchar partita_iva_ente ,
  	ord.anno_eser::integer anno_ese_finanz ,
  	ord.ord_anno::integer anno_capitolo ,
    cap.cod_cap::varchar cod_capitolo ,
    cap.cod_art::varchar cod_articolo ,
  	classif.cod_gestione::varchar ,
  	impegni.num_impegno::varchar ,
  	''''::varchar num_subimpegno ,
    ord.ord_ts_det_importo::numeric importo_lordo_mandato ,
    ord.ord_numero::integer numero_mandato ,
    ord.ord_emissione_data::date data_mandato ,
  	0::numeric importo_stanz_cassa ,
  	ord.ord_cast_emessi::numeric importo_tot_mandati_emessi ,
    (ord.ord_cast_emessi+ord.ord_ts_det_importo)::numeric importo_tot_mandati_dopo_emiss,
  	0::numeric importo_dispon ,
  	ente.ente_oil_tes_desc::varchar nome_tesoriere ,
    -- il campo desc_causale nel report e'' concatenato con CUP e CIG se esistenti.
  	ord.ord_desc::varchar desc_causale ,  
  case when attoamm.attoamm_tipo_code not in (''ALG'', ''SPR'')
  		then attoamm.attoamm_tipo_desc::varchar
        else attoamm.attoamm_tipo_desc_movgest::varchar end desc_provvedimento,
  case when attoamm.attoamm_tipo_code not in (''ALG'', ''SPR'')
  		then trim(attoamm.strut_amm_resp||'' N.''||attoamm.attoamm_numero||
        	'' DEL ''||attoamm.attoamm_anno)::varchar
        else trim(attoamm.strut_amm_resp_movgest||'' N.''||attoamm.attoamm_numero_movgest||
        	'' DEL ''||attoamm.attoamm_anno_movgest)::varchar end estremi_provvedimento,     
 ''''::varchar  numero_fattura_completa ,
  case when doc.doc_numero <>'''' 
  		then  (doc.doc_numero||''/''||doc.subdoc_numero)::varchar 
		else ''''::varchar  end num_fattura ,
  COALESCE(doc.doc_anno::integer,0)::integer anno_fattura ,
  COALESCE(doc.doc_importo,0)::numeric importo_documento  ,
  COALESCE(doc.subdoc_numero::integer,0)::integer  num_sub_doc_fattura,
  COALESCE(doc.subdoc_importo,0)::numeric importo_fattura ,
  	 -- carico il codice fiscale solo se non esiste la partita iva
  case when COALESCE(sogg.partita_iva,'''')=''''
  		then sogg.codice_fiscale::varchar
        else ''''::varchar end benef_cod_fiscale,        
   sogg.partita_iva::varchar benef_partita_iva,
   sogg.soggetto_desc::varchar benef_nome ,
     upper(sogg.via_tipo_desc||'' ''||sogg.toponimo||'' ''||
    		sogg.numero_civico)::varchar benef_indirizzo     ,
    sogg.zip_code::varchar benef_cap ,        
    sogg.comune_desc::varchar benef_localita,
    sogg.sigla_automobilistica::varchar benef_provincia,  
  	modpag.desc_mod_pagamento::varchar ,
    ord.codbollo_desc::varchar bollo ,
   	''''::varchar banca_appoggio ,
    modpag.banca_abi::varchar ,
    modpag.banca_cab::varchar ,
    modpag.banca_cc::varchar ,
    modpag.banca_cc_estero::varchar ,
    modpag.banca_cc_posta::varchar ,
    modpag.banca_cin::varchar ,
    modpag.banca_iban::varchar ,
    modpag.banca_bic::varchar ,
  	 case when modpag.quietanziante_codice_fiscale=''''
     		then modpag.quietanziante::varchar
            else (modpag.quietanziante_codice_fiscale||
      	'' - '' ||modpag.quietanziante)::varchar end quietanzante ,      
  COALESCE(ncd.importo_irpef_imponibile,0)::numeric importo_irpef_imponibile ,
  COALESCE(ncd.importo_imposta,0)::numeric importo_imposta ,
  COALESCE(ncd.importo_inps_inponibile,0)::numeric importo_inps_inponibile ,
  COALESCE(ncd.importo_ritenuta,0::numeric) importo_ritenuta ,
  (COALESCE(ord.ord_ts_det_importo,0)-
    	COALESCE(ncd.importo_ritenuta,0)-
        COALESCE(ncd.importo_imposta,0)-
        COALESCE(ncd.importo_split_reverse,0))::numeric importo_netto,    
  case when COALESCE(cupord.attr_code_cup_ord,'''')='''' or COALESCE(cupord.testo_cup_ord,'''')=''''  
        	then COALESCE(cupliq.testo_cup_liq,'''')::varchar
            else cupord.testo_cup_ord::varchar end cup , 
  case when COALESCE(cigord.attr_code_cig_ord,'''')='''' or COALESCE(cigord.testo_cig_ord,'''')='''' 
        	then COALESCE(cigliq.testo_cig_liq,'''')::varchar 
            else cigord.testo_cig_ord::varchar end cig,
  ente.ente_oil_resp_ord::varchar resp_sett_amm ,
  COALESCE(ncd.cod_tributo,'''')::varchar cod_tributo,
  ente.ente_oil_resp_amm::varchar resp_amm ,
  (cap.programma_code||cap.titusc_code)::varchar tit_miss_progr ,
  case when COALESCE(cupord.attr_code_cup_ord,'''')='''' or COALESCE(cupord.testo_cup_ord,'''')=''''  
        	then (cap.programma_code||classif.cod_v_livello||classif.cod_cofog||
  	classif.cod_trans_europea||classif.cod_siope||COALESCE(cupliq.testo_cup_liq,'''')
    	||classif.ricorrente_spesa||classif.perimetro_sanitario
        ||classif.politiche_reg_unitarie)::varchar
            else (cap.programma_code||classif.cod_v_livello||classif.cod_cofog||
  	classif.cod_trans_europea||classif.cod_siope||COALESCE(cupord.testo_cup_ord,'''')
    	||classif.ricorrente_spesa||classif.perimetro_sanitario
        ||classif.politiche_reg_unitarie)::varchar
    	end   transaz_elementare ,
  COALESCE(ncd.elenco_reversali,'''')::varchar elenco_reversali,
  COALESCE(ncd.split_reverse,'''')::varchar split_reverse ,
  COALESCE(ncd.importo_split_reverse,0)::numeric importo_split_reverse , 
  COALESCE(impegni.anno_primo_impegno,'''')::varchar  anno_primo_impegno ,
  ''''::varchar display_error ,
  upper(ord.ord_stato_code)::varchar cod_stato_mandato,
  modpag.banca_cc_bitalia::varchar ,
  COALESCE(doc.doc_tipo_code,'''')::varchar tipo_doc ,
  COALESCE(elenco_ncd.num_doc_ncd,'''')::varchar num_doc_ncd,   
  COALESCE(importo_ncd.subdoc_importo_da_dedurre,0)::numeric importo_da_dedurre_ncd    
	from ord
        left join doc on ord.ord_ts_id=doc.ord_ts_id
        left join elenco_ncd on doc.doc_id=elenco_ncd.doc_id        
        left join sogg on ord.ord_id=sogg.ord_id       
        left join attoamm on ord.ord_ts_id= attoamm.sord_id
        left join cigord on ord.ord_id= cigord.ord_id
        left join cupord on ord.ord_id= cupord.ord_id
        left join cigliq on ord.ord_ts_id= cigliq.sord_id
        left join cupliq on ord.ord_ts_id= cupliq.sord_id
        left join impegni on ord.ord_id= impegni.ord_id 
        left join ncd on ord.ord_id= ncd.ord_id 
        left join classif on ord.ord_id= classif.ord_id
        left join importo_ncd on ord.ord_id= importo_ncd.ord_id 
        left join modpag on ord.ord_id= modpag.ord_id ,
        cap, ente
where ord.ord_id=cap.ord_id
	and ord.ente_proprietario_id=ente.ente_proprietario_id
order by ord.ord_numero, ord.ord_emissione_data, 
doc_numero, subdoc_numero';

raise notice 'Query = %', sqlQuery;

return query execute sqlQuery;


exception
	when no_data_found THEN
		raise notice 'Nessun mandato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5187 FINE

-- SIAC-5123 INIZIO

DROP TABLE IF EXISTS siac.siac_clearo_impegnato_quietanzato;

CREATE TABLE siac.siac_clearo_impegnato_quietanzato (
  ente_proprietario_id INTEGER,
  anno_bilancio VARCHAR(4),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(500),
  desc_stato_atto_amministrativo VARCHAR(500),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  impegnato NUMERIC,
  quietanzato NUMERIC,
  cod_soggetto VARCHAR(200),
  desc_soggetto VARCHAR(500),
  cf_soggetto CHAR(16),
  cf_estero_soggetto VARCHAR(500),
  p_iva_soggetto VARCHAR(500),
  cod_classe_soggetto VARCHAR(200),
  desc_classe_soggetto VARCHAR(500),
  tipo_impegno VARCHAR(200),
  tipo_importo CHAR(1),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
) 
WITH (oids = false);

CREATE OR REPLACE FUNCTION siac.fnc_siac_clearo_impegnato_quietanzato (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

  anno_bilancio_int integer;

BEGIN

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;   
END IF;

DELETE FROM  siac_clearo_impegnato_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

/*DELETE FROM  siac_clearo_impegnato
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

DELETE FROM  siac_clearo_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;*/

anno_bilancio_int := p_anno_bilancio::integer;

-- Dati estratti per l'impegnato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
AND b.attoamm_anno >= p_anno_bilancio
AND a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
)
, impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
t_movgest.movgest_anno, 
t_movgest.movgest_numero,
t_movgest_ts.movgest_ts_code,
d_movgest_ts_tipo.movgest_ts_tipo_code,
t_movgest_ts_det.movgest_ts_det_importo
FROM siac_t_movgest t_movgest,
siac_t_bil t_bil,
siac_t_periodo t_periodo,
siac_t_movgest_ts t_movgest_ts,    
siac_d_movgest_tipo d_movgest_tipo,            
siac_t_movgest_ts_det t_movgest_ts_det,
siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
siac_d_movgest_ts_tipo d_movgest_ts_tipo,
siac_r_movgest_ts_stato r_movgest_ts_stato,
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
AND t_movgest.movgest_anno = anno_bilancio_int
AND t_movgest.parere_finanziario = 'TRUE'
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
AND d_movgest_stato.movgest_stato_code = 'D' 
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND t_movgest_ts_det.data_cancellazione IS NULL
AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
)
, t_flagDaRiaccertamento as (
SELECT 
a.movgest_ts_id,
a."boolean" flagDaRiaccertamento
FROM  siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE b.attr_code='flagDaRiaccertamento' 
AND a.ente_proprietario_id = p_ente_proprietario_id 
AND a.attr_id = b.attr_id
AND a."boolean"  = 'N'
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)
, sogg as (SELECT 
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)
, sogcla as (SELECT 
a.movgest_ts_id,
b.soggetto_classe_code, b.soggetto_classe_desc
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE a.ente_proprietario_id = p_ente_proprietario_id 
AND a.soggetto_classe_id = b.soggetto_classe_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)
--INSERT INTO siac_clearo_impegnato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 impegnato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 cod_classe_soggetto,
 desc_classe_soggetto,
 tipo_impegno,
 tipo_importo)   
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero, 
--impegnato.movgest_ts_det_importo, 
COALESCE(SUM(impegnato.movgest_ts_det_importo),0) importo_impegnato,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
INNER JOIN t_flagDaRiaccertamento ON t_flagDaRiaccertamento.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogg ON sogg.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogcla ON sogcla.movgest_ts_id = impegnato.movgest_ts_id
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno,
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
sogg.soggetto_code, 
sogg.soggetto_desc, 
sogg.codice_fiscale, 
sogg.codice_fiscale_estero, 
sogg.partita_iva,
sogcla.soggetto_classe_code, 
sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'::varchar;

-- Dati estratti per il quietanzato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b 
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
AND b.attoamm_anno >= p_anno_bilancio
AND a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
),
impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
t_movgest.movgest_anno, 
t_movgest.movgest_numero,
t_movgest_ts.movgest_ts_code,
d_movgest_ts_tipo.movgest_ts_tipo_code
FROM siac_t_movgest t_movgest,
siac_t_bil t_bil,
siac_t_periodo t_periodo,
siac_t_movgest_ts t_movgest_ts,    
siac_d_movgest_tipo d_movgest_tipo,            
siac_d_movgest_ts_tipo d_movgest_ts_tipo,
siac_r_movgest_ts_stato r_movgest_ts_stato,
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
--AND t_movgest.movgest_anno = 2017
AND t_movgest.parere_finanziario = 'TRUE' -- Da considrare?  24.08.2017 Sofia secondo me deve rimanere
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_stato.movgest_stato_code = 'D' -- Da considrare? 24.08.2017 Sofia secondo me deve rimanere
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' -- solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
),
impliquidatoquietanzato AS (
WITH quietanzato AS (
  SELECT e.ord_ts_det_importo, a.ord_id, b.ord_ts_id
  FROM 
  siac_t_ordinativo a,
  siac_t_ordinativo_ts b,
  siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
  siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
  WHERE a.ente_proprietario_id = p_ente_proprietario_id 
  AND  a.ord_id = b.ord_id
  AND  c.ord_id = b.ord_id
  AND  c.ord_stato_id = d.ord_stato_id
  AND  e.ord_ts_id = b.ord_ts_id
  AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
  AND  d.ord_stato_code= 'Q'
  AND  f.ord_ts_det_tipo_code = 'A'  
  AND  a.data_cancellazione IS NULL
  AND  b.data_cancellazione IS NULL
  AND  c.data_cancellazione IS NULL 
  AND  d.data_cancellazione IS NULL  
  AND  e.data_cancellazione IS NULL
  AND  f.data_cancellazione IS NULL
  AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)            
  )
, sogg AS (SELECT 
a.ord_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_ordinativo_soggetto a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)
SELECT 
quietanzato.ord_ts_det_importo,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, 
sogg.codice_fiscale_estero, sogg.partita_iva,
b.movgest_ts_id
FROM  quietanzato
INNER JOIN sogg ON quietanzato.ord_id = sogg.ord_id
INNER JOIN siac_r_liquidazione_ord a ON  a.sord_id = quietanzato.ord_ts_id
INNER JOIN siac_r_liquidazione_movgest b ON b.liq_id = a.liq_id
WHERE a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine,p_data)
)
--INSERT INTO siac_clearo_quietanzato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 quietanzato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 tipo_impegno,
 tipo_importo)
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero,
-- impliquidatoquietanzato.ord_ts_det_importo,
COALESCE(SUM(impliquidatoquietanzato.ord_ts_det_importo),0) importo_quietanzato,  
impliquidatoquietanzato.soggetto_code, impliquidatoquietanzato.soggetto_desc, impliquidatoquietanzato.codice_fiscale, 
impliquidatoquietanzato.codice_fiscale_estero, impliquidatoquietanzato.partita_iva,
impegnato.movgest_ts_tipo_code,
'Q'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
INNER JOIN impliquidatoquietanzato ON impliquidatoquietanzato.movgest_ts_id = provvedimenti.movgest_ts_id
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, 
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
impliquidatoquietanzato.soggetto_code, 
impliquidatoquietanzato.soggetto_desc, 
impliquidatoquietanzato.codice_fiscale, 
impliquidatoquietanzato.codice_fiscale_estero, 
impliquidatoquietanzato.partita_iva,
impegnato.movgest_ts_tipo_code,
'Q'::varchar;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegnato quietanzato (FNC_SIAC_CLEARO_IMPEGNATO_QUIETANZATO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC-5123 FINE

-- SIAC-5199 INIZIO - Sofia

CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  bil_ele_code3 varchar,
  code_cofog varchar,
  code_transaz_ue varchar,
  pdc_iv varchar,
  perim_sanitario_spesa varchar,
  ricorrente_spesa varchar,
  cup varchar,
  ord_id integer,
  ord_importo numeric,
  movgest_id integer,
  anno_movgest integer,
  movgest_importo numeric,
  fondo_plur_vinc numeric
) AS
$body$
DECLARE



classifBilRec record;
bilancio_id integer;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';
select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

return query
select zz.* from (
with clas as (
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
--insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
from missione , programma
,titusc, macroag
, siac_r_class progmacro
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 ),
capall as (
with
cap as (
select a.elem_id,
a.elem_code ,
a.elem_desc ,
a.elem_code2 ,
a.elem_desc2 ,
a.elem_id_padre ,
a.elem_code3,
d.classif_id programma_id,d2.classif_id macroag_id
from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
siac_r_bil_elem_class c2,
siac_t_class d,siac_t_class d2,
siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.elem_tipo_id=a.elem_tipo_id
and b.elem_tipo_code = 'CAP-UG'
and c.elem_id=a.elem_id
and c2.elem_id=a.elem_id
and d.classif_id=c.classif_id
and d2.classif_id=c2.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e2.classif_tipo_id=d2.classif_tipo_id
and e.classif_tipo_code='PROGRAMMA'
and e2.classif_tipo_code='MACROAGGREGATO'
and g.elem_cat_id=f.elem_cat_id
and f.elem_id=a.elem_id
and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
and h.elem_id=a.elem_id
and i.elem_stato_id=h.elem_stato_id
and i.elem_stato_code = 'VA'
and h.validita_fine is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and d2.data_cancellazione is null
and e.data_cancellazione is null
and e2.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
), 
elenco_movgest as (
select distinct
r.elem_id, a.movgest_id,b.movgest_ts_id,
a.movgest_anno,
coalesce(o.movgest_ts_det_importo,0) movgest_importo
 from  siac_t_movgest a, 
 	siac_t_movgest_ts b,  
 	siac_t_movgest_ts_det o,
	siac_d_movgest_ts_det_tipo p,
    siac_d_movgest_tipo q,
    siac_r_movgest_bil_elem r ,
    siac_r_movgest_ts_stato s,
    siac_d_movgest_stato t,
    siac_d_movgest_ts_tipo u
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
-- VERIFICARE SE E' GIUSTO PRENDERE ANCHE I MOVGEST > 2017
-- PER estrarre Impegnato reimputato ad esercizi successivi
--and a.movgest_anno<=p_anno::INTEGER
and o.movgest_ts_id=b.movgest_ts_id
and p.movgest_ts_det_tipo_id=o.movgest_ts_det_tipo_id
and q.movgest_tipo_id=a.movgest_tipo_id
and r.movgest_id=a.movgest_id
and s.movgest_ts_id=b.movgest_ts_id
and t.movgest_stato_id=s.movgest_stato_id
and u.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and q.movgest_tipo_code='I'
and p.movgest_ts_det_tipo_code='A' -- importo attuale
and t.movgest_stato_code in ('D','N') 
and u.movgest_ts_tipo_code='T' 
and a.data_cancellazione is null
and b.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null
and u.data_cancellazione is null
and s.validita_fine is NULL
),
elenco_ord as(
select 
l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno,
sum(coalesce(m.ord_ts_det_importo,0)) ord_importo
 from  siac_T_movgest a, siac_t_movgest_ts b,
 siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e, 
siac_t_ordinativo f,
siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
--and a.movgest_anno<= p_anno::INTEGER
and c.validita_fine is NULL
and d.validita_fine is NULL
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and g.ord_tipo_code='P'
and h.ord_id=f.ord_id
and i.ord_stato_id=h.ord_stato_id
and i.ord_stato_code<>'A'
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
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
group by l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno
)/*,
fondo_plur as (select a.elem_id, sum (coalesce(f.elem_det_importo,0))   as fondo
from siac_t_bil_elem a,siac_r_bil_elem_stato b, siac_d_bil_elem_stato c,
siac_r_bil_elem_categoria d,siac_d_bil_elem_categoria e,
siac_t_bil_elem_det f,siac_d_bil_elem_det_tipo g,siac_t_periodo h
where  b.elem_id=a.elem_id
and c.elem_stato_id=b.elem_stato_id
and c.elem_stato_code='VA'
and a.ente_proprietario_id=p_ente_prop_id
and b.validita_fine is NULL
and d.elem_id=a.elem_id and e.elem_cat_id=d.elem_cat_id
and e.elem_cat_code	in	('FPV','FPVCC','FPVSC')
and d.validita_fine is NULL
and f.elem_id=a.elem_id and g.elem_det_tipo_id=f.elem_det_tipo_id
and g.elem_det_tipo_code='STA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and a.bil_id=bilancio_id
and h.data_cancellazione is null
and h.periodo_id=f.periodo_id
and h.anno=p_anno
group by a.elem_id)*/,
elenco_pdci_IV as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code pdc_iv
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_IV'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null),
elenco_pdci_V as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code classif_code_cap,
  substring(t_class.classif_code from 1 for length(t_class.classif_code)-3) ||
          '000' pdc_v
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_V'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null) ,                    
elenco_class_capitoli as (
	select * from "fnc_bilr153_tab_class_capitoli"  (p_ente_prop_id)),                    
elenco_class_movgest as (
	select * from "fnc_bilr153_tab_class_movgest"  (p_ente_prop_id)),
elenco_class_ord as (
	select * from "fnc_bilr153_tab_class_ord"  (p_ente_prop_id)) ,
cupord as (
		select DISTINCT t_attr.attr_code attr_code_cup_ord, 
        		trim(r_ordinativo_attr.testo) testo_cup_ord,
				r_ordinativo_attr.ord_id                
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id   
              and  t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL) ,
cup_movgest as(
	select DISTINCT t_attr.attr_code attr_code_cup_movgest, 
          trim(r_movgest_ts_attr.testo) testo_cup_movgest,
          r_movgest_ts_attr.movgest_ts_id,
          t_movgest_ts.movgest_id
        from 
               siac_t_attr t_attr,
               siac_r_movgest_ts_attr  r_movgest_ts_attr,
               siac_t_movgest_ts t_movgest_ts
              where  r_movgest_ts_attr.attr_id=t_attr.attr_id                 	
                and t_movgest_ts.movgest_ts_id = r_movgest_ts_attr.movgest_ts_id      
                  and t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_movgest_ts_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL
                  and t_movgest_ts.data_cancellazione IS NULL)                      
select distinct
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.programma_id,cap.macroag_id,
COALESCE(elenco_class_capitoli.code_cofog,'') code_cofog_cap,
COALESCE(elenco_class_capitoli.code_transaz_ue,'') code_transaz_ue_cap,
COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') perim_sanitario_spesa_cap,
COALESCE(elenco_class_capitoli.ricorrente_spesa,'') ricorrente_spesa_cap,
COALESCE(elenco_class_movgest.code_cofog,'') code_cofog_movgest,
COALESCE(elenco_class_movgest.code_transaz_ue,'') code_transaz_ue_movgest,
COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') perim_sanitario_spesa_movgest,
COALESCE(elenco_class_movgest.ricorrente_spesa,'') ricorrente_spesa_movgest,
COALESCE(elenco_class_ord.code_cofog,'') code_cofog_ord,
COALESCE(elenco_class_ord.code_transaz_ue,'') code_transaz_ue_ord,
COALESCE(elenco_class_ord.perim_sanitario_spesa,'') perim_sanitario_spesa_ord,
COALESCE(elenco_class_ord.ricorrente_spesa,'') ricorrente_spesa_ord,
-- ANNA INIZIO 
--CASE WHEN  trim(COALESCE(elenco_pdci_IV.pdc_iv,'')) = ''
--        THEN elenco_pdci_V.pdc_v ::varchar 
--        ELSE elenco_pdci_IV.pdc_iv ::varchar end pdc_iv,
CASE WHEN  trim(COALESCE(elenco_class_movgest.pdc_v,'')) = ''
        THEN elenco_pdci_IV.pdc_iv ::varchar 
        ELSE elenco_class_movgest.pdc_v ::varchar end pdc_iv,
-- ANNA FINE 
COALESCE(cupord.testo_cup_ord,'') testo_cup_ord,
COALESCE(cup_movgest.testo_cup_movgest,'') testo_cup_movgest,
elenco_ord.ord_id,
COALESCE(elenco_ord.ord_importo,0) ord_importo,
elenco_movgest.elem_id,
COALESCE(elenco_movgest.movgest_anno,0) anno_movgest,
elenco_movgest.movgest_id,
COALESCE(elenco_movgest.movgest_importo,0) movgest_importo,
0 fondo_plur_vinc
--COALESCE(fondo_plur.fondo,0) fondo_plur_vinc
from cap
  left join elenco_movgest on cap.elem_id=elenco_movgest.elem_id
  left join elenco_ord on elenco_ord.movgest_id=elenco_movgest.movgest_id
  left join elenco_pdci_IV on elenco_pdci_IV.elem_id=cap.elem_id 
  left join elenco_pdci_V on elenco_pdci_V.elem_id=cap.elem_id 
  left join elenco_class_capitoli on elenco_class_capitoli.elem_id=cap.elem_id
  left join elenco_class_movgest on elenco_class_movgest.movgest_id=elenco_movgest.movgest_id
  left join elenco_class_ord on elenco_class_ord.ord_id=elenco_ord.ord_id 
  left join cup_movgest on (cup_movgest.movgest_id=elenco_movgest.movgest_id
  					and cup_movgest.movgest_ts_id=elenco_movgest.movgest_ts_id)
  left join cupord on cupord.ord_id=elenco_ord.ord_id 
  --left join fondo_plur on cap.elem_id=fondo_plur.elem_id
  
)
select 
    p_anno::varchar bil_anno,
    ''::varchar missione_tipo_code,
    clas.missione_tipo_desc::varchar,
    clas.missione_code::varchar,
    clas.missione_desc::varchar,
    ''::varchar programma_tipo_code,
    clas.programma_tipo_desc::varchar,
    clas.programma_code::varchar,
    clas.programma_desc::varchar,
    ''::varchar	titusc_tipo_code,
    clas.titusc_tipo_desc::varchar,
    clas.titusc_code::varchar,
    clas.titusc_desc::varchar,
    ''::varchar macroag_tipo_code,
    clas.macroag_tipo_desc::varchar,
    clas.macroag_code::varchar,
    clas.macroag_desc::varchar,
    capall.bil_ele_code::varchar,
    capall.bil_ele_desc::varchar,
    capall.bil_ele_code2::varchar,
    capall.bil_ele_desc2::varchar,
    capall.bil_ele_id::integer,
    capall.bil_ele_id_padre::integer,
    capall.bil_ele_code3::varchar,
    CASE WHEN capall.code_cofog_cap = ''
    	THEN CASE WHEN capall.code_cofog_movgest = ''
              THEN capall.code_cofog_ord::varchar
              ELSE capall.code_cofog_movgest::varchar 
              END
        ELSE capall.code_cofog_movgest::varchar end code_cofog,
    CASE WHEN capall.code_transaz_ue_cap = ''
    	THEN CASE WHEN capall.code_transaz_ue_movgest = ''
        		THEN capall.code_transaz_ue_ord::varchar
                ELSE capall.code_transaz_ue_movgest::varchar 
                END
        ELSE capall.code_transaz_ue_cap::varchar  end code_transaz_ue,        
    capall.pdc_iv::varchar,
    CASE WHEN capall.perim_sanitario_spesa_cap = '' or capall.perim_sanitario_spesa_cap='XX' -- 25.08.2017 Sofia
    	 THEN CASE WHEN capall.perim_sanitario_spesa_movgest = '' or capall.perim_sanitario_spesa_movgest='XX'  -- 25.08.2017 Sofia
                   THEN case when capall.perim_sanitario_spesa_ord::varchar='XX' then '' else  capall.perim_sanitario_spesa_ord::varchar end -- 25.08.2017 Sofia
                   ELSE capall.perim_sanitario_spesa_movgest::varchar 
                   END
        ELSE capall.perim_sanitario_spesa_cap::varchar end perim_sanitario_spesa,
    CASE WHEN capall.ricorrente_spesa_cap = ''
    	THEN CASE WHEN capall.ricorrente_spesa_movgest = ''
              THEN capall.ricorrente_spesa_ord::varchar
              ELSE capall.ricorrente_spesa_movgest::varchar 
              END
        ELSE capall.ricorrente_spesa_cap::varchar end ricorrente_spesa,
    CASE WHEN COALESCE(capall.testo_cup_movgest,'') =''
    	THEN COALESCE(capall.testo_cup_ord,'')::varchar
        ELSE COALESCE(capall.testo_cup_movgest,'')::varchar end cup,
    coalesce(capall.ord_id,0)::integer ord_id ,
    coalesce(capall.ord_importo,0)::numeric ord_importo,
    coalesce(capall.movgest_id,0)::integer movgest_id,
    coalesce(capall.anno_movgest,0)::integer anno_movgest , 
    coalesce(capall.movgest_importo,0)::numeric movgest_importo,
    0::numeric fondo_plur_vinc
    --coalesce(capall.fondo_plur_vinc,0)::numeric fondo_plur_vinc    
FROM capall left join clas on 
    clas.programma_id = capall.programma_id and    
    clas.macroag_id=capall.macroag_id
 where 
   capall.bil_ele_id is not null
   and (coalesce(capall.ord_importo,0) > 0 or
   (coalesce(capall.movgest_importo,0)> 0 and coalesce(capall.anno_movgest,0)=p_anno::integer))
   )
  as zz    ;


/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/



    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5199 FINE - Sofia

-- SIAC-5202 INIZIO - Davide

CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_altri_imp boolean,
  ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titent_tipo_code varchar,
  titent_tipo_desc varchar,
  titent_code varchar,
  titent_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
titoloe_tipo_code varchar;
titoloe_TIPO_DESC varchar;
titoloe_CODE varchar;
titoloe_DESC varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;

-- lettura della struttura di bilancio
-- impostazione dell'ente proprietario sulle classificazioni

display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE
END IF;


select fnc_siac_random_user()
into	user_table;
 	
/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/


--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;


insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl, 
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno				= p_anno
and bilancio.periodo_id			=anno_eserc.periodo_id 
and e.bil_id					=bilancio.bil_id 
and e.elem_tipo_id				=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id					=rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
       and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		residui_presunti,
    	tb5.importo		as		previsioni_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpresidui
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;
                
-------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);
end if;

-------------------------------------
        

for classifBilRec in

select 	v1.classif_tipo_desc1    		titent_tipo_desc,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titent_code,
       	v1.titolo_desc             		titent_desc,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)				stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)					residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)				previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)		stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
         
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1              
            on (tb1.elem_id	=	tb.elem_id
            		AND TB.utente=tb1.utente
                    and tb.utente=user_table)
           left	join    siac_rep_cap_ep_imp_riga tb2  
           			on (tb2.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb2.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                      
    where v1.utente = user_table   	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

----titent_tipo_code := classifBilRec.titent_tipo_code;
titent_tipo_desc := classifBilRec.titent_tipo_desc;
titent_code := classifBilRec.titent_code;
titent_desc := classifBilRec.titent_desc;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;


--26/07/2016: sommo gli eventuali valori delle variazioni
stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;


if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    

-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;

end loop;

--delete from siac_rep_tit_tip_cat_riga where utente=user_table;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ep_imp where utente=user_table;
delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;                
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE

END IF;

select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
-------siac_v_mis_pro_tit_macr_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
insert into siac_rep_cap_up
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	-----cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
    cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')														
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
   


insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo           
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= p_anno 													
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- ? stata tolta) e FPVC        		
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')								
        and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	and	tb1.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	and	tb2.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	and	tb3.tipo_capitolo 	in ('STD','FSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpRes	and	tb4.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		in ('STD','FSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
                                    
  
  insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND  -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
                 
                                       
                    


/*
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb6,siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where	
        tb6.elem_id	=	tb7.elem_id
        and 	
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
        tb6.periodo_anno = annoCapImp	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		= 'FPV'
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV'
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        
*/

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno, 
        v1.ente_proprietario_id,
        user_table utente,
        0,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2 
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente) 	
            -----------left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;           

 -------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------

 	for classifBilRec in
select 	t1.missione_tipo_desc	missione_tipo_desc,
		t1.missione_code		missione_code,
		t1.missione_desc		missione_desc,
		t1.programma_tipo_desc	programma_tipo_desc,
		t1.programma_code		programma_code,
		t1.programma_desc		programma_desc,
		t1.titusc_tipo_desc		titusc_tipo_desc,
		t1.titusc_code			titusc_code,
		t1.titusc_desc			titusc_desc,
		t1.macroag_tipo_desc	macroag_tipo_desc,
		t1.macroag_code			macroag_code,
		t1.macroag_desc			macroag_desc,
    	t1.bil_anno   			BIL_ANNO,
        t1.elem_code     		BIL_ELE_CODE,
        t1.elem_code2     		BIL_ELE_CODE2,
        t1.elem_code3			BIL_ELE_CODE3,
		t1.elem_desc     		BIL_ELE_DESC,
        t1.elem_desc2     		BIL_ELE_DESC2,
        t1.elem_id      		BIL_ELE_ID,
       	t1.elem_id_padre    	BIL_ELE_ID_PADRE,
    	COALESCE (t1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
    	COALESCE (t1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (t1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (t1.stanziamento_prev_res_anno,0)		stanziamento_prev_res_anno,
    	COALESCE (t1.stanziamento_anno_prec,0)			stanziamento_anno_prec,
    	COALESCE (t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2 ,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2                    
from siac_rep_mptm_up_cap_importi t1
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)   
        order by missione_code,programma_code,titusc_code,macroag_code
          loop
          missione_tipo_desc:= classifBilRec.missione_tipo_desc;
          missione_code:= classifBilRec.missione_code;
          missione_desc:= classifBilRec.missione_desc;
          programma_tipo_desc:= classifBilRec.programma_tipo_desc;
          programma_code:= classifBilRec.programma_code;
          programma_desc:= classifBilRec.programma_desc;
          titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
          titusc_code:= classifBilRec.titusc_code;
          titusc_desc:= classifBilRec.titusc_desc;
          macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
          macroag_code:= classifBilRec.macroag_code;
          macroag_desc:= classifBilRec.macroag_desc;
          bil_anno:=classifBilRec.bil_anno;
          bil_ele_code:=classifBilRec.bil_ele_code;
          bil_ele_desc:=classifBilRec.bil_ele_desc;
          bil_ele_code2:=classifBilRec.bil_ele_code2;
          bil_ele_desc2:=classifBilRec.bil_ele_desc2;
          bil_ele_id:=classifBilRec.bil_ele_id;
          bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
          bil_anno:=p_anno;
          stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
          stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
          stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
          stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
          stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
          stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
          stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
          stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
          stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
          stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
          impegnato_anno:=0;
          impegnato_anno1:=0;
          impegnato_anno2=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
---            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;
stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;


select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;


/*          
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;            */

-- restituisco il record complessivo
/*raise notice 'record %', classifBilRec.bil_ele_id;
 h_count:=h_count+1;
 raise notice 'n. record %', h_count;*/
return next;
bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;                    
    when others  THEN
      RTN_MESSAGGIO:='struttura bilancio altro errore';
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5202 FINE - Davide

-- SIAC-5208 - INIZIO - Alessandro

-- BILR110
CREATE OR REPLACE FUNCTION siac."BILR110_Allegato_9_bilancio_di_gestione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric,
  previsioni_anno_prec_comp numeric,
  previsioni_anno_prec_cassa numeric,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

select fnc_siac_random_user()
into	user_table;


/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/

--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;

insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());

--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_ep
      select t_class.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
      from siac_t_cap_e_importi_anno_prec prec,
        siac_d_class_tipo classif_tipo,
        siac_t_class t_class
      where classif_tipo.classif_tipo_id	=	t_class.classif_tipo_id
      and t_class.classif_code=prec.categoria_code
      and classif_tipo.classif_tipo_code	=	'CATEGORIA'
      and t_class.ente_proprietario_id =prec.ente_proprietario_id
      and t_class.ente_proprietario_id=p_ente_prop_id
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between t_class.validita_inizio and
        COALESCE(t_class.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_ep ep
      				where ep.elem_code=prec.elem_code
                    	AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = t_class.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);*/

-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_e_importi_anno_prec                 
insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'CATEGORIA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)  
select categ.classif_id classif_id_categ,  p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);                        
  
--------------



insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)   
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    


-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);
end if;

-------------------------------------



for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_code3					BIL_ELE_CODE3,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
        
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           			on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                                                                        
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop



/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;

previsioni_anno_prec_cassa:=0;
previsioni_anno_prec_comp:=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
residui_presunti=residui_presunti+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    
--06/05/2016: cerco i dati relativi alle previsioni anno precedente.
IF classifBilRec.bil_ele_code IS NOT NULL THEN
	--raise notice 'Cerco: titolo_code=%, tipologia_code=%, categoria_code=%,  bil_ele_code=%, bil_ele_code2=%, bil_ele_code3= %, anno=%', classifBilRec.titoloe_CODE, classifBilRec.tipologia_code, classifBilRec.categoria_code,bil_ele_code,bil_ele_code2, classifBilRec.BIL_ELE_CODE3, annoPrec;
  SELECT COALESCE(imp_prev_anno_prec.importo_cassa,0) importo_cassa,
          COALESCE(imp_prev_anno_prec.importo_competenza, 0) importo_competenza
  INTO previsioni_anno_prec_cassa, previsioni_anno_prec_comp 
  FROM siac_t_cap_e_importi_anno_prec  imp_prev_anno_prec
  WHERE imp_prev_anno_prec.categoria_code=classifBilRec.categoria_code
      AND imp_prev_anno_prec.elem_code=classifBilRec.bil_ele_code
      AND imp_prev_anno_prec.elem_code2=classifBilRec.bil_ele_code2
      AND imp_prev_anno_prec.elem_code3=classifBilRec.BIL_ELE_CODE3
      AND imp_prev_anno_prec.anno= annoPrec
      AND imp_prev_anno_prec.ente_proprietario_id=p_ente_prop_id
      AND imp_prev_anno_prec.data_cancellazione IS NULL;
  IF NOT FOUND THEN 
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
  END IF;
ELSE	
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
END IF;
--raise notice 'previsioni_anno_prec_comp= %, previsioni_anno_prec_cassa=%', previsioni_anno_prec_comp,previsioni_anno_prec_cassa;
--06/05/2016: in prima battuta la tabella siac_t_cap_e_importi_anno_prec NON
-- conterra' i dati della competenza ma solo quelli della cassa, pertanto
-- il dato della competenza letto dalla tabella e' sostituito da quello che
-- era contenuto nel campo previsioni_anno_prec.
-- Quando sara' valorizzato la seguente riga dovra' ESSERE ELIMINATA!!!
--previsioni_anno_prec_comp=previsioni_anno_prec;


/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- BILR111
CREATE OR REPLACE FUNCTION siac."BILR111_Allegato_9_bil_gest_spesa_mpt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  previsioni_anno_prec_comp numeric,
  previsioni_anno_prec_cassa numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE

BEGIN

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

/* 06/09/2016: eliminata lettura fase di bilancio perche' NON necessaria.
begin
     RTN_MESSAGGIO:='lettura anno di bilancio''.';  
for classifBilRec in
select 	anno_eserc.anno BIL_ANNO, 
        r_fase.bil_fase_operativa_id, 
        fase.fase_operativa_desc, 
        fase.fase_operativa_code fase_bilancio
from 	siac_t_bil 						bilancio,
		siac_t_periodo 					anno_eserc,
        siac_d_periodo_tipo				tipo_periodo,
        siac_r_bil_fase_operativa 		r_fase,
        siac_d_fase_operativa  			fase
where	anno_eserc.anno						=	p_anno							and	
		bilancio.periodo_id					=	anno_eserc.periodo_id			and
        tipo_periodo.periodo_tipo_code		=	'SY'							and
        anno_eserc.ente_proprietario_id		=	p_ente_prop_id					and
        tipo_periodo.periodo_tipo_id		=	anno_eserc.periodo_tipo_id		and
        r_fase.bil_id						=	bilancio.bil_id					AND
        r_fase.fase_operativa_id			=	fase.fase_operativa_id			and
        bilancio.data_cancellazione			is null								and							
		anno_eserc.data_cancellazione		is null								and	
        tipo_periodo.data_cancellazione		is null								and	
       	r_fase.data_cancellazione			is null								and	
        fase.data_cancellazione				is null								and
        now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())			and		
        now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())		and
        now() between tipo_periodo.validita_inizio and coalesce (tipo_periodo.validita_fine, now())	and        
        now() between r_fase.validita_inizio and coalesce (r_fase.validita_fine, now())				and
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now())

loop
   fase_bilancio:=classifBilRec.fase_bilancio;
--raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

anno_bil_impegni:=p_anno;

  if classifBilRec.fase_bilancio = 'P'  then
      anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_impegni:=p_anno;
  end if;
end loop;

exception
	when no_data_found THEN
		raise notice 'Fase del bilancio non trovata';
	return;
	when others  THEN
        RTN_MESSAGGIO:='errore ricerca fase bilancio';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
       return;
end; */

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';
previsioni_anno_prec_comp=0;
previsioni_anno_prec_cassa=0;
stanziamento_fpv_anno_prec=0;
      
     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice '2: %', clock_timestamp()::varchar;  
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/

-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;

raise notice '3: %', clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up''.';  
insert into siac_rep_cap_up 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 	 		is null;	


--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_up 
select programma.classif_id, macroaggr.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
      from siac_t_cap_u_importi_anno_prec prec,
        siac_d_class_tipo programma_tipo,
        siac_d_class_tipo macroaggr_tipo,
        siac_t_class programma,
        siac_t_class macroaggr
      where programma_tipo.classif_tipo_id	=	programma.classif_tipo_id
      and programma.classif_code=prec.programma_code
      and programma_tipo.classif_tipo_code	=	'PROGRAMMA'
      and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 	
      and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'
      and macroaggr.classif_code=prec.macroagg_code
      and programma.ente_proprietario_id =prec.ente_proprietario_id
      and macroaggr.ente_proprietario_id =prec.ente_proprietario_id
      and prec.ente_proprietario_id=p_ente_prop_id       
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between programma.validita_inizio and
       COALESCE(programma.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
       COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_up up
      				where up.elem_code=prec.elem_code
                    	AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macroaggr.classif_id
                        and up.programma_id = programma.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=p_ente_prop_id);*/

-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_u_importi_anno_prec                        
insert into siac_rep_cap_up                        
with prec as (       
select * From siac_t_cap_u_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, progr as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'PROGRAMMA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
, macro as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'MACROAGGREGATO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
select progr.classif_id classif_id_programma, macro.classif_id classif_id_macroaggregato, p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
 from prec
join progr on prec.programma_code=progr.classif_code
join macro on prec.macroagg_code=macro.classif_code
and not exists (select 1 from siac_rep_cap_up up
                      where up.elem_code=prec.elem_code
                        AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macro.classif_id
                        and up.programma_id = progr.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=prec.ente_proprietario_id);
                    
-----------------   importo capitoli di tipo standard ------------------------

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  
raise notice '4: %', clock_timestamp()::varchar; 
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')						
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
  
-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


raise notice '5: %', clock_timestamp()::varchar; 
insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC')
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		in ('STD','FSC')
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		in ('STD','FSC')		 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		in ('STD','FSC')
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	in ('STD','FSC')
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC')
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;

raise notice '6: %', clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.';  
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

-----------------------------------------------------------------------------------
raise notice '7: %', clock_timestamp()::varchar; 
insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND v1.utente=user_table
                    and	TB.utente=V1.utente)
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id and tbprec.data_cancellazione is null
    where v1.utente = user_table
    		------and TB.utente=V1.utente
            ------and	tb1.utente	=	tb.utente
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

raise notice '7.1: %', clock_timestamp()::varchar; 
/*
 if classifBilRec.fase_bilancio = 'P'  then
 	tipo_capitolo:=elemTipoCode_UG;
 else
 	tipo_capitolo:=elemTipoCode;
 end if;
 */
 
 tipo_capitolo:=elemTipoCode_UG;
 
 
 -------------------------------------
--25/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
--raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
raise notice '7.2: %', clock_timestamp()::varchar; 
   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------
 

       
-- PRIMA VERSIONE INIZIO      
----------------------------------------------------------------------------------------------------
--------  TABELLA TEMPORANEA PER ACQUISIRE L'IMPORTO DEL CUI GIA' IMPEGNATO 
--------  sostituisce momentaneamente le due query successive.
/*raise notice '9: %', clock_timestamp()::varchar;      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
insert into  siac_rep_impegni_riga
select 	tb2.elem_id,
		tb2.dicuiimpegnato_anno1,
        tb2.dicuiimpegnato_anno2,
        tb2.dicuiimpegnato_anno3,
        p_ente_prop_id,
        user_table utente
from 	siac_t_dicuiimpegnato_bilprev 	tb2,
		siac_t_periodo 					anno_eserc,
    	siac_t_bil 						bilancio
where 	tb2.ente_proprietario_id = p_ente_prop_id				AND
		anno_eserc.anno= p_anno									and
        bilancio.periodo_id=anno_eserc.periodo_id				and
		tb2.bil_id = bilancio.bil_id;*/	
-- PRIMA VERSIONE FINE   
raise notice '8: %', clock_timestamp()::varchar; 

/* 13/05/2016: tolto il controllo sulla fase di bilancio 
select case when count(*) is null then 0 else 1 end into esiste_siac_t_dicuiimpegnato_bilprev 
from siac_t_dicuiimpegnato_bilprev where ente_proprietario_id=p_ente_prop_id limit 1;

if classifBilRec.fase_bilancio = 'P' and esiste_siac_t_dicuiimpegnato_bilprev<>1  then
  	for classifBilRec in */

-- NUOVA VERSIONE INIZIO
for ImpegniRec in
  select tb2.elem_id,
  tb.movgest_anno,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  m.movgest_anno::VARCHAR, 
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        -------and et.elem_tipo_code      =  'CAP-UG'
        ----------and m.movgest_anno    <= annoCapImp_int
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        and m.movgest_anno::VARCHAR   			 in (annoCapImp, annoCapImp1, annoCapImp2)
        --and m.movgest_anno >= annobilint
        --------and m.bil_id     = b.bil_id --non serve
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='I' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') ------ P,A,N 
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null      
  group by m.movgest_anno, e.elem_id )
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id
   
  LOOP
    
    v_importo_imp  :=0;
    v_importo_imp1 :=0;
    v_importo_imp2 :=0;
    
    IF ImpegniRec.movgest_anno = annoCapImp THEN
       v_importo_imp := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp1 THEN
       v_importo_imp1 := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN  
       v_importo_imp2 := ImpegniRec.importo;
    END IF; 
        
    v_conta_rec := 0;
    SELECT count(elem_id)
    INTO   v_conta_rec
    FROM   SIAC_REP_IMPEGNI_RIGA
    WHERE  ente_proprietario = p_ente_prop_id
    AND    utente = ImpegniRec.utente
    AND    elem_id = ImpegniRec.elem_id;
    
    IF  v_conta_rec = 0 THEN
       
      INSERT INTO SIAC_REP_IMPEGNI_RIGA
          (elem_id,
           impegnato_anno,
           impegnato_anno1,
           impegnato_anno2,
           ente_proprietario,
           utente)
      VALUES
          (ImpegniRec.elem_id,
           v_importo_imp,
           v_importo_imp1,
           v_importo_imp2,
           p_ente_prop_id,
           ImpegniRec.utente
          );   
    ELSE
        IF ImpegniRec.movgest_anno = annoCapImp THEN
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno = v_importo_imp
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;
        ELSIF  ImpegniRec.movgest_anno = annoCapImp1 THEN  
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno1 = v_importo_imp1
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente; 
        ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN                   
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno2 = v_importo_imp2
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;   
        END IF;             
    END IF;
        
  END LOOP; 
   
-- NUOVA VERSIONE FINE  

 RTN_MESSAGGIO:='preparazione file output''.'; 
 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2,
            COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
            COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
            COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
            COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
            COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
            COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
            COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
            COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
            COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
            COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
            COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
            COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
            COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
            COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
            COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
            COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
            COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
            COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
                      
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id)  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                ----and	t1.utente	=	t2.utente
                ----and	t1.utente	=	user_table)
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)                    
            where t1.utente = user_table
         /*  06/09/2016: eliminate queste condizioni perche'il filtro
         		e' nella query di caricamento struttura
         	 and	(
        		(t1.missione_code < '20' and t1.titusc_code in ('1','2','3'))
        		or (t1.missione_code = '20' and t1.programma_code='2001' and t1.titusc_code = '1')
                or (t1.missione_code = '20' and t1.programma_code in ('2002','2003') and t1.titusc_code in ('1','2'))
                or (t1.missione_code = '50' and t1.programma_code='5001' and t1.titusc_code = '1')
                or (t1.missione_code = '50' and t1.programma_code='5002' and t1.titusc_code = '4')
                or (t1.missione_code = '60' and t1.programma_code = '6001' and t1.titusc_code in ('1','5'))
                or (t1.missione_code = '99' and t1.programma_code in ('9901','9902') and t1.titusc_code = '7')
                )*/
            order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      --stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno_prec_app:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
      
      --stanziamento_fpv_anno_prec

--25/07/2016: sommo gli eventuali valori delle variazioni

--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
--            					    classifBilRec.variazione_diminuzione_stanziato;
                                    
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;

stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;

select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;

/* if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;  */

--06/05/2016: cerco i dati relativi alle previsioni anno precedente.
IF bil_ele_code IS NOT NULL THEN
--raise notice 'Cerco: missione_code=%, programma_code=%, titolo_code=%, macroagg_code=%,  bil_ele_code=%, bil_ele_code2=%, bil_ele_code3= %, anno=%', missione_code, classifBilRec.programma_code, classifBilRec.titusc_code,classifBilRec.macroag_code,bil_ele_code,bil_ele_code2, classifBilRec.BIL_ELE_CODE3, annoPrec;

  SELECT COALESCE(imp_prev_anno_prec.importo_cassa,0) importo_cassa,
          COALESCE(imp_prev_anno_prec.importo_competenza, 0) importo_competenza,
          elem_cat_code
  INTO previsioni_anno_prec_cassa_app, previsioni_anno_prec_comp_app, tipo_categ_capitolo
  FROM siac_t_cap_u_importi_anno_prec  imp_prev_anno_prec 
  WHERE  --imp_prev_anno_prec.missione_code= classifBilRec.missione_code
       imp_prev_anno_prec.programma_code=classifBilRec.programma_code
      --AND imp_prev_anno_prec.titolo_code=classifBilRec.titusc_code      
      AND imp_prev_anno_prec.macroagg_code=classifBilRec.macroag_code
      AND imp_prev_anno_prec.elem_code=bil_ele_code
      AND imp_prev_anno_prec.elem_code2=bil_ele_code2
      AND imp_prev_anno_prec.elem_code3=classifBilRec.BIL_ELE_CODE3
      AND imp_prev_anno_prec.anno= annoPrec
      AND imp_prev_anno_prec.ente_proprietario_id=p_ente_prop_id
      AND imp_prev_anno_prec.data_cancellazione IS NULL;
  IF NOT FOUND THEN 
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
  ELSE
 -- raise notice 'XXXX tipo_categ_capitolo = %', tipo_categ_capitolo;
      previsioni_anno_prec_comp=previsioni_anno_prec_comp_app;
      previsioni_anno_prec_cassa=previsioni_anno_prec_cassa_app;
      	-- se il capitolo e' di tipo FPV carico anche il campo stanziamento_fpv_anno_prec
     -- 06/09/2016: aggiunto FPVC
 	 IF tipo_categ_capitolo = 'FPV' OR tipo_categ_capitolo = 'FPVC' THEN
      	previsioni_anno_prec_comp=0;
      	stanziamento_fpv_anno_prec=previsioni_anno_prec_comp_app;  
      END IF;
  END IF;
ELSE
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
END IF;
--06/05/2016: in prima battuta la tabella siac_t_cap_e_importi_anno_prec NON
-- conterra' i dati della competenza ma solo quelli della cassa, pertanto
-- il dato della competenza letto dalla tabella e' sostituito da quello che
-- era contenuto nel campo previsioni_anno_prec.
-- Quando sara' valorizzato le seguenti righe dovranno ESSERE ELIMINATE!!!
--previsioni_anno_prec_comp=stanziamento_anno_prec;
--stanziamento_fpv_anno_prec=stanziamento_fpv_anno_prec_app;

	return next;
    bil_anno='';
    missione_tipo_code='';
    missione_tipo_desc='';
    missione_code='';
    missione_desc='';
    programma_tipo_code='';
    programma_tipo_desc='';
    programma_code='';
    programma_desc='';
    titusc_tipo_code='';
    titusc_tipo_desc='';
    titusc_code='';
    titusc_desc='';
    macroag_tipo_code='';
    macroag_tipo_desc='';
    macroag_code='';
    macroag_desc='';
    bil_ele_code='';
    bil_ele_desc='';
    bil_ele_code2='';
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;
    impegnato_anno=0;
    impegnato_anno1=0;
    impegnato_anno2=0;
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    previsioni_anno_prec_comp=0;
	previsioni_anno_prec_cassa=0;
	stanziamento_fpv_anno_prec=0;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_up 						where utente=user_table;
delete from siac_rep_cap_up_imp 					where utente=user_table;
delete from siac_rep_cap_up_imp_riga				where utente=user_table;
delete from siac_rep_mptm_up_cap_importi 			where utente=user_table;
delete from siac_rep_impegni 						where utente=user_table;
delete from siac_rep_impegni_riga  					where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;              
    when others  THEN
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5208 - FINE - Alessandro

-- siac-5203 - INIZIO - Sofia
CREATE OR REPLACE FUNCTION siac."BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;



BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';


-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where --ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and
 e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
/*and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
           	--------capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    -----group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente

     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  


insert into siac_rep_var_entrate
(
  elem_id,
  importo,
  utente,
  ente_proprietario,
  periodo_anno
)
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
        --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
        --------tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_d_bil_elem_categoria 	cat_del_capitolo, 
        siac_r_bil_elem_categoria 	r_cat_capitolo,
        siac_t_periodo 				anno_eserc,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
-- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
--and     anno_importo.anno                                   =   p_anno 					
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					= 'STA'
and		capitolo.elem_id									=	r_cat_capitolo.elem_id
and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
and		cat_del_capitolo.elem_cat_code						in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		cat_del_capitolo.data_cancellazione			is null 
and     r_cat_capitolo.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
        	utente,
            atto.ente_proprietario_id,
            anno_importo.anno;

/*group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code,
            cat_del_capitolo.elem_cat_code,
-----------------------            tipo_elemento.elem_det_tipo_code,  
        	utente,
        	atto.ente_proprietario_id;*/


    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  




insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
--tipologia_capitolo := 'DAM';
stanziato := classifBilRec.stanziato;
--stanziato := 250;
variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;
return next;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- siac-5203 - FINE - Sofia