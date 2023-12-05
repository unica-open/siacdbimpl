/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac_for.calcolo_impegnato (
  ente_prop_id integer
)
RETURNS TABLE (
  elem_det_id integer,
  elem_id integer,
  elem_det_importo numeric,
  elem_det_flag varchar,
  elem_det_tipo_id integer,
  periodo_id integer,
  validita_inizio timestamp,
  validita_fine timestamp,
  ente_proprietario_id integer,
  data_creazione timestamp,
  data_modifica timestamp,
  data_cancellazione timestamp,
  login_operazione varchar,
  disponibilitapagare numeric,
  disponibilitavariare numeric,
  fondopluriennalevincprec numeric,
  impegnatopluranno_3 numeric,
  stanziamentoannoprec numeric,
  stanziamentocassaannoprec numeric,
  stanziamentoresannoprec numeric,
  disponibilitafondopluriennalevinc numeric,
  disponibilitaimpegnare numeric,
  dicuiimpegnato numeric,
  dicuiimpegnatoannoprec numeric,
  dicuiaccertato numeric,
  dicuiaccertatoannoprec numeric,
  stanziamentoannoprecdef numeric,
  disponibilitaaccertare numeric
) AS
$body$
DECLARE
rec record;
--  intsommato integer;
BEGIN
for rec in 
SELECT 
t1.elem_det_id,
  t1.elem_id,
  t1.elem_det_importo,
  t1.elem_det_flag,
  t1.elem_det_tipo_id,
  t1.periodo_id,
  t1.validita_inizio,
t1.validita_fine,
  t1.ente_proprietario_id,
  t1.data_creazione,
  t1.data_modifica,
  t1.data_cancellazione,
  t1.login_operazione  
FROM siac_t_bil_elem_det t1
    WHERE  t1.ente_proprietario_id=ente_prop_id
loop

  elem_det_id:=rec.elem_det_id;
  elem_id:=rec.elem_id;
  elem_det_importo:=rec.elem_det_importo;
  elem_det_flag:=rec.elem_det_flag;
  elem_det_tipo_id:=rec.elem_det_tipo_id;
  periodo_id:=rec.periodo_id;
  
   validita_inizio:=rec.validita_inizio;
  validita_fine:=rec.validita_fine;
  ente_proprietario_id:=rec.ente_proprietario_id;
  data_creazione:=rec.data_creazione;
  data_modifica:=rec.data_modifica;
  data_cancellazione:=rec.data_cancellazione;
  login_operazione:=rec.login_operazione;
  
   disponibilitapagare:=0;
  disponibilitavariare:=0;
  fondopluriennalevincprec:=0;
  impegnatopluranno_3:=0;
  stanziamentoannoprec:=0;
  stanziamentocassaannoprec:=0;
  stanziamentoresannoprec:=0;
  --capitolo UG
  disponibilitafondopluriennalevinc:=0;
  disponibilitaimpegnare:=0;
  --capitolo UP 
  dicuiimpegnato:=0;
  dicuiimpegnatoannoprec:=0;
  --capitolo EP
  dicuiaccertato:=0;
  dicuiaccertatoannoprec:=0;
  --capitolo EP  UP 
  stanziamentoannoprecdef:=0;
  --capitolo EG
  disponibilitaaccertare:=0;
  
  --elem_det_flag:='@'||elem_det_flag;
  
  RETURN NEXT;
end loop;
exception
when no_data_found THEN
raise notice 'nessun dato trovato';
return;
--when others  THEN
--raise notice 'altro errore';
--return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;