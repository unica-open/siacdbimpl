/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 18.12.2017 Sofia - SIAC-5670 - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_impegno_total (
  _uid_impegno integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) 
	into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='P'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				liquidazione as(
					select
						i.sord_id,
						i.liq_id,
						l.liq_anno,
						l.liq_numero,
						m.ord_id
					from
						siac_r_liquidazione_ord i,
						siac_t_liquidazione l,
						siac_t_ordinativo_ts m
					where i.liq_id=l.liq_id
					and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
					and i.sord_id=m.ord_ts_id
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				),
				impegno as (
					select
						r.liq_id
					from
						siac_r_liquidazione_movgest r,
						siac_t_movgest_ts s
					where s.movgest_ts_id =r.movgest_ts_id
					and s.movgest_id=_uid_impegno
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				)
				select *
				from
					ordinativo
					cross join soggetto
					cross join attoamm
					cross join capitolo
					cross join impegno
					cross join liquidazione
					left OUTER join modpag on (ordinativo.uid=modpag.ord_id)
				where ordinativo.uid=soggetto.ord_id
				and ordinativo.uid=liquidazione.ord_id
				and ordinativo.uid=attoamm.ord_id
				and ordinativo.uid=capitolo.ord_id
				--and ordinativo.uid=modpag.ord_id
				and impegno.liq_id=liquidazione.liq_id
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
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select *
			from ord_join
			left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		),
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)
		select
			ord_join_outer.uid
		from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	) as ord_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_impegno (
  _uid_impegno integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					siac_t_ordinativo a,
					siac_r_ordinativo_stato d,
					siac_d_ordinativo_stato e,
					siac_t_ordinativo_ts f,
					siac_t_ordinativo_ts_det g,
					siac_d_ordinativo_ts_det_tipo h,
					siac_d_ordinativo_tipo i
				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			liquidazione as(
				select
					i.sord_id,
					i.liq_id,
					l.liq_anno,
					l.liq_numero,
					m.ord_id
				from
					siac_r_liquidazione_ord i,
					siac_t_liquidazione l,
					siac_t_ordinativo_ts m
				where i.liq_id=l.liq_id
				and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
				and i.sord_id=m.ord_ts_id
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				select
					c2.ord_id,
					e2.accredito_tipo_code,
					e2.accredito_tipo_desc
				FROM
					siac_r_ordinativo_modpag c2,
					siac_t_modpag d2,
					siac_d_accredito_tipo e2
				where c2.modpag_id=d2.modpag_id
				and e2.accredito_tipo_id=d2.accredito_tipo_id
				and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
				and c2.data_cancellazione is null
				and d2.data_cancellazione is null
				and e2.data_cancellazione is null
			),
			impegno as (
				select
					r.liq_id
				from
					siac_r_liquidazione_movgest r,
					siac_t_movgest_ts s
				where s.movgest_ts_id =r.movgest_ts_id
				and s.movgest_id=_uid_impegno
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			)
			select *
			from
				ordinativo
				cross join soggetto
				cross join attoamm
				cross join capitolo
				cross join impegno
				cross join liquidazione
				left OUTER join modpag on (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=liquidazione.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
			and impegno.liq_id=liquidazione.liq_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	)
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida
	from ord_join_outer
	left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_liquidazione_total (
  _liq_id integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) 
	into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='P'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				),
				liquidazione as (
					select
						z.ord_id
					from
						siac_r_liquidazione_ord r,
						siac_t_liquidazione s,siac_t_ordinativo_ts z
					where s.liq_id =r.liq_id
					and s.liq_id=_liq_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and z.ord_ts_id=r.sord_id
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				)
				select *
				from
					ordinativo
					cross join soggetto
					cross join attoamm
					cross join capitolo
					cross join liquidazione
					left OUTER join modpag on (ordinativo.uid=modpag.ord_id)
				where ordinativo.uid=soggetto.ord_id
				and ordinativo.uid=attoamm.ord_id
				and ordinativo.uid=capitolo.ord_id
				--and ordinativo.uid=modpag.ord_id
				and ordinativo.uid=liquidazione.ord_id
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
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select *
			from ord_join
			left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		),
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.accredito_tipo_code,
			ord_join_outer.accredito_tipo_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_code as num_capitolo,
			ord_join_outer.elem_code2 as num_articolo,
			ord_join_outer.elem_code3 as num_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
			provv_cassa.provc_anno,
			provv_cassa.provc_numero,
			provv_cassa.provc_data_convalida
		from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	
	) as ord_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_liquidazione (
  _liq_id integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					siac_t_ordinativo a,
					siac_r_ordinativo_stato d,
					siac_d_ordinativo_stato e,
					siac_t_ordinativo_ts f,
					siac_t_ordinativo_ts_det g,
					siac_d_ordinativo_ts_det_tipo h,
					siac_d_ordinativo_tipo i
				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				select
					c2.ord_id,
					e2.accredito_tipo_code,
					e2.accredito_tipo_desc
				FROM
					siac_r_ordinativo_modpag c2,
					siac_t_modpag d2,
					siac_d_accredito_tipo e2
				where c2.modpag_id=d2.modpag_id
				and e2.accredito_tipo_id=d2.accredito_tipo_id
				and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
				and c2.data_cancellazione is null
				and d2.data_cancellazione is null
				and e2.data_cancellazione is null
			),
			liquidazione as (
				select
					z.ord_id
				from
					siac_r_liquidazione_ord r,
					siac_t_liquidazione s,siac_t_ordinativo_ts z
				where s.liq_id =r.liq_id
				and s.liq_id=_liq_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and z.ord_ts_id=r.sord_id
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			)
			select *
			from
				           ordinativo
				cross join soggetto
				cross join attoamm
				cross join capitolo
				cross join liquidazione
				left OUTER join modpag on (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
			and ordinativo.uid=liquidazione.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	)
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida
	from ord_join_outer
	left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_provvedimento_total (
  _uid_provvedimento integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT 
	coalesce(count(*),0) into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='P'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and n.attoamm_id=_uid_provvedimento
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					with modpag_noncessione as (
						select
							c2.ord_id,
							e2.accredito_tipo_code,
							e2.accredito_tipo_desc
						FROM
							siac_r_ordinativo_modpag c2,
							siac_t_modpag d2,
							siac_d_accredito_tipo e2
						where c2.modpag_id=d2.modpag_id
						and e2.accredito_tipo_id=d2.accredito_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					),
					modpag_cessione as (
						select
							c2.ord_id,
							e2.relaz_tipo_code accredito_tipo_code,
							e2.relaz_tipo_desc accredito_tipo_desc
						from
							siac_r_ordinativo_modpag c2,
							siac_r_soggetto_relaz d2,
							siac_d_relaz_tipo e2
						where d2.soggetto_relaz_id = c2.soggetto_relaz_id
						and e2.relaz_tipo_id = d2.relaz_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					)
					select *
					from modpag_noncessione
					UNION ALL
					select *
					from modpag_cessione
				)
				select *
				from
					ordinativo
					cross join soggetto
					cross join attoamm
					cross join capitolo
					left OUTER JOIN modpag on (ordinativo.uid=modpag.ord_id)
				where ordinativo.uid=soggetto.ord_id
				and ordinativo.uid=attoamm.ord_id
				and ordinativo.uid=capitolo.ord_id
				--and ordinativo.uid=modpag.ord_id
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
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select *
			from ord_join
			left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		),
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.accredito_tipo_code,
			ord_join_outer.accredito_tipo_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_id as uid_capitolo,
			ord_join_outer.elem_code as num_capitolo,
			ord_join_outer.elem_code2 as num_articolo,
			ord_join_outer.elem_code3 as num_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
			provv_cassa.provc_anno,
			provv_cassa.provc_numero,
			provv_cassa.provc_data_convalida
		from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	) as ord_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_provvedimento (
  _uid_provvedimento integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					siac_t_ordinativo a,
					siac_r_ordinativo_stato d,
					siac_d_ordinativo_stato e,
					siac_t_ordinativo_ts f,
					siac_t_ordinativo_ts_det g,
					siac_d_ordinativo_ts_det_tipo h,
					siac_d_ordinativo_tipo i
				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and n.attoamm_id=_uid_provvedimento
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				with modpag_noncessione as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				),
				modpag_cessione as (
					select
						c2.ord_id,
						e2.relaz_tipo_code accredito_tipo_code,
						e2.relaz_tipo_desc accredito_tipo_desc
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
						siac_d_relaz_tipo e2
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and e2.relaz_tipo_id = d2.relaz_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			)
			select *
			from
				      ordinativo
				cross join soggetto
				cross join attoamm
				cross join capitolo
                LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	)
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida
	from ord_join_outer
	left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto_total (
  _uid_soggetto integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0)
	into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='P'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and c.soggetto_id=_uid_soggetto
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
                
				modpag as (
				with modpag_noncessione as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				),
                
				modpag_cessione as (
					select
						c2.ord_id,
						e2.relaz_tipo_code accredito_tipo_code,
						e2.relaz_tipo_desc accredito_tipo_desc
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
						siac_d_relaz_tipo e2
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and e2.relaz_tipo_id = d2.relaz_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
				)
				select *
				from
					ordinativo,
					soggetto,
					attoamm,
					capitolo--,
					--modpag
				where ordinativo.uid=soggetto.ord_id
				and ordinativo.uid=attoamm.ord_id
				and ordinativo.uid=capitolo.ord_id
				--and ordinativo.uid=modpag.ord_id
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
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select *
			from ord_join
			left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		),
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.accredito_tipo_code,
			ord_join_outer.accredito_tipo_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_id as uid_capitolo,
			ord_join_outer.elem_code as num_capitolo,
			ord_join_outer.elem_code2 as num_articolo,
			ord_join_outer.elem_code3 as num_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
			provv_cassa.provc_anno,
			provv_cassa.provc_numero,
			provv_cassa.provc_data_convalida
		from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	) as ord_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto (
  _uid_soggetto integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					siac_t_ordinativo a,
					siac_r_ordinativo_stato d,
					siac_d_ordinativo_stato e,
					siac_t_ordinativo_ts f,
					siac_t_ordinativo_ts_det g,
					siac_d_ordinativo_ts_det_tipo h,
					siac_d_ordinativo_tipo i
				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				with modpag_noncessione as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null--??forse da commentare siac-5670
					and e2.data_cancellazione is null
				),
				modpag_cessione as (
					select
						c2.ord_id,
						e2.relaz_tipo_code accredito_tipo_code,
						e2.relaz_tipo_desc accredito_tipo_desc
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
						siac_d_relaz_tipo e2
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and e2.relaz_tipo_id = d2.relaz_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			)
			select *
			from
				           ordinativo
				CROSS JOIN soggetto
				CROSS JOIN attoamm
				CROSS JOIN capitolo
				LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	)
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida
	from ord_join_outer
	left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- 18.12.2017 Sofia - SIAC-5670 - FINE

