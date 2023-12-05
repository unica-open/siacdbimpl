/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop view siac_v_dwh_bil_elem_comp_tipo;
                    -- 012345678901234567890123456789
CREATE OR REPLACE VIEW siac_v_dwh_bil_elem_comp_tipo
(

  ente_proprietario_id,
  ente_denominazione,
--012345678901234567890123456789
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
  elem_det_comp_tipo_anno       ,
  elem_det_comp_tipo_stato_code ,
  elem_det_comp_tipo_stato_desc ,
  validita_inizio,
  validita_fine
)
as
select
  ente.ente_proprietario_id,
  ente.ente_denominazione,
  tipo.elem_det_comp_tipo_code,
  tipo.elem_det_comp_tipo_desc,
  macro.elem_det_comp_macro_tipo_code,
  macro.elem_det_comp_macro_tipo_desc,
  sotto_tipo.elem_det_comp_sotto_tipo_code,
  sotto_tipo.elem_det_comp_sotto_tipo_desc,
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
  stato.elem_det_comp_tipo_stato_code,
  stato.elem_det_comp_tipo_stato_desc,
  tipo.validita_inizio,
  tipo.validita_fine
from siac_t_ente_proprietario ente,
     siac_d_bil_elem_det_comp_tipo_stato stato, siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)
where stato.ente_proprietario_id=ente.ente_proprietario_id
and   stato.elem_det_comp_tipo_stato_id=tipo.elem_det_comp_tipo_stato_id
and   macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null;