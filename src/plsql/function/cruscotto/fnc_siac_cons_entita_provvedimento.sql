/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_provvedimento (
  _ente_proprietario_id integer,
  _attoamm_anno varchar,
  _attoamm_numero integer,
  _uid_attoamm_tipo integer,
  _uid_sac integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_oggetto varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	stringaTest character varying := 'Test';
    rec record;   
    sql_query varchar;
BEGIN

/*raise notice ' _ente_proprietario_id=%', _ente_proprietario_id;
raise notice ' _attoamm_anno=%',  _attoamm_anno;
raise notice ' _attoamm_numero=%',  _attoamm_numero;
raise notice ' _uid_attoamm_tipo=%',  _uid_attoamm_tipo;
raise notice ' _uid_sac=%',  _uid_sac;
raise notice ' _limit=%',  _limit;
raise notice ' _page=%',  _page;*/


/*sql_query:='select a.attoamm_id,a.attoamm_numero,a.attoamm_anno,a.attoamm_oggetto,  
b.attoamm_tipo_code,b.attoamm_tipo_desc, d.attoamm_stato_desc
,f.classif_code attoamm_sac_code,f.classif_desc attoamm_sac_desc
from siac_t_atto_amm a, siac_d_atto_amm_tipo b, 
siac_r_atto_amm_stato c,
siac_d_atto_amm_stato d ,
 siac_r_atto_amm_class e, siac_t_class f,siac_d_class_tipo g
where b.attoamm_tipo_id=a.attoamm_tipo_id
and c.attoamm_id=a.attoamm_id
and d.attoamm_stato_id=c.attoamm_stato_id
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and a.ente_proprietario_id='|| _ente_proprietario_id||'  and a.attoamm_anno='''||_attoamm_anno||''''
   ;*/
   
   
sql_query:='with aa AS
 (select a.attoamm_id,a.attoamm_numero,a.attoamm_anno,a.attoamm_oggetto,  
b.attoamm_tipo_code,b.attoamm_tipo_desc, d.attoamm_stato_desc
from siac_t_atto_amm a, siac_d_atto_amm_tipo b, 
siac_r_atto_amm_stato c,
siac_d_atto_amm_stato d 
where b.attoamm_tipo_id=a.attoamm_tipo_id
and c.attoamm_id=a.attoamm_id
and d.attoamm_stato_id=c.attoamm_stato_id
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and a.ente_proprietario_id='|| _ente_proprietario_id||'  and a.attoamm_anno='''||_attoamm_anno||'''';  

   
if    _attoamm_numero is not null THEN
sql_query:=sql_query||' and a.attoamm_numero='||_attoamm_numero;
end if;

if    _uid_attoamm_tipo is not null THEN
sql_query:=sql_query||' and b.attoamm_tipo_id='||_uid_attoamm_tipo;
end if;


sql_query:=sql_query||
') ,
bb as (select 
e.attoamm_id,
f.classif_code attoamm_sac_code,
  f.classif_desc attoamm_sac_desc from
siac_r_atto_amm_class e, siac_t_class f,siac_d_class_tipo g
where
e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and f.classif_id=e.classif_id
and g.classif_tipo_id=f.classif_tipo_id
and g.classif_tipo_code in (''CDR'',''CDC'')
and now() BETWEEN e.validita_inizio and COALESCE(e.validita_fine,now())'
;

if _uid_sac is not null then
sql_query:=sql_query||' and f.classif_id ='||_uid_sac;
end if;


sql_query:=sql_query||' ) select aa.*,bb.* from aa ';

if _uid_sac is null then
sql_query:=sql_query||' left outer ';
end if;


sql_query:=sql_query||' join bb on aa.attoamm_id=bb.attoamm_id order by 3,2 ';


if    _limit is not null THEN
sql_query:=sql_query||' LIMIT '||_limit;
end if;

if    _offset is not null THEN
sql_query:=sql_query||' OFFSET '||_offset;
end if;


raise notice '%',sql_query;

for rec in
EXECUTE sql_query
loop

uid:=rec.attoamm_id;
attoamm_numero:=rec.attoamm_numero;
attoamm_anno:=rec.attoamm_anno;
attoamm_oggetto:=rec.attoamm_oggetto;
attoamm_tipo_code:=rec.attoamm_tipo_code;
attoamm_tipo_desc:=rec.attoamm_tipo_desc;
attoamm_stato_desc:=rec.attoamm_stato_desc;
attoamm_sac_code:=rec.attoamm_sac_code;
attoamm_sac_desc:=rec.attoamm_sac_desc;
    
    return next;
    end loop;
    return;
    
  /*  RETURN QUERY
	SELECT 1, 1, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest
	*/
    

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;