/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_bko_programma_cofog as 
with uno as (
select a.*,f.classif_tipo_code,
b.classif_id classif_id_cofog
 from siac_r_class c , siac_t_class a, siac_t_class b,  
siac_d_class_tipo f, siac_d_class_tipo g
where 
c.classif_a_id=a.classif_id
and
c.classif_b_id=b.classif_id
and f.classif_tipo_id=a.classif_tipo_id
and f.classif_tipo_code='PROGRAMMA'
--and a.ente_proprietario_id=1
and g.classif_tipo_id=b.classif_tipo_id
and g.classif_tipo_code like '%COFOG%'
)
select 
due.ente_proprietario_id,
due.classif_code codice_cofog,due.classif_desc desc_cofog, 
uno.classif_code codice_programma,uno.classif_desc desc_programma 
from siac_v_bko_cofog due left join uno 
on (due.classif_id=uno.classif_id_cofog and due.ente_proprietario_id=uno.ente_proprietario_id)