-- SIAC-5656 INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR152_elenco_liquidazioni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  num_liquidazione varchar,
  anno_liquidazione integer,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  cup varchar,
  cig varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  tipo varchar,
  tipo_finanz varchar,
  conto_dare varchar,
  conto_avere varchar,
  importo_liquidazione numeric,
  code_cofog varchar,
  code_programma varchar,
  anno_mandato integer,
  numero_mandato numeric,
  code_stato_mandato varchar,
  desc_stato_mandato varchar,
  code_soggetto_mandato varchar,
  desc_soggetto_mandato varchar,
  code_modpag_mandato varchar,
  desc_modpag_mandato varchar,
  importo_mandato numeric,
  pdce_v varchar,
  trans_eu varchar,
  ricorrente varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
sqlQuery varchar;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
num_liquidazione:='';
anno_liquidazione:=0;
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
code_soggetto:='';
desc_soggetto:=0;
tipo:='';
tipo_finanz:='';
conto_dare:='';
conto_avere:='';
importo_liquidazione:=0;
code_programma:='';
code_cofog:='';
cup:='';
cig:='';
anno_mandato:=0;
numero_mandato:=0;
code_stato_mandato:='';
desc_stato_mandato:='';
code_soggetto_mandato:='';
desc_soggetto_mandato:='';
code_modpag_mandato:='';
desc_modpag_mandato:='';
importo_mandato:=0;
pdce_v:='';
trans_eu:='';
ricorrente :='';

anno_eser_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
	-- 14/12/2017: SIAC-5656.
    --	Aggiunte tabelle per testare lo stato della liquidazione in modo
    --	da escludere quelle annullate.
 with liquidazioni as (
 			  select t_liquidazione.liq_anno,
              t_liquidazione.liq_numero,
              t_liquidazione.liq_id,       
              t_liquidazione.liq_importo
           from  siac_t_liquidazione t_liquidazione,     
           		siac_r_liquidazione_atto_amm r_liq_atto_amm ,    
                siac_t_atto_amm t_atto_amm  ,
                siac_d_atto_amm_tipo	tipo_atto,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_r_liquidazione_stato r_liq_stato,
                siac_d_liquidazione_stato d_liq_stato
          where t_liquidazione.liq_id=   r_liq_atto_amm.liq_id
          		AND t_atto_amm.attoamm_id=r_liq_atto_amm.attoamm_id
                AND t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
                AND t_bil.bil_id=t_liquidazione.bil_id
                AND t_periodo.periodo_id=t_bil.periodo_id
                AND r_liq_stato.liq_id = t_liquidazione.liq_id
                AND r_liq_stato.liq_stato_id=d_liq_stato.liq_stato_id
               	AND t_liquidazione.ente_proprietario_id =p_ente_prop_id
               	AND t_atto_amm.attoamm_numero=p_numero_provv
                AND t_atto_amm.attoamm_anno=p_anno_provv
                AND tipo_atto.attoamm_tipo_code=p_tipo_provv
                AND t_periodo.anno=p_anno
                AND d_liq_stato.liq_stato_code <> 'A'
                AND r_liq_stato.validita_fine IS NULL
                AND t_liquidazione.data_cancellazione IS NULL
                AND r_liq_atto_amm.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL
                AND tipo_atto.data_cancellazione IS NULL
                AND t_bil.data_cancellazione IS NULL
                AND t_periodo.data_cancellazione IS NULL
                AND r_liq_stato.data_cancellazione IS NULL
                AND d_liq_stato.data_cancellazione IS NULL),
 impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		r_liq_movgest_ts.liq_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
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
                siac_d_movgest_stato d_movgest_stato ,
                siac_r_liquidazione_movgest r_liq_movgest_ts
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	               
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_liq_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_liq_movgest_ts.data_cancellazione IS NULL),
	soggetto_liq as (
    		SELECT r_liq_sog.liq_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_liquidazione_soggetto r_liq_sog,
                siac_t_soggetto t_soggetto
            WHERE r_liq_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_liq_sog.data_cancellazione IS NULL) ,         	 
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL),
elenco_pdce_finanz as (        
SELECT  r_bil_elem_class.elem_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                 and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,
        elenco_attrib as(
        	select * from "fnc_bilr152_tab_attrib"(p_ente_prop_id))  ,
        programma as (
        	select t_programma.programma_code,
            	r_movgest_ts_prog.movgest_ts_id
            from siac_r_movgest_ts_programma     r_movgest_ts_prog,
            	siac_t_programma t_programma
            where r_movgest_ts_prog.programma_id= t_programma.programma_id
            	and r_movgest_ts_prog.ente_proprietario_id=p_ente_prop_id
            	and t_programma.data_cancellazione is null
                and r_movgest_ts_prog.data_cancellazione is null) ,
        tipo_finanz_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='TIPO_FINANZIAMENTO' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),
        cofog_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='GRUPPO_COFOG' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ), 
        programma_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='PROGRAMMA' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),                                        
  elencocig as (
  				select  t_attr.attr_code attr_code_cig, 
                  r_liq_attr.testo testo_cig,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                    siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                    and t_attr.ente_proprietario_id=p_ente_prop_id        
                	AND upper(t_attr.attr_code) = 'CIG'          
                    and r_liq_attr.data_cancellazione IS NULL
                    and t_attr.data_cancellazione IS NULL),
    elencocup as (
    			select  t_attr.attr_code attr_code_cup, 
                  r_liq_attr.testo testo_cup,
                  r_liq_attr.liq_id
                from siac_t_attr t_attr,
                       siac_r_liquidazione_attr  r_liq_attr
                where  r_liq_attr.attr_id=t_attr.attr_id          
                        and t_attr.ente_proprietario_id=p_ente_prop_id  
                        AND upper(t_attr.attr_code) = 'CUP'          
                        and r_liq_attr.data_cancellazione IS NULL
                        and t_attr.data_cancellazione IS NULL),
  	elenco_mandati as (    			
        SELECT r_liq_ord.liq_id,
        	t_ord.ord_anno, t_ord.ord_numero,
            d_ord_stato.ord_stato_code, d_ord_stato.ord_stato_desc,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_code,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_code,'') end code_pagamento,
            case when t_modpag.modpag_id is not null 
                then COALESCE(d_accredito_tipo.accredito_tipo_desc,'')
                else  COALESCE(d_accredito_tipo1.accredito_tipo_desc,'') end desc_pagamento,
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,
            t_ord_ts_det.ord_ts_det_importo
        FROM siac_r_liquidazione_ord r_liq_ord,
            siac_t_ordinativo_ts t_ord_ts,
            siac_t_ordinativo_ts_det t_ord_ts_det,
            siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
            siac_t_ordinativo t_ord,
            siac_r_ordinativo_stato r_ord_stato,
            siac_d_ordinativo_stato d_ord_stato,
            siac_r_ordinativo_modpag r_ord_modpag
            LEFT JOIN siac_t_modpag t_modpag 
                    ON (t_modpag.modpag_id=r_ord_modpag.modpag_id
                        AND t_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo 
              ON (d_accredito_tipo.accredito_tipo_id=t_modpag.accredito_tipo_id
                  AND d_accredito_tipo.data_cancellazione IS NULL) 
            /* in caso di cessione di incasso su siac_r_ordinativo_modpag
            non e' valorizzata la modalita' di pagamento.
            Devo cercare quella del soggetto a cui e' stato ceduto l'incasso. */
            LEFT JOIN  siac_r_soggrel_modpag r_sogg_modpag
                ON (r_ord_modpag.soggetto_relaz_id=r_sogg_modpag.soggetto_relaz_id
                    AND r_sogg_modpag.data_cancellazione IS NULL)
            LEFT JOIN siac_t_modpag t_modpag1 
                ON (t_modpag1.modpag_id=r_sogg_modpag.modpag_id
                    AND t_modpag1.data_cancellazione IS NULL)
            LEFT JOIN siac_d_accredito_tipo d_accredito_tipo1 
                ON (d_accredito_tipo1.accredito_tipo_id=t_modpag1.accredito_tipo_id
                    AND d_accredito_tipo1.data_cancellazione IS NULL),
            siac_d_ordinativo_tipo d_ord_tipo ,
            siac_r_ordinativo_soggetto r_ord_soggetto,
            siac_t_soggetto t_soggetto
        WHERE r_liq_ord.sord_id=t_ord_ts.ord_ts_id
            AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
            AND t_ord.ord_id=t_ord_ts.ord_id
            AND r_ord_stato.ord_id=t_ord.ord_id
            AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND r_ord_modpag.ord_id=t_ord.ord_id
            AND d_ord_tipo.ord_tipo_id=t_ord.ord_tipo_id
            AND r_ord_soggetto.ord_id=t_ord.ord_id
            AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
            AND r_liq_ord.ente_proprietario_id=p_ente_prop_id
            AND d_ord_tipo.ord_tipo_code='P' --Pagamento
            AND d_ord_ts_det_tipo.ord_ts_det_tipo_code='A' -- importo Attuale
            AND d_ord_stato.ord_stato_code <> 'A' --Annullato
            AND r_liq_ord.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND d_ord_ts_det_tipo.data_cancellazione IS NULL
            AND t_ord.data_cancellazione IS NULL
            AND r_ord_modpag.data_cancellazione IS NULL 
            AND d_ord_tipo.data_cancellazione IS NULL
            AND r_ord_soggetto.data_cancellazione IS NULL
            AND t_soggetto.data_cancellazione IS NULL
            AND r_ord_stato.data_cancellazione IS NULL
            AND d_ord_stato.data_cancellazione IS NULL
            AND r_ord_stato.validita_fine IS NULL)   ,
