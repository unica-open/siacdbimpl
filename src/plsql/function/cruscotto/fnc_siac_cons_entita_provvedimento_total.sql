/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_provvedimento_total (
  _ente_proprietario_id integer,
  _attoamm_anno varchar,
  _attoamm_numero integer,
  _uid_attoamm_tipo integer,
  _uid_sac integer
)
RETURNS bigint AS
$body$
DECLARE
    rec record;   
    sql_query varchar;
    total bigint;
BEGIN
total:=0;

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




for rec in
EXECUTE sql_query
loop

   total:=total+1;

end loop;


return total;
    
  /*  RETURN QUERY
	SELECT 1, 1, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest, stringaTest
	*/
    

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;