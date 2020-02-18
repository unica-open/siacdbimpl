/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
       -- 012345678901234567890123456789
drop view siac_v_dwh_bil_elem_comp_cap;

CREATE OR REPLACE VIEW siac_v_dwh_bil_elem_comp_cap
(
	   ente_proprietario_id,
       ente_denominazione,
     --012345678901234567890123456789
	   elem_anno_bilancio            ,
	   elem_tipo_code_capitolo       ,
       elem_tipo_desc_capitolo       ,
	   elem_code_capitolo            ,
       elem_code_articolo            ,
       elem_code_ueb                 ,
       elem_stato_code_capitolo      ,
       elem_stato_desc_capitolo      ,
       elem_det_anno                 ,
       elem_det_importo              ,
       elem_det_comp_importo         ,
	   elem_det_comp_tipo_code       ,
	   elem_det_comp_tipo_desc       ,
       elem_det_comp_macro_tipo_code ,
 	   elem_det_comp_macro_tipo_desc ,
	   elem_det_comp_sotto_tipo_code ,
	   elem_det_comp_sotto_tipo_desc ,
	   elem_det_comp_tipo_ambito_code,
	   elem_det_comp_tipo_ambito_desc,
	   elem_det_comp_tipo_fonte_code ,
	   elem_det_comp_tipo_fonte_desc ,
	   elem_det_comp_tipo_fase_code  ,
	   elem_det_comp_tipo_fase_desc  ,
	   elem_det_comp_tipo_def_code   ,
	   elem_det_comp_tipo_def_desc   ,
	   elem_det_comp_tipo_gest_aut   ,
	   elem_det_comp_tipo_anno
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione,
       query.elem_anno_bilancio,
	   query.elem_tipo_code_capitolo,
       query.elem_tipo_desc_capitolo,
	   query.elem_code_capitolo,
       query.elem_code_articolo,
       query.elem_code_ueb,
       query.elem_stato_code_capitolo,
       query.elem_stato_desc_capitolo,
       query.elem_det_anno,
       query.elem_det_importo,
       query.elem_det_comp_importo,
	   query.elem_det_comp_tipo_code,
	   query.elem_det_comp_tipo_desc,
	   query.elem_det_comp_macro_tipo_code,
 	   query.elem_det_comp_macro_tipo_desc,
	   query.elem_det_comp_sotto_tipo_code,
	   query.elem_det_comp_sotto_tipo_desc,
	   query.elem_det_comp_tipo_ambito_code,
	   query.elem_det_comp_tipo_ambito_desc,
	   query.elem_det_comp_tipo_fonte_code,
	   query.elem_det_comp_tipo_fonte_desc,
	   query.elem_det_comp_tipo_fase_code,
	   query.elem_det_comp_tipo_fase_desc,
	   query.elem_det_comp_tipo_def_code,
	   query.elem_det_comp_tipo_def_desc,
	   query.elem_det_comp_tipo_gest_aut,
	   query.elem_det_comp_tipo_anno
from
(
with
comp_tipo as
(
select
  macro.elem_det_comp_macro_tipo_code,
  macro.elem_det_comp_macro_tipo_desc,
  sotto_tipo.elem_det_comp_sotto_tipo_code,
  sotto_tipo.elem_det_comp_sotto_tipo_desc,
  tipo.elem_det_comp_tipo_code,
  tipo.elem_det_comp_tipo_desc,
  ambito_tipo.elem_det_comp_tipo_ambito_code,
  ambito_tipo.elem_det_comp_tipo_ambito_desc,
  fonte_tipo.elem_det_comp_tipo_fonte_code,
  fonte_tipo.elem_det_comp_tipo_fonte_desc,
  fase_tipo.elem_det_comp_tipo_fase_code,
  fase_tipo.elem_det_comp_tipo_fase_desc,
  def_tipo.elem_det_comp_tipo_def_code,
  def_tipo.elem_det_comp_tipo_def_desc,
  (case when tipo.elem_det_comp_tipo_gest_aut=true then 'Solo automatica'
        else 'Manuale' end)::varchar(50) elem_det_comp_tipo_gest_aut,
  per.anno::integer elem_det_comp_tipo_anno,
  tipo.elem_det_comp_tipo_id,
  per.periodo_id elem_det_comp_periodo_id
from siac_d_bil_elem_det_comp_tipo_stato stato, siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)
where stato.elem_det_comp_tipo_stato_id=tipo.elem_det_comp_tipo_stato_id
and   macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
),
capitolo as
(
select e.elem_code, e.elem_code2, e.elem_code3,
       tipo.elem_tipo_code, tipo.elem_tipo_desc,
       stato.elem_stato_code, stato.elem_stato_desc,
       per.anno elem_anno_bilancio,
       per_det.anno elem_det_anno,
       det.elem_det_importo,
       e.elem_id,
       det.elem_det_id,
       det.elem_det_tipo_id,
       bil.bil_id,
       per.periodo_id,
       per_det.periodo_id periodo_det_id,
       e.ente_proprietario_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
     siac_t_periodo per_det
where tipo.elem_tipo_code in ('CAP-UG','CAP-UP')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   tipo_det.elem_det_tipo_code='STA'
and   per_det.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
),
capitolo_det_comp as
(
select comp.*
from siac_t_bil_elem_det_comp comp
where comp.data_cancellazione is null
)
select capitolo.elem_code  elem_code_capitolo,
       capitolo.elem_code2 elem_code_articolo,
       capitolo.elem_code3 elem_code_ueb,
       capitolo.elem_tipo_code  elem_tipo_code_capitolo,
       capitolo.elem_tipo_desc  elem_tipo_desc_capitolo,
       capitolo.elem_stato_code elem_stato_code_capitolo,
       capitolo.elem_stato_desc elem_stato_desc_capitolo,
       capitolo.elem_anno_bilancio,
       capitolo.elem_det_anno,
       capitolo.elem_det_importo,
       capitolo.elem_id,
       capitolo.elem_det_id,
       capitolo.elem_det_tipo_id,
       capitolo.bil_id,
       capitolo.periodo_id,
       capitolo.periodo_det_id,
       capitolo.ente_proprietario_id,
       capitolo_det_comp.elem_det_importo elem_det_comp_importo,
       comp_tipo.elem_det_comp_macro_tipo_code,
 	   comp_tipo.elem_det_comp_macro_tipo_desc,
	   comp_tipo.elem_det_comp_sotto_tipo_code,
	   comp_tipo.elem_det_comp_sotto_tipo_desc,
	   comp_tipo.elem_det_comp_tipo_code,
	   comp_tipo.elem_det_comp_tipo_desc,
	   comp_tipo.elem_det_comp_tipo_ambito_code,
	   comp_tipo.elem_det_comp_tipo_ambito_desc,
	   comp_tipo.elem_det_comp_tipo_fonte_code,
	   comp_tipo.elem_det_comp_tipo_fonte_desc,
	   comp_tipo.elem_det_comp_tipo_fase_code,
	   comp_tipo.elem_det_comp_tipo_fase_desc,
	   comp_tipo.elem_det_comp_tipo_def_code,
	   comp_tipo.elem_det_comp_tipo_def_desc,
	   comp_tipo.elem_det_comp_tipo_gest_aut,
	   comp_tipo.elem_det_comp_tipo_anno,
       comp_tipo.elem_det_comp_periodo_id
from capitolo, capitolo_det_comp,comp_tipo
where capitolo.elem_det_id=capitolo_det_comp.elem_det_id
and   comp_tipo.elem_det_comp_tipo_id=capitolo_det_comp.elem_det_comp_tipo_id
) query, siac_t_ente_proprietario ente
where query.ente_proprietario_id=ente.ente_proprietario_id;