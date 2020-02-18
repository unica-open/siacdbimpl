/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_accertamento (integer,  integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_accertamento (
  _uid_accertamento integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_anno integer,
  ord_numero numeric,
  ord_desc varchar,
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
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  capitolo_desc varchar,
  capitolo_anno varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp,
  ord_quietanza_data timestamp,
  -- 13.07.2018 Sofia jira siac-6193
  ord_emissione_data timestamp,
  conto_tesoreria varchar,
  distinta_code varchar,
  distinta_desc varchar,
  ord_split     varchar,
  ord_ritenute  varchar
) AS
$body$
DECLARE
_offset INTEGER := (_page) * _limit;
_test VARCHAR := 'test';
rec record;
v_ord_id integer;
v_attoamm_id integer;
v_ord_ts_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			d.ord_id,
			d.ord_anno,
			d.ord_numero,
			d.ord_desc,
			l.ord_stato_desc,
			g.ord_ts_code,
			g.ord_ts_id,
            -- 13.07.2018 Sofia jira siac-6193
            d.ord_emissione_data,
            d.contotes_id,
            d.dist_id
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_ordinativo_bil_elem b,
			siac_t_ordinativo d,
			siac_d_ordinativo_tipo e,
			siac_r_ordinativo_ts_movgest_ts f,
			siac_t_ordinativo_ts g,
			siac_t_movgest_ts h,
			siac_r_ordinativo_stato i,
			siac_d_ordinativo_stato l
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and b.elem_id=a.elem_id
		and d.ord_id=b.ord_id
		and e.ord_tipo_id=d.ord_tipo_id
		and e.ord_tipo_code='I'
		and f.ord_ts_id=g.ord_ts_id
		and g.ord_id=d.ord_id
		and h.movgest_ts_id=f.movgest_ts_id
		and h.movgest_id=_uid_accertamento
		and i.ord_id=d.ord_id
		and l.ord_stato_id=i.ord_stato_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and b.data_cancellazione is null
		and d.data_cancellazione is null
		and b2.data_cancellazione is null
		and c2.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		order by 7,8
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.elem_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			ord_anno:=rec.ord_anno;
			ord_numero:=rec.ord_numero;
			ord_desc:=rec.ord_desc;
			v_ord_id:=rec.ord_id;
			ord_stato_desc:=rec.ord_stato_desc;
			ord_ts_code:=rec.ord_ts_code;
			v_ord_ts_id:=rec.ord_ts_id;

			select
				f.ord_ts_det_importo
			into importo
			from
				siac_t_ordinativo_ts e,
				siac_t_ordinativo_ts_det f,
				siac_d_ordinativo_ts_det_tipo g
			where e.ord_ts_id=v_ord_ts_id
			and f.ord_ts_id=e.ord_ts_id
			and g.ord_ts_det_tipo_id=f.ord_ts_det_tipo_id
			and g.ord_ts_det_tipo_code='A'
			and e.data_cancellazione is null
			and f.data_cancellazione is null
			and g.data_cancellazione is null;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_ordinativo_soggetto z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.ord_id=v_ord_id;

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
				siac_r_ordinativo_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.ord_id=v_ord_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

             --SIAC-5899
              SELECT
                  siac_r_ordinativo_quietanza.ord_quietanza_data
              INTO
                  ord_quietanza_data
              FROM
                  siac_t_oil_ricevuta
                  ,siac_T_Ordinativo
                  ,siac_d_oil_ricevuta_tipo
                  ,siac_r_ordinativo_quietanza
              WHERE
                      siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
                  AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
                  AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
                  AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
                  AND siac_T_Ordinativo.ord_Id = v_ord_id
                  AND siac_t_oil_ricevuta.data_cancellazione is null
                  AND siac_T_Ordinativo.data_cancellazione is null
                  AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
                  AND siac_r_ordinativo_quietanza.data_cancellazione is null;

            -- 13.07.2018 Sofia jira siac-6193
            ord_emissione_data:=rec.ord_emissione_data;

            -- 13.07.2018 Sofia jira siac-6193
            conto_tesoreria:=null;
            select conto.contotes_code into conto_tesoreria
            from siac_d_contotesoreria conto
            where conto.contotes_id=rec.contotes_id;

            distinta_code:=null;
            distinta_desc:=null;
            select d.dist_code, d.dist_desc
                   into distinta_code, distinta_desc
            from siac_d_distinta d
            where d.dist_id=rec.dist_id;

            -- 13.07.2018 Sofia jira siac-6193
            ord_split:=null;
           	select tipo.relaz_tipo_code into ord_split
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='SPR'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
			if ord_split is not null then
                 ord_split:='S';
            else ord_split:='N';
            end if;

            -- 13.07.2018 Sofia jira siac-6193
            ord_ritenute:=null;
            select tipo.relaz_tipo_code into ord_ritenute
            from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                 siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
  		    where rord.ord_id_a=rec.ord_id
            and   tipo.relaz_tipo_id=rord.relaz_tipo_id
            and   tipo.relaz_tipo_code='RIT_ORD'
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
            limit 1;
            if ord_ritenute is not null then
                 ord_ritenute:='S';
            else ord_ritenute:='N';
            end if;

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