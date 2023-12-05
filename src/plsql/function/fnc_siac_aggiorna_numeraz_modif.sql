/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

create or replace function fnc_siac_aggiorna_numeraz_modif()
returns integer
as
$body$
DECLARE

 annoImpegno integer:=-1;
 numeroImpegno integer:=-1;
 numeroSubimpegno integer:=-1;
 numeroModifica integer:=-1;
 numeroModificaNew integer:=-1;

 mod_rec  record;
BEGIN

for mod_rec in
(select inc.*
 from INC000001771118_rinumeraz_modif inc
 order by 1,2,3,4,5
)
loop

	if annoImpegno!=mod_rec.anno_impegno or
       numeroImpegno!=mod_rec.numero_impegno or
       numeroSubimpegno!=mod_rec.numero_subimpegno then
--       numeroModifica!=mod_rec.numero_modifica then

       numeroModificaNew:=1;

       annoImpegno:=mod_rec.anno_impegno;
	   numeroImpegno:=mod_rec.numero_impegno;
       numeroSubimpegno:=mod_rec.numero_subimpegno;
	   numeroModifica:=mod_rec.numero_modifica;
    else
       numeroModificaNew:=numeroModificaNew+1;
    end if;


    update INC000001771118_rinumeraz_modif incUPD
    set    numero_modifica_new=numeroModificaNew
    where incUPD.rinumera_modif_id=mod_rec.rinumera_modif_id;


end loop;

return 1;

exception
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        return 0;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;