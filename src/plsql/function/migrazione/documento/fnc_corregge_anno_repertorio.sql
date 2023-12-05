/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION corregge_anno_repertorio (
)
RETURNS integer AS
$body$
DECLARE
    migrEntiID record;
BEGIN
    for migrEntiID IN
    (select ente.ente_proprietario_id
     from siac_t_ente_proprietario ente
     order by ente.ente_proprietario_id
     )
    loop

     update siac_r_doc_attr k
       set numerico=testo::numeric,
           testo=DEFAULT,
		   data_modifica=now(),
		   login_operazione='migr_documento'
     where k.ente_proprietario_id=migrEntiID.ente_proprietario_id
       and k.attr_id in (select attr.attr_id
                           from siac_t_attr attr
                          where attr.ente_proprietario_id=migrEntiID.ente_proprietario_id
                            and attr.attr_code='anno_repertorio'
                            and attr.data_cancellazione is null
	                        and date_trunc('day',now())>=date_trunc('day',attr.validita_inizio)
    	                    and (date_trunc('day',now())<date_trunc('day',attr.validita_fine) or attr.validita_fine is null))
       and k.testo is not null;

    end loop;
	
     RAISE NOTICE 'attributo anno repertorio corretto';
	 return 0;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
