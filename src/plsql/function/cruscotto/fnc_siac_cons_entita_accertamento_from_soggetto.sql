/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


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
  capitolo_anno integer,
  capitolo_numero integer,
  capitolo_articolo integer,
  ueb_numero varchar,
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
		and r.data_cancellazione is null
		and s.data_cancellazione is null
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
            
			capitolo_anno:=rec.anno::integer;
			capitolo_numero:=rec.elem_code::integer;
			capitolo_articolo:=rec.elem_code2::integer;
            
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
				r.attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                q.attoamm_oggetto

			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                attoamm_oggetto
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