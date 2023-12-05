/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- SIAC-5152: DROP FUNZIONE CON TRE (vecchia versione) E QUATTRO (nuova versione) PARAMETRI
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
  pdc_desc varchar,
  -- 26.06.2018 Sofia siac-6193
  impegno_anno_capitolo integer,
  impegno_nro_capitolo  integer,
  impegno_nro_articolo  integer,
  impegno_flag_prenotazione varchar,
  impegno_cup varchar,
  impegno_cig varchar,
  impegno_tipo_debito varchar,
  impegno_motivo_assenza_cig varchar,
  attoamm_desc varchar
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
                a.attoamm_oggetto attoamm_desc, -- 26.06.2018 Sofia siac-6193
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
            attoamm.attoamm_desc, -- 26.06.2018 Sofia siac-6193
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
			b.classif_desc pdc_desc,
            f.siope_tipo_debito_id,
            f.siope_assenza_motivazione_id
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
	),
    -- 26.06.2018 Sofia siac-6193
    capitolo as
    (
    select r.movgest_id,
           e.elem_code::integer nro_capitolo,
           e.elem_code2::integer nro_articolo,
           per.anno::integer anno_capitolo
    from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,siac_r_movgest_bil_elem r,
         siac_t_bil bil, siac_t_periodo per
    where tipo.elem_tipo_code='CAP-UG'
    and   e.elem_tipo_id=tipo.elem_tipo_id
    and   r.elem_id=e.elem_id
    and   bil.bil_id=e.bil_id
    and   per.periodo_id=bil.periodo_id
    and   e.data_cancellazione is null
    and   now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())
    and   r.data_cancellazione is null
    and   now() BETWEEN r.validita_inizio and COALESCE(r.validita_fine,now())
    ),
    -- 26.06.2018 Sofia siac-6193
    flagPrenotazione as
    (
    select rattr.movgest_ts_id,
           rattr.boolean
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='flagPrenotazione'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
    ),
    cup as
    (
    select rattr.movgest_ts_id,
           rattr.testo
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='cup'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
    ),
    cig as
    (
    select rattr.movgest_ts_id,
           rattr.testo
    from siac_r_movgest_ts_attr rattr, siac_t_attr attr
    where attr.attr_code='cig'
    and   rattr.attr_id=attr.attr_id
    and   rattr.data_cancellazione is null
    and   now() BETWEEN rattr.validita_inizio and COALESCE(rattr.validita_fine,now())
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
		sogg.pdc_desc,
        -- 26.06.2018 Sofia siac-6193
        capitolo.anno_capitolo impegno_anno_capitolo,
        capitolo.nro_capitolo  impegno_nro_capitolo,
        capitolo.nro_articolo  impegno_nro_articolo,
        coalesce(flagPrenotazione.boolean,'N')::varchar impegno_flag_prenotazione,
        coalesce(cup.testo,' ') impegno_cup,
        coalesce(cig.testo,' ') impegno_cig,
        coalesce(deb.siope_tipo_debito_desc,' ') impegno_tipo_debito,
        coalesce(ass.siope_assenza_motivazione_desc,' ') impegno_motivo_assenza_cig,
        attoammsac.attoamm_desc
   from
         sogg
	     left outer join attoammsac on attoammsac.movgest_ts_id=sogg.movgest_ts_id
          -- 26.06.2018 Sofia siac-6193
         left outer join capitolo on  sogg.uid=capitolo.movgest_id
         left outer join flagPrenotazione on sogg.movgest_ts_id=flagPrenotazione.movgest_ts_id
         left outer join cup on sogg.movgest_ts_id=cup.movgest_ts_id
         left outer join cig on sogg.movgest_ts_id=cig.movgest_ts_id
         left outer join siac_d_siope_assenza_motivazione ass on sogg.siope_assenza_motivazione_id=ass.siope_assenza_motivazione_id
         left outer join siac_d_siope_tipo_debito deb on sogg.siope_tipo_debito_id=deb.siope_tipo_debito_id
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