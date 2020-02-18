/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_soggetto(_uid_soggetto integer, _annoesercizio character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, ord_numero numeric, ord_desc character varying, ord_emissione_data timestamp without time zone, soggetto_code character varying, soggetto_desc character varying, accredito_tipo_code character varying, accredito_tipo_desc character varying, ord_stato_desc character varying, importo numeric, ord_ts_code character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, uid_capitolo integer, capitolo_numero character varying, capitolo_articolo character varying, num_ueb character varying, capitolo_desc character varying, capitolo_anno character varying, provc_anno integer, provc_numero numeric, provc_data_convalida timestamp without time zone, ord_quietanza_data timestamp without time zone, conto_tesoreria character varying, distinta_code character varying, distinta_desc character varying, ord_split character varying, ord_ritenute character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
    v_ente_proprietario_id INTEGER;
BEGIN

	select ente_proprietario_id	into v_ente_proprietario_id from siac_t_soggetto where soggetto_id = _uid_soggetto;
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
					f.ord_ts_code,
                    -- 13.07.2018 Sofia jira siac-6193
                    a.contotes_id,
                    a.dist_id
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper

				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id

                and a.bil_id = tbil.bil_id
                and tbil.periodo_id	= tper.periodo_id
                and tper.anno = _annoEsercizio
				and a.ente_proprietario_id =  v_ente_proprietario_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='I'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and h.data_cancellazione is null
                and tbil.data_cancellazione is null
				and tper.data_cancellazione is null

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
                and n.ente_proprietario_id =  v_ente_proprietario_id
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
					s.elem_desc,
					y.anno capitolo_anno
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s,
					siac_t_bil x,
					siac_t_periodo y
				where s.elem_id=r.elem_id
				and x.bil_id=s.bil_id
				and y.periodo_id=x.periodo_id
                and x.ente_proprietario_id =  v_ente_proprietario_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and x.data_cancellazione is null
				and y.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				select c2.ord_id,
					e2.accredito_tipo_code,
					e2.accredito_tipo_desc
				FROM
					siac_r_ordinativo_modpag c2,
					siac_t_modpag d2,
					siac_d_accredito_tipo e2
				where c2.modpag_id=d2.modpag_id
				and e2.accredito_tipo_id=d2.accredito_tipo_id
				and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
                and d2.ente_proprietario_id =  v_ente_proprietario_id
				and c2.data_cancellazione is null
				and d2.data_cancellazione is null
				and e2.data_cancellazione is null
			),
            -- 13.07.2018 Sofia siac-6193
            conto_tesoreria as
            (
            	select conto.contotes_id, conto.contotes_code
                from siac_d_contotesoreria conto
                where conto.data_cancellazione is null
            ),
            -- 13.07.2018 Sofia siac-6193
            distinta as
            (
            	select d.dist_id, d.dist_code, d.dist_desc
                from siac_d_distinta d
                where 
                    d.ente_proprietario_id =  v_ente_proprietario_id
                and d.data_cancellazione is null
            )
			select *
			from ordinativo
			join soggetto on ordinativo.uid=soggetto.ord_id
			join attoamm on ordinativo.uid=attoamm.ord_id
			join capitolo on ordinativo.uid=capitolo.ord_id
			left outer join modpag on ordinativo.uid=modpag.ord_id
            -- 13.07.2018 Sofia siac-6193
            left join conto_tesoreria on (ordinativo.contotes_id=conto_tesoreria.contotes_id)
            left join distinta on (ordinativo.dist_id=distinta.dist_id)
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
            and y.ente_proprietario_id =  v_ente_proprietario_id
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
/*	--Haithm 27/11/2019  SIAC-7222		
   provv_cassa as(
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
        and b2.ente_proprietario_id =  v_ente_proprietario_id
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),*/
    quietanza AS(
     --SIAC-5899
        SELECT
            siac_T_Ordinativo.ord_id,
            --SIAC-7222  siac_r_ordinativo_quietanza.ord_quietanza_data
            MAX(siac_r_ordinativo_quietanza.ord_quietanza_data) as ord_quietanza_data

        --INTO
            --ord_quietanza_data
        FROM
            siac_t_oil_ricevuta
            ,siac_T_Ordinativo
            ,siac_d_oil_ricevuta_tipo
            ,siac_r_ordinativo_quietanza
        WHERE
                siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
            AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
            AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
            and siac_t_ordinativo.ente_proprietario_id =  v_ente_proprietario_id
            AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'            
            --AND siac_T_Ordinativo.ord_Id = uid
            AND siac_t_oil_ricevuta.data_cancellazione is null
            AND siac_T_Ordinativo.data_cancellazione is null
            AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
            AND siac_r_ordinativo_quietanza.data_cancellazione is null
            group by siac_T_Ordinativo.ord_id
            ),
    split as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='SPR'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   tipo.ente_proprietario_id =  v_ente_proprietario_id
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
            and   tipo.data_cancellazione is null
            and   stato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
        ),
        ritenute as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='RIT_ORD'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ente_proprietario_id =  v_ente_proprietario_id
			and   stato.ord_stato_code!='A'
            and   tipo.data_cancellazione is null
            and   stato.data_cancellazione is null
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
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
		ord_join_outer.elem_code as capitolo_numero,
		ord_join_outer.elem_code2 as capitolo_articolo,
		ord_join_outer.elem_code3 as numero_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		ord_join_outer.capitolo_anno as capitolo_anno,
		--SIAC-7222
		cast(null as integer) as provc_anno, --provv_cassa.provc_anno,
		cast(null as numeric) as provc_numero, --provv_cassa.provc_numero,
		cast(null as timestamp without time zone) as provc_data_convalida, --provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data,
        -- 13.07.2018 Sofia siac-6193
        ord_join_outer.contotes_code conto_tesoreria,
        ord_join_outer.dist_code distinta_code,
        ord_join_outer.dist_desc distinta_desc,
        (case when split.ord_id is not null then 'S' else 'N' end)::varchar ord_split,
        (case when ritenute.ord_id is not null then 'S' else 'N' end)::varchar ord_ritenute
	from ord_join_outer
		--left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id  --SIAC-7222		
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
        -- 13.07.2018 Sofia siac-6193
  	    left outer join split on ord_join_outer.uid=split.ord_id
        left outer join ritenute on ord_join_outer.uid=ritenute.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$function$
;