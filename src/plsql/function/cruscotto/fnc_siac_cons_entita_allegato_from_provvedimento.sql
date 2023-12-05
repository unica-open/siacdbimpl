/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION fnc_siac_cons_entita_allegato_from_provvedimento(INTEGER, INTEGER, INTEGER);

CREATE FUNCTION fnc_siac_cons_entita_allegato_from_provvedimento(
_uid_provvedimento integer,
_limit integer, 
_page integer
)
RETURNS table(
	uid integer,
 	attoal_causale varchar,
 	attoal_data_scadenza timestamp,
 	attoal_stato_desc varchar,	
 	attoal_versione_invio_firma integer,
 	attoamm_numero integer,
 	attoamm_anno varchar,
 	attoamm_tipo_code varchar,
 	attoamm_tipo_desc varchar,
 	attoamm_stato_desc varchar,
 	attoamm_sac_code varchar,
 	attoamm_sac_desc varchar
) as
$body$
DECLARE
_offset integer := (_page) * _limit;
BEGIN

	RETURN QUERY
    with attoamm as (
    select 
    e.attoal_id uid,
    e.attoal_causale,
    e.attoal_data_scadenza,
    m.attoal_stato_desc,
    e.attoal_versione_invio_firma,
    a.attoamm_numero,
    a.attoamm_anno,
    b.attoamm_tipo_code,
    b.attoamm_tipo_desc,
    d.attoamm_stato_desc,
    a.attoamm_id
    from siac_t_atto_amm a, siac_d_atto_amm_tipo b,siac_r_atto_amm_stato c,
    siac_d_atto_amm_stato d, siac_t_atto_allegato e,siac_r_atto_allegato_stato l,
    siac_d_atto_allegato_stato m
    where 
    b.attoamm_tipo_id=a.attoamm_tipo_id
    and c.attoamm_id=a.attoamm_id
    and d.attoamm_stato_id=c.attoamm_stato_id
    and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
    and a.attoamm_id=_uid_provvedimento
    and e.attoamm_id=a.attoamm_id
    and l.attoal_id=e.attoal_id
    and m.attoal_stato_id=l.attoal_stato_id
    and now() BETWEEN l.validita_inizio and COALESCE(l.validita_fine,now())
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
    and l.data_cancellazione is null
    and m.data_cancellazione is null)
    ,
    sac as 
    (select f.attoamm_id,g.classif_code,g.classif_desc
     from siac_r_atto_amm_class f, siac_t_class g,
    siac_d_class_tipo h 
    where 
    f.classif_id=g.classif_id
    and h.classif_tipo_id=g.classif_tipo_id
    and h.classif_tipo_code in ('CDR','CDC')
    and now() BETWEEN f.validita_inizio and COALESCE(f.validita_fine,now())
    and f.data_cancellazione is null
    and g.data_cancellazione is null
    and h.data_cancellazione is null
    )
    select 
    attoamm.uid,
    attoamm.attoal_causale,
    attoamm.attoal_data_scadenza,
    attoamm.attoal_stato_desc,
    attoamm.attoal_versione_invio_firma,
    attoamm.attoamm_numero,
    attoamm.attoamm_anno,
    attoamm.attoamm_tipo_code,
    attoamm.attoamm_tipo_desc,
    attoamm.attoamm_stato_desc,
    sac.classif_code attoamm_sac_code,
    sac.classif_desc attoamm_sac_desc 
    from attoamm left outer join sac
    on attoamm.attoamm_id=sac.attoamm_id
    order by    attoamm.attoamm_anno,  attoamm.attoamm_numero   
   	LIMIT _limit
	OFFSET _offset
    ;
END 
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
;