conto_integrato as (    	
      select distinct t_liq.liq_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_liquidazione t_liq,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_liq.liq_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_liq.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='L' --Liquidazione 
          and r_ev_reg_movfin.data_cancellazione is null
          and t_liq.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null ) ,
      /* 12/06/2017: aggiunta la gestione delle classificazioni dell
      	liquidazioni */
	elenco_class_liq as (select *
    			from "fnc_bilr152_tab_class_liquid"(p_ente_prop_id))                                                   
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    liquidazioni.liq_numero::varchar num_liquidazione,
    liquidazioni.liq_anno::integer anno_liquidazione,
    COALESCE(impegni.movgest_numero,0)::numeric num_impegno,
    COALESCE(impegni.movgest_anno,0)::integer anno_impegno,
    COALESCE(impegni.movgest_ts_code,'')::varchar num_subimpegno,
    COALESCE(elencocup.testo_cup,'')::varchar cup,
    COALESCE(elencocig.testo_cig,'')::varchar cig,
    COALESCE(soggetto_liq.soggetto_code,'')::varchar code_soggetto,
	COALESCE(soggetto_liq.soggetto_desc,'')::varchar desc_soggetto,
   -- CASE WHEN upper(COALESCE(elenco_attrib.flag_prenotazione,'')) = 'S'
    --	THEN 'PR'::varchar 
     --   ELSE impegni.tipo_impegno::varchar  end tipo,
    'LIQ'::varchar tipo,
    COALESCE(tipo_finanz_cap.classif_code,'')::varchar tipo_finanz,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
	liquidazioni.liq_importo::numeric importo_liquidazione,
    COALESCE(cofog_cap.classif_code,'')::varchar code_cofog,
    COALESCE(programma_cap.classif_code,'')::varchar code_programma,
    COALESCE(elenco_mandati.ord_anno,0)::integer anno_mandato,
    COALESCE(elenco_mandati.ord_numero,0)::numeric numero_mandato,
	COALESCE(elenco_mandati.ord_stato_code,'')::varchar code_stato_mandato,
	COALESCE(elenco_mandati.ord_stato_desc,'')::varchar desc_stato_mandato,
	COALESCE(elenco_mandati.soggetto_code,'')::varchar code_soggetto_mandato,
    COALESCE(elenco_mandati.soggetto_desc,'')::varchar desc_soggetto_mandato,
	COALESCE(elenco_mandati.code_pagamento,'')::varchar code_modpag_mandato,
    COALESCE(elenco_mandati.desc_pagamento,'')::varchar desc_modpag_mandato,
	COALESCE(elenco_mandati.ord_ts_det_importo,0)::numeric importo_mandato,
    COALESCE(elenco_class_liq.pdc_v,'')::varchar pdce_v,
    COALESCE(elenco_class_liq.code_transaz_ue,'')::varchar trans_eu,
    COALESCE(elenco_class_liq.ricorrente_spesa,'')::varchar ricorrente
FROM liquidazioni
	LEFT JOIN impegni on impegni.liq_id=liquidazioni.liq_id
	LEFT JOIN soggetto_liq on soggetto_liq.liq_id=liquidazioni.liq_id
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.elem_id = capitoli.elem_id 
    LEFT join elenco_attrib on elenco_attrib.movgest_ts_id = impegni.movgest_ts_id
    LEFT join programma on programma.movgest_ts_id = impegni.movgest_ts_id
    LEFT join tipo_finanz_cap on tipo_finanz_cap.elem_id = capitoli.elem_id 
    LEFT join elencocig on elencocig.liq_id=liquidazioni.liq_id  
    LEFT join elencocup on elencocup.liq_id=liquidazioni.liq_id  
    LEFT join cofog_cap on cofog_cap.elem_id = capitoli.elem_id
    LEFT join programma_cap on programma_cap.elem_id = capitoli.elem_id 
    LEFT JOIN elenco_mandati on elenco_mandati.liq_id=liquidazioni.liq_id 
    LEFT JOIN conto_integrato on conto_integrato.liq_id=liquidazioni.liq_id   
    LEFT JOIN elenco_class_liq on elenco_class_liq.liquid_id=liquidazioni.liq_id                 
ORDER BY anno_impegno, num_impegno, tipo, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
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

-- SIAC-5656 FINE - Maurizio

-- SIAC-5334 INIZIO

-- Inserimento azioni
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GEN-gestisciPRNotaIntManGSA', 'Inserisci prima nota integrata manuale', ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
WHERE ta.ente_proprietario_id = e.ente_proprietario_id
AND ga.ente_proprietario_id = e.ente_proprietario_id
AND ta.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND ga.gruppo_azioni_code = 'GEN_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id=ta.azione_tipo_id
	AND z.azione_code='OP-GEN-gestisciPRNotaIntManGSA'
);

INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GEN-ricPRNotaIntManGSA', 'Ricerca prima nota integrata manuale', ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
WHERE ta.ente_proprietario_id = e.ente_proprietario_id
AND ga.ente_proprietario_id = e.ente_proprietario_id
AND ta.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND ga.gruppo_azioni_code = 'GEN_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id=ta.azione_tipo_id
	AND z.azione_code='OP-GEN-ricPRNotaIntManGSA'
);

-- Inserimento evento e tipo
INSERT INTO siac_d_evento_tipo (evento_tipo_code, evento_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'EXTR', 'EXTR', to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_evento_tipo det
	WHERE det.ente_proprietario_id = tep.ente_proprietario_id
	AND det.evento_tipo_code = 'EXTR'
);

INSERT INTO siac_r_causale_ep_tipo_evento_tipo (causale_ep_tipo_id, evento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dcet.causale_ep_tipo_id, det.evento_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), dcet.ente_proprietario_id, 'admin'
FROM siac_d_causale_ep_tipo dcet
JOIN siac_d_evento_tipo det ON det.ente_proprietario_id = dcet.ente_proprietario_id
WHERE dcet.causale_ep_tipo_code = 'INT'
AND det.evento_tipo_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_causale_ep_tipo_evento_tipo rcetet
	WHERE rcetet.causale_ep_tipo_id = dcet.causale_ep_tipo_id
	AND rcetet.evento_tipo_id = det.evento_tipo_id
	AND rcetet.ente_proprietario_id = dcet.ente_proprietario_id
);

-- Gli eventi inseriti sono EXTR (fittizio, per l'interfaccia utente), EXTR-I per l'impegno, EXTR-A per l'accertamento, EXTR-IS per il subimpegno, EXTR-AS per il subaccertamento
INSERT INTO siac_d_evento (evento_code, evento_desc, evento_tipo_id, collegamento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, det.evento_tipo_id, dct.collegamento_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo det ON det.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES
	('EXTR', 'EXTR', 'EXTR', NULL),
	('EXTR-I', 'EXTR-Impegno', 'EXTR', 'I'),
	('EXTR-A', 'EXTR-Accertamento', 'EXTR', 'A'),
	('EXTR-SI', 'EXTR-SubImpegno', 'EXTR', 'SI'),
	('EXTR-SA', 'EXTR-SubAccertamento', 'EXTR', 'SA'))
	AS tmp(code, descr, tipo, coll)
LEFT OUTER JOIN siac_d_collegamento_tipo dct ON (dct.ente_proprietario_id = tep.ente_proprietario_id AND dct.collegamento_tipo_code = tmp.coll)
WHERE det.evento_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_evento de
	WHERE de.ente_proprietario_id = tep.ente_proprietario_id
	AND de.evento_tipo_id = det.evento_tipo_id
	AND de.evento_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

-- Creazione della causale di default
INSERT INTO siac_t_causale_ep (causale_ep_code, causale_ep_desc, causale_ep_tipo_id, ambito_id, validita_inizio, ente_proprietario_id, login_creazione, login_operazione)
SELECT 'EXTR', 'EXTR', dcet.causale_ep_tipo_id , da.ambito_id, to_timestamp('2017-01-01', 'YYYY-MM-DD')), tep.ente_proprietario_id, 'admin', 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_causale_ep_tipo dcet ON (tep.ente_proprietario_id = dcet.ente_proprietario_id)
JOIN siac_d_ambito da ON (tep.ente_proprietario_id = da.ente_proprietario_id)
WHERE dcet.causale_ep_tipo_code = 'INT'
AND da.ambito_code = 'AMBITO_GSA'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_causale_ep tce
	WHERE tce.ente_proprietario_id = tep.ente_proprietario_id
	AND tce.causale_ep_tipo_id = dcet.causale_ep_tipo_id
	AND tce.ambito_id = da.ambito_id
	AND tce.causale_ep_code = 'EXTR'
	AND tce.data_cancellazione IS NULL
);

