/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac_for.capitolo_mis_prog_par (
  ente_prop_id integer,
  anno_bil varchar,
  id_capitolo integer
)
RETURNS TABLE (
  elem_id integer,
  elem_code varchar,
  elem_desc varchar,
  elem_code2 varchar,
  elem_desc2 varchar,
  tipoclass varchar,
  classif_code varchar,
  classif_desc varchar
) AS
$body$
DECLARE
rec record;
  intsommato integer;
BEGIN
for rec in 
select 
be.elem_id,
be.elem_code,
be.elem_desc,
be.elem_code2,
be.elem_desc2,
'MISSIONE' tipoclass,
cl.classif_code,
cl.classif_desc
from siac_d_class_tipo ct,siac_t_class cl,siac_r_bil_elem_class rbc, siac_t_bil_elem be, siac_t_bil bi, 
siac_t_periodo pe
where ct.classif_tipo_code='MISSIONE'
and bi.bil_id=be.bil_id
and pe.periodo_id=bi.periodo_id
and pe.anno=anno_bil
and cl.classif_tipo_id=ct.classif_tipo_id and rbc.classif_id=cl.classif_id
and be.elem_id=rbc.elem_id
and be.livello=1
AND date_trunc('day',CURRENT_TIMESTAMP) > ct.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < ct.validita_fine) or (ct.validita_fine is null)) 
AND date_trunc('day',CURRENT_TIMESTAMP) > cl.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < cl.validita_fine) or (cl.validita_fine is null)) 
AND date_trunc('day',CURRENT_TIMESTAMP) > rbc.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < rbc.validita_fine) or (rbc.validita_fine is null))
AND date_trunc('day',CURRENT_TIMESTAMP) > be.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < be.validita_fine) or (be.validita_fine is null))
and be.ente_proprietario_id=ente_prop_id
and be.elem_id=id_capitolo
union
select 
be.elem_id,
be.elem_code,
be.elem_desc,
be.elem_code2,
be.elem_desc2,
'PROGRAMMA' tipoclass,
cl.classif_code,
cl.classif_desc
from siac_d_class_tipo ct,siac_t_class cl,siac_r_bil_elem_class rbc, siac_t_bil_elem be, siac_t_bil bi, 
siac_t_periodo pe
where ct.classif_tipo_code='PROGRAMMA'
and bi.bil_id=be.bil_id
and pe.periodo_id=bi.periodo_id
and pe.anno=anno_bil
and cl.classif_tipo_id=ct.classif_tipo_id and rbc.classif_id=cl.classif_id
and be.elem_id=rbc.elem_id
and be.livello=1
AND date_trunc('day',CURRENT_TIMESTAMP) > ct.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < ct.validita_fine) or (ct.validita_fine is null)) 
AND date_trunc('day',CURRENT_TIMESTAMP) > cl.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < cl.validita_fine) or (cl.validita_fine is null)) 
AND date_trunc('day',CURRENT_TIMESTAMP) > rbc.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < rbc.validita_fine) or (rbc.validita_fine is null))
AND date_trunc('day',CURRENT_TIMESTAMP) > be.validita_inizio
and ((date_trunc('day',CURRENT_TIMESTAMP) < be.validita_fine) or (be.validita_fine is null))
and be.ente_proprietario_id=ente_prop_id
and be.elem_id=id_capitolo
loop
elem_id:=rec.elem_id;
elem_code:=rec.elem_code;
elem_desc:=rec.elem_desc;
elem_code2:=rec.elem_code2;
elem_desc2:=rec.elem_desc2;
tipoclass:=rec.tipoclass;
classif_code:=rec.classif_code;
classif_desc:=rec.classif_desc;

  RETURN NEXT;
end loop;
exception
when no_data_found THEN
raise notice 'nessun dato trovato';
return;
when others  THEN
raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;