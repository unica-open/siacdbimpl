/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer)
RETURNS TEXT AS
$body$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
WITH
gruppi as
(
select trib.tefa_trib_code,gruppo.tefa_trib_gruppo_anno
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   r_tefa.data_cancellazione is null
and   r_tefa.validita_fine is null
and   trib.data_cancellazione is null
and   trib.validita_fine is null
and   gruppo.data_cancellazione is null
and   gruppo.validita_fine is null
order by 1 desc
)
select gruppi.tefa_trib_code,gruppi.tefa_trib_gruppo_anno
from gruppi
order by 1 desc
)
loop
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';

end loop;

if elenco_trib is not null then
 elenco_trib:=trim(both from substring(elenco_trib,1,length(elenco_trib)-1));
end if;

return elenco_trib;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return elenco_trib;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;