INSERT INTO siac_r_evento_causale (evento_id, causale_ep_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT de.evento_id, tce.causale_ep_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), de.ente_proprietario_id, 'admin'
FROM siac_d_evento de
JOIN siac_t_causale_ep tce ON (de.ente_proprietario_id = tce.ente_proprietario_id)
WHERE de.evento_code = 'EXTR'
AND tce.causale_ep_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_evento_causale rec
	WHERE rec.ente_proprietario_id = de.ente_proprietario_id
	AND rec.causale_ep_id = tce.causale_ep_id
	AND rec.evento_id = de.evento_id
	AND rec.data_cancellazione IS NULL
);

INSERT INTO siac_r_causale_ep_stato (causale_ep_id, causale_ep_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tce.causale_ep_id, dces.causale_ep_stato_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tce.ente_proprietario_id, 'admin'
FROM siac_t_causale_ep tce
JOIN siac_d_causale_ep_stato dces ON (tce.ente_proprietario_id = dces.ente_proprietario_id)
WHERE dces.causale_ep_stato_code = 'V'
AND tce.causale_ep_code = 'EXTR'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_causale_ep_stato rces
	WHERE rces.ente_proprietario_id = tce.ente_proprietario_id
	AND rces.causale_ep_id = tce.causale_ep_id
	AND rces.causale_ep_stato_id = dces.causale_ep_stato_id
);

-- SIAC-5334 FINE

-- SIAC-5708 INIZIO - Modifiche da CSI - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_variabili" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric
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

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

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

select fnc_siac_random_user()
into	user_table;

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
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
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
select	dettaglio_variazione.elem_id,
		dettaglio_variazione.elem_det_importo,
        cat_del_capitolo.elem_cat_code,
        --------tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	      	
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
        siac_t_periodo 				anno_eserc ,
        -- 21-12 anna inizio
        siac_t_bil					t_bil,
        -- 21-12 anna fine
        siac_t_periodo 				anno_importi
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil 				= 	atto.attoamm_id)
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
-- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and		anno_eserc.anno										= 	p_anno 												
-- 21-12 anna commentato and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
-- 21-12 anna inizio
and		anno_eserc.periodo_id 								=   t_bil.periodo_id
and 	t_bil.bil_id 										=	testata_variazione.bil_id								
-- 21-12 anna fine
and		anno_importi.anno									= 	annoCapImp 												
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
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
and     r_cat_capitolo.data_cancellazione			is null;
/*group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code,
            cat_del_capitolo.elem_cat_code,
-----------------------            tipo_elemento.elem_det_tipo_code,  
        	utente,
        	atto.ente_proprietario_id;*/


    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  




insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		sum(tb1.importo)   as 		variazione_aumento_stanziato,
        sum(tb2.importo)   as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_eg_imp tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and 	tb1.importo > 0	) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	AND	tb2.importo < 0	)
    group by 	tb0.elem_id,
    			tb0.utente,
        		tb1.ente_proprietario;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;
variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;

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

-- SIAC-5708 INIZIO - Modifiche da CSI - Maurizio

-- SIAC-5641 INIZIO
DROP VIEW IF EXISTS siac.siac_v_dwh_causali_econpatr;

CREATE OR REPLACE VIEW siac.siac_v_dwh_causali_econpatr (
    ente_proprietario_id,
    causale_ep_code,
    causale_ep_desc,
    causale_ep_tipo_code,
    causale_ep_tipo_desc,
    evento_code,
    evento_desc,
    evento_tipo_code,
    evento_tipo_desc,
    pdce_conto_code,
    oper_ep_code,
    oper_ep_desc,
    classif_code,
    classif_desc)
AS
WITH tab1 AS (
SELECT -- DISTINCT 
      tce.causale_ep_id, tce.ente_proprietario_id,
      tce.causale_ep_code, tce.causale_ep_desc,
      CASE
          WHEN dcet.causale_ep_tipo_code::text = 'INT'::text THEN
          CASE
              WHEN de.evento_code::text ~~ '%RES%'::text THEN
                  "substring"(de.evento_code::text, 1, "position"(de.evento_code::text, '-'::text) + "position"("substring"(de.evento_code::text, "position"(de.evento_code::text, '-'::text) + 1), '-'::text) - 1)::character varying
              ELSE btrim("substring"(de.evento_code::text, 1,
                  "position"(de.evento_code::text, '-'::text) - 1), ' '::text)::character varying
          END
          ELSE de.evento_code
      END AS evento_code,
      de.evento_desc, dcet.causale_ep_tipo_code,
      dcet.causale_ep_tipo_desc, det.evento_tipo_code,
      det.evento_tipo_desc,
      max(rces.validita_inizio),
      max(rec.validita_inizio)
FROM siac_t_causale_ep tce
JOIN siac_r_causale_ep_stato rces ON tce.causale_ep_id = rces.causale_ep_id
JOIN siac_d_causale_ep_stato dces ON rces.causale_ep_stato_id = dces.causale_ep_stato_id
JOIN siac_d_causale_ep_tipo dcet ON dcet.causale_ep_tipo_id = tce.causale_ep_tipo_id
JOIN siac_r_evento_causale rec ON rec.causale_ep_id = tce.causale_ep_id
JOIN siac_d_evento de ON rec.evento_id = de.evento_id
JOIN siac_d_evento_tipo det ON det.evento_tipo_id = de.evento_tipo_id
WHERE dces.causale_ep_stato_code::text = 'V'::text 
AND (de.evento_code::text ~~ '%INS'::text 
     AND dcet.causale_ep_tipo_code::text = 'INT'::text 
     OR dcet.causale_ep_tipo_code::text = 'LIB'::text
    ) 
/*AND tce.data_cancellazione IS NULL 
AND rces.data_cancellazione IS NULL 
AND dces.data_cancellazione IS NULL 
AND dcet.data_cancellazione IS NULL 
AND rec.data_cancellazione IS NULL 
AND de.data_cancellazione IS NULL 
AND det.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rces.validita_inizio 
AND (date_trunc('day'::text, now()) < rces.validita_fine OR rces.validita_fine IS NULL) 
AND date_trunc('day'::text, now()) > rec.validita_inizio 
AND (date_trunc('day'::text, now()) < rec.validita_fine OR rec.validita_fine IS NULL)*/
group by tce.causale_ep_id, tce.ente_proprietario_id, evento_code,
         de.evento_desc, dcet.causale_ep_tipo_code,
         dcet.causale_ep_tipo_desc, det.evento_tipo_code,
         det.evento_tipo_desc
), 
tab2 AS (
SELECT rcepc.causale_ep_id, tpc.pdce_conto_code, doe.oper_ep_code, doe.oper_ep_desc
FROM siac_r_causale_ep_pdce_conto rcepc
JOIN siac_t_pdce_conto tpc ON rcepc.pdce_conto_id = tpc.pdce_conto_id
JOIN siac_r_causale_ep_pdce_conto_oper rcepco ON rcepc.causale_ep_pdce_conto_id = rcepco.causale_ep_pdce_conto_id
JOIN siac_d_operazione_ep doe ON doe.oper_ep_id = rcepco.oper_ep_id
WHERE (doe.oper_ep_code::text = ANY (ARRAY['DARE'::character varying::text,'AVERE'::character varying::text])) 
AND  rcepc.data_cancellazione IS NULL 
AND tpc.data_cancellazione IS NULL 
AND rcepco.data_cancellazione IS NULL 
AND doe.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rcepco.validita_inizio 
AND (date_trunc('day'::text, now()) < rcepco.validita_fine OR rcepco.validita_fine IS NULL)
), 
tab3 AS (
SELECT rcep.causale_ep_id, tc.classif_code, tc.classif_desc
FROM siac_r_causale_ep_class rcep
JOIN siac_t_class tc ON tc.classif_id = rcep.classif_id
WHERE rcep.data_cancellazione IS NULL 
AND tc.data_cancellazione IS NULL 
AND date_trunc('day'::text, now()) > rcep.validita_inizio 
AND (date_trunc('day'::text, now()) < rcep.validita_fine OR rcep.validita_fine IS NULL)
)
SELECT tab1.ente_proprietario_id, tab1.causale_ep_code, tab1.causale_ep_desc,
tab1.causale_ep_tipo_code, tab1.causale_ep_tipo_desc, tab1.evento_code,
tab1.evento_desc, tab1.evento_tipo_code, tab1.evento_tipo_desc,
tab2.pdce_conto_code, tab2.oper_ep_code, tab2.oper_ep_desc,
tab3.classif_code, tab3.classif_desc
FROM tab1
LEFT JOIN tab2 ON tab1.causale_ep_id = tab2.causale_ep_id
LEFT JOIN tab3 ON tab1.causale_ep_id = tab3.causale_ep_id;

