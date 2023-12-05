/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop view if exists siac.siac_v_dwh_bil_elem_prev_iacc;

CREATE OR REPLACE VIEW siac.siac_v_dwh_bil_elem_prev_iacc 
(
    ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    elem_tipo_code_capitolo,
    elem_tipo_desc_capitolo,
    elem_code_capitolo,
    elem_code_articolo,
    elem_code_ueb,
    elem_importo_prev_anno1,
	elem_importo_prev_anno2,
	elem_importo_prev_anno3,
	elem_importo_prev_note
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione, 
       per.anno::varchar(4) bil_anno,
       tipo.elem_tipo_code elem_tipo_code_capitolo,
       tipo.elem_tipo_desc elem_tipo_desc_capitolo,
       e.elem_code elem_code_capitolo,
       e.elem_code2 elem_code_articolo,
       e.elem_code3 elem_code_ueb,
       r.importo_prev_anno1 elem_importo_prev_anno1,
       r.importo_prev_anno2 elem_importo_prev_anno2,
       r.importo_prev_anno3 elem_importo_prev_anno3,
       r.importo_prev_note
from siac_r_bil_elem_previsione_impacc r,
     siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_ente_proprietario ente
where  e.ente_proprietario_id=ente.ente_proprietario_id 
and    e.elem_id=r.elem_id
and    tipo.elem_tipo_id=e.elem_tipo_id
and    bil.bil_id=e.bil_id
and    per.periodo_id=bil.periodo_id
and    r.data_cancellazione is null 
and    r.validita_fine is null 
and    e.data_cancellazione is null;


alter view siac.siac_v_dwh_bil_elem_prev_iacc OWNER to siac;