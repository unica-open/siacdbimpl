/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer,p_tefa_trib_upload_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer,p_tefa_trib_upload_id integer)
RETURNS TEXT AS
$body$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
with 
raggruppa_sel as
(
select gruppo.tefa_trib_gruppo_anno, trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
),
tefa_sel as
(
select trib_imp.tefa_trib_tributo_code, trib_imp.tefa_trib_anno_rif_str
from siac_t_tefa_trib_importi trib_imp
where trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tipo_record='D'
and   trib_imp.data_cancellazione is null
and   trib_imp.validita_fine is null
)
select  distinct raggruppa_sel.tefa_trib_code 
from raggruppa_sel, tefa_sel 
where tefa_sel.tefa_trib_tributo_code=raggruppa_sel.tefa_trib_code
and   tefa_sel.tefa_trib_anno_rif_str=raggruppa_sel.tefa_trib_gruppo_anno
order by 1 DESC
/*select distinct trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo,
     siac_t_tefa_trib_importi trib_imp
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   trib_imp.ente_proprietario_id=gruppo.ente_proprietario_id
and   trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tributo_code=trib.tefa_trib_code
and   trib_imp.tefa_trib_tipo_record='D'
and   gruppo.tefa_trib_gruppo_anno=trib_imp.tefa_trib_anno_rif_str*/
/*     ( case when trib_imp.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
           when trib_imp.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
           when trib_imp.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )*/
/*and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  trib_imp.data_cancellazione is null
and  trib_imp.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
order by 1 DESC*/
)
loop
-- raise notice 'tefa_trib_code=%',rec_trib.tefa_trib_code;
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';
-- raise notice 'elenco_trib=%',elenco_trib;

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