ALTER TABLE siac_dwh_contabilita_generale ADD tipo_evento varchar(200);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
/*
pdc        record;  

impegni record; 
documenti record; 
liquidazioni_doc record; 
liquidazioni_imp record; 
ordinativi record; 
ordinativi_imp record;

prima_nota record;
movimenti  record;
causale    record;
class      record;*/

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   --IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      --p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   --ELSE
      p_data := now();
   --END IF;   
END IF;

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

insert into 
siac_dwh_contabilita_generale
select 
tb.ente_proprietario_id,
tb.ente_denominazione,
tb.bil_anno, 
tb.desc_prima_nota,
tb.num_provvisorio_prima_nota,  
tb.num_definitivo_prima_nota,
tb.data_registrazione_prima_nota,
tb.cod_stato_prima_nota,
tb.desc_stato_prima_nota,
tb.cod_mov_ep,
tb.desc_mov_ep,  
tb.cod_mov_ep_dettaglio,
tb.desc_mov_ep_dettaglio,
tb.importo_mov_ep,
tb.segno_mov_ep,
tb.cod_piano_dei_conti,
tb.desc_piano_dei_conti,
tb.livello_piano_dei_conti,
tb.ordine_piano_dei_conti,
tb.cod_pdce_fam,
tb.desc_pdce_fam,
tb.cod_ambito, 
tb.desc_ambito,  
tb.cod_causale,
tb.desc_causale,
tb.cod_tipo_causale,
tb.desc_tipo_causale,
tb.cod_stato_causale,
tb.desc_stato_causale,
tb.cod_evento,
tb.desc_evento,
tb.cod_tipo_mov_finanziario,
tb.desc_tipo_mov_finanziario,
tb.cod_piano_finanziario,
tb.desc_piano_finanziario,
tb.anno_movimento,
tb.numero_movimento,
tb.cod_submovimento,
anno_ordinativo,
num_ordinativo,
num_subordinativo,
anno_liquidazione,
num_liquidazione,
anno_doc,
num_doc,
cod_tipo_doc,
data_emissione_doc,
cod_sogg_doc,
num_subdoc,
modifica_impegno,
entrate_uscite,
tb.cod_bilancio,
p_data data_elaborazione,
numero_ricecon,
tipo_evento -- SIAC-5641
from (
select tbdoc.* from 
(
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and 
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code in ('SE','SS') 
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id= p_ente_proprietario_id 
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
  then 'CE' 
  when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
  when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
  when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
  else ''::varchar end as tipo_codifica,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id= p_ente_proprietario_id 
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null
        )
  select aa.*, 
bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
   from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  doc as (with aa as (
select a.doc_id,
b.subdoc_id, b.subdoc_numero  num_subdoc,
a.doc_anno anno_doc,
a.doc_numero num_doc, 
a.doc_data_emissione data_emissione_doc ,
c.doc_tipo_code cod_tipo_doc
 from siac_t_doc a,siac_t_subdoc b,siac_d_doc_tipo c
where b.doc_id=a.doc_id and a.ente_proprietario_id=p_ente_proprietario_id
and c.doc_tipo_id=a.doc_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is NULL)
, bb as (SELECT 
  a.doc_id,
  b.soggetto_code v_soggetto_code
      FROM   siac_r_doc_sog a, siac_t_soggetto b
      WHERE a.soggetto_id = b.soggetto_id
      and a.ente_proprietario_id=p_ente_proprietario_id 
      and a.data_cancellazione is null
and b.data_cancellazione is null
and a.validita_fine is null)
select * From 
aa left join bb ON
aa.doc_id=bb.doc_id),
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
   null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
doc.anno_doc,
doc.num_doc,
doc.cod_tipo_doc,
doc.data_emissione_doc,
doc.v_soggetto_code cod_sogg_doc,
doc.num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'SE' then
          'E'
         else
          'U'
       end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
    from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
     left join doc
  on movep.campo_pk_id=doc.subdoc_id 
  left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbdoc 
UNION
select tbimp.* from (
-- imp
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and
     i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND  p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code in ('A','I') 
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null        
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) 
  ,imp as (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento from siac_t_movgest a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  , pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.*,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
   imp.anno_movimento,imp.numero_movimento,
   null::varchar cod_submovimento 
   ,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'A' then
          'E'
         else
          'U'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from 
   movep left join 
  	movepdet on movep.movep_id=movepdet.movep_id
left join imp
  on movep.campo_pk_id=imp.movgest_id  left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbimp
UNION
--subimp acc  
select tbimp.* from (
-- imp
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND 
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code in ('SA','SI') 
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null        
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) 
  ,subimp as (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento,
  b.movgest_ts_id,b.movgest_ts_code cod_submovimento
  from siac_t_movgest a,siac_T_movgest_ts b where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.movgest_id=a.movgest_id
  )
  , pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, subimp.anno_movimento,
   subimp.numero_movimento,
   subimp.cod_submovimento
   ,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601 
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'SA' then
          'E'
         else
          'U'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
left join subimp
  on movep.campo_pk_id=subimp.movgest_ts_id    left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id ) as tbimp  
union
select tbord.* from (
-- ord
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code in ('OI', 'OP') 
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as (/* SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null        
        )
  select aa.*,bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
   ord as (select a.ord_id,a.ord_anno anno_ordinativo,a.ord_numero num_ordinativo
   from siac_t_ordinativo a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
/*  ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=3
and a.data_cancellazione is null)  */
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, 
   null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,ord.anno_ordinativo,
ord.num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601 
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'OI' then
          'E'
         else
          'U'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
   left join ord
  on movep.campo_pk_id=ord.ord_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
  ) as tbord
UNION
-- liq
select tbliq.* from (
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and 
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code ='L'
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null        
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
liq.anno_liquidazione,
liq.num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601 
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'L' then
          'U'
         else
          'E'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon   
   from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
  left join liq
  on movep.campo_pk_id=liq.liq_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
) as tbliq
union
--richiesta econ
select tbricecon.* from (
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code ='RE'
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null        
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  ricecon as (select a.ricecon_id, a.ricecon_numero numero_ricecon from siac_t_richiesta_econ a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
)       ,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601 
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'RE' then
          'U'
         else
          'E'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
ricecon.numero_ricecon   
   from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
  left join ricecon 
  on movep.campo_pk_id=ricecon.ricecon_id   left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbricecon
   union
-- mod
select tbmod.* from (
with movep as (
  select    distinct 
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno, 
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,  
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,  
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t 
    WHERE 
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and 
          q.causale_ep_id=l.causale_ep_id AND 
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and 
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL 
          and d.collegamento_tipo_code in ('MMGE','MMGS') 
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( 
/*  
SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join 
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  mod as (
select d.mod_id,
c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
b.movgest_ts_code cod_submovimento
          FROM   siac_t_movgest_ts_det_mod a,siac_T_movgest_ts b, siac_t_movgest c,
           siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f
          WHERE  a.ente_proprietario_id = p_ente_proprietario_id
and a.mod_stato_r_id=e.mod_stato_r_id
and e.mod_id=d.mod_id
and f.mod_stato_id=e.mod_stato_id
and a.movgest_ts_id=b.movgest_ts_id
and b.movgest_id=c.movgest_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
          AND    a.data_cancellazione IS NULL
          AND    b.data_cancellazione IS NULL
          AND    c.data_cancellazione IS NULL
          AND    d.data_cancellazione IS NULL
          AND    e.data_cancellazione IS NULL
          AND    f.data_cancellazione IS NULL            
UNION
select d.mod_id,
c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
b.movgest_ts_code cod_submovimento
          FROM   siac_r_movgest_ts_sog_mod a,siac_T_movgest_ts b, siac_t_movgest c,
           siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f
          WHERE  a.ente_proprietario_id = p_ente_proprietario_id
and a.mod_stato_r_id=e.mod_stato_r_id
and e.mod_id=d.mod_id
and f.mod_stato_id=e.mod_stato_id
and a.movgest_ts_id=b.movgest_ts_id
and b.movgest_id=c.movgest_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
          AND    a.data_cancellazione IS NULL
          AND    b.data_cancellazione IS NULL
          AND    c.data_cancellazione IS NULL
          AND    d.data_cancellazione IS NULL
          AND    e.data_cancellazione IS NULL
          AND    f.data_cancellazione IS NULL   )
,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and 
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )          
   select movep.*,movepdet.*--, case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno
,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , mod.v_movgest_anno anno_movimento,mod.v_movgest_numero numero_movimento,
   mod.cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno,
case -- SIAC-5601 
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case 
         when movep.cod_tipo_mov_finanziario = 'MMGE' then
          'E'
         else
          'U'
         end  
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon   
     from movep left join 
  movepdet on movep.movep_id=movepdet.movep_id
  left join mod on 
  movep.campo_pk_id=  mod.mod_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
) as tbmod   
--lib
union
select lib.* from (
with movep as (
select distinct 
m.ente_proprietario_id,
p.ente_denominazione,
i.anno AS bil_anno, 
m.pnota_desc desc_prima_nota,  
m.pnota_numero num_provvisorio_prima_nota,  
m.pnota_progressivogiornale num_definitivo_prima_nota,
m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
o.pnota_stato_code cod_stato_prima_nota,
o.pnota_stato_desc desc_stato_prima_nota,
l.movep_id,
l.movep_code cod_mov_ep,
l.movep_desc desc_mov_ep,  
q.causale_ep_code cod_causale,
q.causale_ep_desc desc_causale,
r.causale_ep_tipo_code cod_tipo_causale,
r.causale_ep_tipo_desc desc_tipo_causale,
t.causale_ep_stato_code cod_stato_causale,
t.causale_ep_stato_desc desc_stato_causale,
NULL::varchar cod_evento,
NULL::varchar desc_evento,
NULL::varchar cod_tipo_mov_finanziario,
NULL::varchar desc_tipo_mov_finanziario,
NULL::integer campo_pk_id ,
q.causale_ep_id,
NULL::varchar evento_tipo_code
FROM 
siac_t_prima_nota m,siac_d_causale_ep_tipo r,
siac_t_bil h,
siac_t_periodo i,
siac_t_mov_ep l,
siac_r_prima_nota_stato n,
siac_d_prima_nota_stato o,
siac_t_ente_proprietario p,
siac_t_causale_ep q,
siac_r_causale_ep_stato s,
siac_d_causale_ep_stato t 
WHERE 
m.ente_proprietario_id=p_ente_proprietario_id 
and r.causale_ep_tipo_code='LIB' and 
i.anno=p_anno_bilancio 
and
h.bil_id = m.bil_id AND
i.periodo_id = h.periodo_id AND
l.regep_id = m.pnota_id AND
m.pnota_id = n.pnota_id AND
o.pnota_stato_id = n.pnota_stato_id AND
--p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
p.ente_proprietario_id=m.ente_proprietario_id and 
q.causale_ep_id=l.causale_ep_id AND 
r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
o.pnota_stato_code <> 'A' and 
h.data_cancellazione IS NULL AND
i.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL AND
r.data_cancellazione IS NULL AND
s.data_cancellazione IS NULL AND
t.data_cancellazione IS NULL 
)
,
movepdet as (
with aa as 
(
select a.movep_id, b.pdce_conto_id,
a.movep_det_code cod_mov_ep_dettaglio,
a.movep_det_desc desc_mov_ep_dettaglio,
a.movep_det_importo importo_mov_ep,
a.movep_det_segno segno_mov_ep,
b.pdce_conto_code cod_piano_dei_conti,
b.pdce_conto_desc desc_piano_dei_conti,
b.livello livello_piano_dei_conti,
b.ordine ordine_piano_dei_conti,
d.pdce_fam_code cod_pdce_fam,
d.pdce_fam_desc desc_pdce_fam,
e.ambito_code cod_ambito, 
e.ambito_desc desc_ambito
From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
,siac_d_pdce_fam d,siac_d_ambito e
where a.ente_proprietario_id= p_ente_proprietario_id 
and b.pdce_conto_id=a.pdce_conto_id
and c.pdce_fam_tree_id=b.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
and c.validita_fine is null
and e.ambito_id=a.ambito_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
)
, 
bb as 
( 
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE' 
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579 
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id 
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
)
select aa.*, 
bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
from aa left join 
bb on aa.pdce_conto_id=bb.pdce_conto_id
) 
select movep.*,movepdet.*,
null::varchar cod_piano_finanziario,
null::varchar desc_piano_finanziario,
null::integer anno_movimento,
null::numeric numero_movimento,
null::varchar cod_submovimento,
null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
null::varchar entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
from movep left join 
movepdet on movep.movep_id=movepdet.movep_id
) as lib
) as tb;
               
esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5641 FINE

-- SIAC-5525 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  cod_missione varchar,
  cod_programma varchar
)
RETURNS TABLE (
  nome_ente varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  segno_importo varchar,
  importo numeric,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  livello integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
  
  --siac 5536: 10/11/2017.
  --	Nella query dinamica si ottiene un errore se il nome ente 
  -- 	contiene un apice. Sostituisco l'apice con uno doppio.  
  nome_ente:=REPLACE(nome_ente,'''','''''');  
  
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

/* 18/10/2017: resa dinamica la query perche' sono stati aggiunti i parametri 
	cod_missione e cod_programma */

/*SIAC-5525 Sostituito l'ordine delle tabelle nella query
Prima era:
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id 
e
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id 
Aggiunta inoltre la condizione

  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null))   
  
per evitare di prendere in considerazione dati con capitoli appartenenti ad un anno di bilancio
diverso da quello inserito
  */ 
    
sql_query:='select zz.* from (
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
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
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
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
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
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
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
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00002''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id
  )
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
  from missione , programma,titusc, macroag, siac_r_class progmacro
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
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.bil_id='||bilancio_id||'
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = ''CAP-UG''
  and c.elem_id=a.elem_id
  and c2.elem_id=a.elem_id
  and d.classif_id=c.classif_id
  and d2.classif_id=c2.classif_id
  and e.classif_tipo_id=d.classif_tipo_id
  and e2.classif_tipo_id=d2.classif_tipo_id
  and e.classif_tipo_code=''PROGRAMMA''
  and e2.classif_tipo_code=''MACROAGGREGATO''
  and g.elem_cat_id=f.elem_cat_id
  and f.elem_id=a.elem_id
  and g.elem_cat_code in	(''STD'',''FPV'',''FSC'',''FPVC'')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = ''VA''
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
  dati_prime_note as(
  WITH prime_note AS (
  SELECT d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  n.campo_pk_id,n.campo_pk_id_2,
  q.collegamento_tipo_code,
  b.livello
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_r_evento_reg_movfin n ON n.regmovfin_id = f.regmovfin_id
  INNER JOIN siac_d_evento p ON p.evento_id = n.evento_id
  INNER JOIN siac_d_collegamento_tipo q ON q.collegamento_tipo_id = p.collegamento_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  AND   n.data_cancellazione IS NULL
  AND   p.data_cancellazione IS NULL
  AND   q.data_cancellazione IS NULL
  ), collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  ),
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id
  FROM   siac_r_movgest_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  /* 19/09/2017: SIAC-5216.
  	Si deve testare la data di fine validita'' perche'' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e'' stata implementata sui documenti!!!! 
     E'' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e'' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu'' valida."
  */
    --and a.data_cancellazione IS NULL
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id
  FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  ),
  /* 20/09/2017: SIAC-5216..
  	Aggiunto collegamento per estrarre il capitolo nel caso il documento
  	sia una nota di Credito.
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (
  select c.elem_id, a.subdoc_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
  -- COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),
  -- collegamento_SS_SE.elem_id,
  -- collegamento_I_A.elem_id,
  -- collegamento_SI_SA.elem_id
  -- collegamento_OP_OI.elem_id
  -- collegamento_L.elem_id
  -- collegamento_RR.elem_id
  -- collegamento_RE.elem_id
  --COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id) elem_id
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id
  FROM   prime_note
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''MMGS'',''MMGE'')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''I'',''A'')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = prime_note.campo_pk_id_2
  										AND prime_note.collegamento_tipo_code IN (''SS'',''SE'')                      
  )                      
  select -- distinct
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,
  dati_prime_note.*
  from dati_prime_note
  left join cap on cap.elem_id = dati_prime_note.elem_id
  where (dati_prime_note.elem_id is null or exists (select 1 
  from siac_t_bil_elem a
  where a.ente_proprietario_id = '||p_ente_proprietario_id||'
  and   a.elem_id = dati_prime_note.elem_id
  and   a.bil_id ='||bilancio_id||'
  and   a.data_cancellazione is null)) 
  )
  select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from capall 
  left join clas on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id = capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
    select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Avere'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  	clas.programma_id = capall.programma_id and    
 	 clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' 
  union all
      select 
      '''||nome_ente||'''::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
      ''Dare'',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null ';
/*  16/10/2017: SIAC-5287.
	Aggiunto filtro su missione/programma */      
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' AND clas.missione_code ='''||cod_missione||'''';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' AND clas.programma_code ='''||cod_programma||'''';
  end if;
  sql_query:=sql_query||' ) as zz ';
/*  16/10/2017: SIAC-5287.
    	Aggiunta gestione delle prime note libere.
*/  
sql_query:=sql_query||' 
UNION
  select xx.* from (
  WITH prime_note_lib AS (
  SELECT b.ente_proprietario_id, d_caus_ep.causale_ep_tipo_code, d.pdce_fam_code, d.pdce_fam_desc,
  e.movep_det_segno,
  e.movep_det_importo importo,
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_code
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_code
  END pdce_conto_code,   
  CASE 
   WHEN b.livello = 7 THEN
      (SELECT o.pdce_conto_desc
      FROM   siac_t_pdce_conto o
      WHERE  o.pdce_conto_id = b.pdce_conto_id_padre
      AND    o.data_cancellazione IS NULL)
   ELSE
       b.pdce_conto_desc
  END pdce_conto_desc,
  b.livello,e.movep_det_id
  FROM  siac_t_pdce_conto b
  INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
  INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
  INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
  --LEFT JOIN  siac_r_mov_ep_det_class r_mov_ep_det_class 
  --		ON (r_mov_ep_det_class.movep_det_id=e.movep_det_id
   --     	AND r_mov_ep_det_class.data_cancellazione IS NULL)
  INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
  INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
  INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
  INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
  INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
  INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id 
  INNER JOIN siac_t_causale_ep t_caus_ep ON t_caus_ep.causale_ep_id=f.causale_ep_id
  INNER JOIN siac_d_causale_ep_tipo d_caus_ep ON d_caus_ep.causale_ep_tipo_id=t_caus_ep.causale_ep_tipo_id
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   m.pnota_stato_code = ''D''
  AND   i.anno = '''||p_anno_bilancio||'''
  AND   d.pdce_fam_code in (''CE'',''RE'')
  AND   d_caus_ep.causale_ep_tipo_code =''LIB''
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
  AND   f.data_cancellazione IS NULL
  AND   g.data_cancellazione IS NULL
  AND   h.data_cancellazione IS NULL
  AND   i.data_cancellazione IS NULL
  AND   l.data_cancellazione IS NULL
  AND   m.data_cancellazione IS NULL
  ),
ele_prime_note_progr as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''PROGRAMMA''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),
ele_prime_note_miss as (
  	select r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id='||p_ente_proprietario_id||'
        and d_class_tipo.classif_tipo_code=''MISSIONE''
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),        
  missione as 
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
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
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
  a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = ''00001''
  and to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))
  and b.classif_id_padre is not  null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.classif_tipo_id=a.classif_tipo_id)
select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	prime_note_lib.movep_det_segno::varchar segno_importo,
    prime_note_lib.importo::numeric ,
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
  if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if;
  sql_query:=sql_query||'
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Dare''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||' 
union select '''||nome_ente||'''::varchar nome_ente, 
	COALESCE(missione.missione_code,'''')::varchar missione_code, 
    COALESCE(missione.missione_desc,'''')::varchar missione_desc,
	COALESCE(programma.programma_code,'''')::varchar programma_code, 
	COALESCE(programma.programma_desc,'''')::varchar programma_desc,
	''Avere''::varchar segno_importo,
    0.00::numeric(15,2),
	prime_note_lib.pdce_conto_code::varchar,
    prime_note_lib.pdce_conto_desc::varchar,
    prime_note_lib.livello::integer  
from prime_note_lib
	LEFT JOIN ele_prime_note_progr ON ele_prime_note_progr.movep_det_id=prime_note_lib.movep_det_id
    LEFT JOIN ele_prime_note_miss ON ele_prime_note_miss.movep_det_id=prime_note_lib.movep_det_id
	LEFT JOIN programma ON programma.programma_id = ele_prime_note_progr.classif_id
    LEFT JOIN missione ON missione.missione_id=ele_prime_note_miss.classif_id ';  
if cod_missione <> 'T' THEN
  	sql_query:=sql_query||' 
    	WHERE (missione.missione_code ='''||cod_missione||''' OR ele_prime_note_miss.movep_det_id is null) ';
  end if;
  if cod_programma <> 'T' THEN
  	sql_query:=sql_query||' 
    	AND (programma.programma_code ='''||cod_programma||''' OR ele_prime_note_progr.movep_det_id is null) ';
  end if; 
sql_query:=sql_query||'
    ) as xx';
    
raise notice 'sql_query= %',     sql_query;

  return query execute sql_query;
  

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
-- SIAC-5525 FINE

-- SIAC-5522 INIZIO
ALTER TABLE siac_dwh_ordinativo_incasso ADD caus_id integer;

ALTER TABLE siac_dwh_subordinativo_incasso ADD caus_id integer;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_incasso (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico ordinativi in incasso (FNC_SIAC_DWH_ORDINATIVO_INCASSO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;


INSERT INTO siac.siac_dwh_ordinativo_incasso
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_inc,
  num_ord_inc,
  desc_ord_inc,
  cod_stato_ord_inc,
  desc_stato_ord_inc,
  castelletto_cassa_ord_inc,
  castelletto_competenza_ord_inc,
  castelletto_emessi_ord_inc,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordin,
  data_inizio_val_ordin,
  data_creazione_ordin,
  data_modifica_ordin,
  data_trasmissione,
  cod_siope,
  desc_siope,
  caus_id -- SIAC-5522
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante, 
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban, 
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla26_classif_tipo_desc,tb.cla26_classif_code,tb.cla26_classif_desc,
tb.cla27_classif_tipo_desc,tb.cla27_classif_code,tb.cla27_classif_desc,
tb.cla28_classif_tipo_desc,tb.cla28_classif_code,tb.cla28_classif_desc,
tb.cla29_classif_tipo_desc,tb.cla29_classif_code,tb.cla29_classif_desc, 
tb.cla30_classif_tipo_desc,tb.cla30_classif_code,tb.cla30_classif_desc, 
tb.v_flagAllegatoCartaceo,
tb.v_cup,
tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo , 
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope,
tb.caus_id -- SIAC-5522
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data,
a.caus_id -- SIAC-5522
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i 
where  d.ente_proprietario_id = p_ente_proprietario_id
and 
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla26_classif_tipo_desc,      
b.classif_code cla26_classif_code, b.classif_desc cla26_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_26'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla27_classif_tipo_desc,
b.classif_code cla27_classif_code, b.classif_desc cla27_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_27'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla28_classif_tipo_desc,
b.classif_code cla28_classif_code, b.classif_desc cla28_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_28'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla29_classif_tipo_desc,
b.classif_code cla29_classif_code, b.classif_desc cla29_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_29'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla30_classif_tipo_desc,
b.classif_code cla30_classif_code, b.classif_desc cla30_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_30'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cup as (
SELECT 
a.ord_id
, a.testo v_cup
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
a.ord_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (        
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (        
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_entrata a,  mif_t_flusso_elaborato b 
      where a.ente_proprietario_id=p_ente_proprietario_id  
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero  
      from mif_t_ordinativo_entrata a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id   
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id 
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'E'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_ENTRATA_I'
      and   a.classif_code not in ('XXXX','YYYY')
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1 
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id 
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno 
    and  mif1.mif_ord_numero=mifmax.mif_ord_numero) as tb
    ) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo, t_cup.v_cup,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class26.*,class27.*,class28.*,class29.*,class30.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_cup
on ord_pag.ord_id=t_cup.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id  
left join impattuale
on ord_pag.ord_id=impattuale.ord_id  
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
) as tb; 

 
    
     INSERT INTO siac.siac_dwh_subordinativo_incasso
    (
    ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_inc,
    num_ord_inc,
    desc_ord_inc,
    cod_stato_ord_inc,
    desc_stato_ord_inc,
    castelletto_cassa_ord_inc,
    castelletto_competenza_ord_inc,
    castelletto_emessi_ord_inc,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_inc,
    desc_subord_inc,
    data_scadenza,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_accertamento,
    num_accertamento,
    desc_accertamento,
    cod_subaccertamento,
    importo_quietanziato,
    data_inizio_val_stato_ordin,
    data_inizio_val_subordin,
    data_creazione_subordin,
    data_modifica_subordin,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc,
    caus_id -- SIAC-5522    
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.movgest_anno,tb.movgest_numero,tb.movgest_desc,tb.movgest_ts_code,
case when tb.ord_stato_code='Q' then tb.importo_attuale else null end importo_quietanziato,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code,
tb.caus_id_ord -- SIAC-5522
from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
       l.validita_inizio as data_inizio_val_subordpg,
       l.data_creazione as data_creazione_subordpg,
       l.data_modifica as data_modifica_subordpg,
       a.caus_id as caus_id_ord-- SIAC-5522    
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id 
and 
c.anno = p_anno_bilancio--p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
b.ord_ts_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id 
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
),
 causale as (SELECT 
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT 
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id 
    AND doa.data_cancellazione IS NULL)  
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt 
on onere.onere_att_id=onatt.onere_att_id)
,
movgest as (
select a.ord_ts_id, c.movgest_anno,c.movgest_numero,c.movgest_desc,
case when d.movgest_ts_tipo_code = 'T' then
     	null
     else
     	b.movgest_ts_code
end movgest_ts_code 
from  
siac_r_ordinativo_ts_movgest_ts a,siac_t_movgest_ts b,siac_t_movgest c,siac_d_movgest_ts_tipo d
where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.movgest_ts_id=b.movgest_ts_id
and c.movgest_id=b.movgest_id
and d.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and p_data BETWEEN a.validita_inizio and COALESCE (a.validita_fine,p_data)
)  ,
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,    	        
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id    
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND 
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc, 
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id    
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id           
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL        
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND 
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data)) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,
movgest.ord_ts_id, movgest.movgest_anno,movgest.movgest_numero,movgest.movgest_desc,movgest.movgest_ts_code,
elenco_doc.*
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id  
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id  
left join firma
on ord_pag.ord_id=firma.ord_id 
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id     
left join movgest
on ord_pag.ord_ts_id=movgest.ord_ts_id 
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id  
) as tb;
  

esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5522 FINE

-- SIAC-5567 INIZIO
CREATE OR REPLACE VIEW siac_v_dwh_registrazioni (
ente_proprietario_id,
anno_bilancio,
cod_tipo_evento,
desc_tipo_evento,
cod_tipo_mov_finanziario,
desc_tipo_mov_finanziario,
cod_evento,
desc_evento,    
data_creazione_registrazione,
cod_stato_registrazione, 
desc_stato_registrazione,    
ambito,
validita_inizio,
validita_fine,
cod_pdc_fin_orig,
desc_pdc_fin_orig,
cod_pdc_fin_agg,
desc_pdc_fin_agg,
anno_movimento_mod,
numero_movimento_mod,
cod_submovimento_mod,
anno_movimento,
numero_movimento,
cod_submovimento,
doc_id,
anno_doc,
num_doc,
cod_tipo_doc,
data_emissione_doc, 
num_subdoc,
cod_sogg_doc,
anno_ordinativo,
numero_ordinativo,
anno_liquidazione, 
numero_liquidazione,
numero_ricecon,
anno_rateo_risconto, 
numero_pn_rateo_risconto, 
anno_pn_rateo_risconto 
)
AS
WITH registrazioni AS (
SELECT  
    a.ente_proprietario_id,
    i.anno,
    g.evento_tipo_code,
    g.evento_tipo_desc,
    d.collegamento_tipo_code,
    d.collegamento_tipo_desc,
    c.evento_code,
    c.evento_desc,    
    a.data_creazione,
    f.regmovfin_stato_code, 
    f.regmovfin_stato_desc,    
    l.ambito_code,
    a.validita_inizio,
    a.validita_fine,
    a.classif_id_iniziale, a.classif_id_aggiornato,
    b.campo_pk_id, b.campo_pk_id_2
FROM siac_t_reg_movfin a, siac_r_evento_reg_movfin b, siac_d_evento c,
    siac_d_collegamento_tipo d, siac_r_reg_movfin_stato e,
    siac_d_reg_movfin_stato f, siac_d_evento_tipo g, siac_t_bil h,
    siac_t_periodo i, siac_d_ambito l
WHERE a.regmovfin_id = b.regmovfin_id 
AND c.evento_id = b.evento_id 
AND d.collegamento_tipo_id = c.collegamento_tipo_id 
AND g.evento_tipo_id = c.evento_tipo_id 
AND e.regmovfin_id = a.regmovfin_id 
AND f.regmovfin_stato_id = e.regmovfin_stato_id 
AND h.bil_id = a.bil_id 
AND i.periodo_id = h.periodo_id 
AND l.ambito_id = a.ambito_id
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
), 
collegamento_MMGS_MMGE_a AS (
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
      siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt, siac_t_movgest tmov
WHERE tm.mod_id = rms.mod_id  
AND   rms.mod_stato_id = dms.mod_stato_id
AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   tmtdm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
),
collegamento_MMGS_MMGE_b AS (
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
      siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt, siac_t_movgest tmov
WHERE tm.mod_id = rms.mod_id  
AND   rms.mod_stato_id = dms.mod_stato_id
AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   rmtsm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
),
collegamento_I_A AS (
SELECT a.movgest_id, a.movgest_anno, a.movgest_numero
FROM   siac_t_movgest a
WHERE  a.data_cancellazione IS NULL
),
collegamento_SI_SA AS (
SELECT a.movgest_ts_id, b.movgest_anno, b.movgest_numero, a.movgest_ts_code
FROM  siac_t_movgest_ts a, siac_t_movgest b
WHERE a.movgest_id = b.movgest_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
collegamento_SS_SE AS (
SELECT a.subdoc_id, b.doc_id, b.doc_anno, b.doc_numero, b.doc_data_emissione, a.subdoc_numero,
       c.doc_tipo_code
FROM   siac_t_subdoc a, siac_t_doc b, siac_d_doc_tipo c  
WHERE  a.doc_id = b.doc_id
AND    c.doc_tipo_id = b.doc_tipo_id
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL
),
collegamento_OP_OI AS (
SELECT a.ord_id, a.ord_anno, a.ord_numero
FROM   siac_t_ordinativo a
WHERE  a.data_cancellazione IS NULL
),
collegamento_L AS (
SELECT a.liq_id, a.liq_anno, a.liq_numero
FROM   siac_t_liquidazione a
WHERE  a.data_cancellazione IS NULL
),
collegamento_RR AS (
SELECT a.gst_id, b.ricecon_id, b.ricecon_numero
FROM  siac_t_giustificativo a, siac_t_richiesta_econ b
WHERE a.ricecon_id = b.ricecon_id
AND   a.data_cancellazione  IS NULL
AND   b.data_cancellazione  IS NULL
),
collegamento_RE AS (
SELECT a.ricecon_id, a.ricecon_numero
FROM  siac_t_richiesta_econ a
WHERE a.data_cancellazione  IS NULL
),
soggetto_doc AS (
SELECT distinct a.doc_id, b.soggetto_code 
FROM  siac_r_doc_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
collegamento_RT_RS AS (
SELECT a.pnotarr_id, 
       a.anno as anno_rateo_risconto, 
       b.pnota_progressivogiornale as numero_pn_rateo_risconto, 
       d.anno as anno_pn_rateo_risconto
FROM  siac_t_prima_nota_ratei_risconti a, siac_t_prima_nota b, siac_t_bil c, siac_t_periodo d
WHERE a.pnota_id = b.pnota_id
AND   b.bil_id = c.bil_id
AND   c.periodo_id = d.periodo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
)
SELECT
registrazioni.ente_proprietario_id,
registrazioni.anno as anno_bilancio,
registrazioni.evento_tipo_code as cod_tipo_evento,
registrazioni.evento_tipo_desc as desc_tipo_evento,
registrazioni.collegamento_tipo_code as cod_tipo_mov_finanziario,
registrazioni.collegamento_tipo_desc as desc_tipo_mov_finanziario,
registrazioni.evento_code as cod_evento,
registrazioni.evento_desc as desc_evento,    
registrazioni.data_creazione as data_creazione_registrazione,
registrazioni.regmovfin_stato_code as cod_stato_registrazione, 
registrazioni.regmovfin_stato_desc as desc_stato_registrazione,    
registrazioni.ambito_code as ambito,
registrazioni.validita_inizio,
registrazioni.validita_fine,
pdc_fin_orig.classif_code as cod_pdc_fin_orig,
pdc_fin_orig.classif_desc as desc_pdc_fin_orig,
pdc_fin_agg.classif_code as cod_pdc_fin_agg,
pdc_fin_agg.classif_desc as desc_pdc_fin_agg,
COALESCE(collegamento_MMGS_MMGE_a.movgest_anno,collegamento_MMGS_MMGE_b.movgest_anno) as anno_movimento_mod,
COALESCE(collegamento_MMGS_MMGE_a.movgest_numero,collegamento_MMGS_MMGE_b.movgest_numero) as numero_movimento_mod,
COALESCE(collegamento_MMGS_MMGE_a.movgest_ts_code,collegamento_MMGS_MMGE_b.movgest_ts_code) as cod_submovimento_mod,
COALESCE(collegamento_I_A.movgest_anno,collegamento_SI_SA.movgest_anno) as anno_movimento,
COALESCE(collegamento_I_A.movgest_numero,collegamento_SI_SA.movgest_numero) as numero_movimento,
collegamento_SI_SA.movgest_ts_code as cod_submovimento,
collegamento_SS_SE.doc_id,
collegamento_SS_SE.doc_anno as anno_doc,
collegamento_SS_SE.doc_numero as num_doc,
collegamento_SS_SE.doc_tipo_code as cod_tipo_doc,
collegamento_SS_SE.doc_data_emissione as data_emissione_doc, 
collegamento_SS_SE.subdoc_numero as num_subdoc,
soggetto_doc.soggetto_code as cod_sogg_doc,
collegamento_OP_OI.ord_anno as anno_ordinativo,
collegamento_OP_OI.ord_numero as numero_ordinativo,
collegamento_L.liq_anno as anno_liquidazione, 
collegamento_L.liq_numero as numero_liquidazione,
COALESCE(collegamento_RR.ricecon_numero,collegamento_RE.ricecon_numero) as numero_ricecon,
collegamento_RT_RS.anno_rateo_risconto, 
collegamento_RT_RS.numero_pn_rateo_risconto, 
collegamento_RT_RS.anno_pn_rateo_risconto 
FROM registrazioni
LEFT JOIN siac_t_class pdc_fin_orig ON registrazioni.classif_id_iniziale = pdc_fin_orig.classif_id
                                    AND  pdc_fin_orig.data_cancellazione is null  
LEFT JOIN siac_t_class pdc_fin_agg ON registrazioni.classif_id_aggiornato = pdc_fin_agg.classif_id
                                    AND  pdc_fin_agg.data_cancellazione is null  
LEFT JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = registrazioni.campo_pk_id
                                   AND registrazioni.collegamento_tipo_code IN ('MMGS','MMGE') 
LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = registrazioni.campo_pk_id
                                     AND registrazioni.collegamento_tipo_code IN ('MMGS','MMGE')
LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code IN ('I','A')
LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code IN ('SI','SA')                                     
LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = COALESCE(registrazioni.campo_pk_id, registrazioni.campo_pk_id_2) 
                                       AND registrazioni.collegamento_tipo_code IN ('SS','SE')                                       
LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code IN ('OP','OI')
LEFT   JOIN collegamento_L ON collegamento_L.liq_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code = 'L'
LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code = 'RR'
LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = registrazioni.campo_pk_id
                                       AND registrazioni.collegamento_tipo_code = 'RE'
LEFT JOIN collegamento_RT_RS ON collegamento_RT_RS.pnotarr_id = registrazioni.campo_pk_id
                                        AND registrazioni.collegamento_tipo_code in ('RT','RS') 
LEFT JOIN soggetto_doc ON collegamento_SS_SE.doc_id = soggetto_doc.doc_id;
-- SIAC-5567 FINE

--SIAC-5480 INIZIO
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacfinapp/azioneRichiesta.do', FALSE, to_timestamp('01/01/2017','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = tep.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-SPE-reintroitoOrdPag', 'Gestione Reintroiti', 'ATTIVITA_SINGOLA', 'FIN_BASE1')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO 
  siac.siac_d_relaz_tipo
(
  relaz_tipo_code,
  relaz_tipo_desc,
  relaz_entita_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'REI_ORD','ORDINATIVO SUBORDINATO - DA INCASSO A PAGAMENTO',b.relaz_entita_id,
to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,
'admin'
from siac.siac_t_ente_proprietario a
left join siac.siac_d_relaz_entita b
on b.ente_proprietario_id=a.ente_proprietario_id
and b.relaz_entita_code=null
--SIAC-5480 FINE
