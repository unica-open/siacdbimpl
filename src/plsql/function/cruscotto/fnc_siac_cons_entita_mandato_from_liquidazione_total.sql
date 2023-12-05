/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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

