/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/




drop view if exists siac.siac_v_dwh_mutuo_ripartizione;
create or replace view siac.siac_v_dwh_mutuo_ripartizione
(
    ente_proprietario_id,
    mutuo_numero,
	mutuo_ripartizione_tipo_code,
	mutuo_ripartizione_tipo_desc,
	anno_bilancio,
	mutuo_bil_elem_tipo,
	mutuo_bil_elem_code_capitolo,
	mutuo_bil_elem_code_articolo,
	mutuo_ripartizione_importo,
	mutuo_ripartizione_perc
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
    tipo.mutuo_ripartizione_tipo_code,
    tipo.mutuo_ripartizione_tipo_desc,
    per.anno::integer anno_bilancio,
    tipo_cap.elem_tipo_code mutuo_bil_elem_tipo,
    cap.elem_code mutuo_bil_elem_code_capitolo,
    cap.elem_code2 mutuo_bil_elem_code_articolo,
    r.mutuo_ripartizione_importo,
    r.mutuo_ripartizione_perc
FROM siac_t_mutuo mutuo ,siac_r_mutuo_ripartizione r,siac_d_mutuo_ripartizione_tipo tipo ,siac_t_bil_elem cap, siac_d_bil_elem_tipo tipo_cap, siac_t_bil bil,siac_t_periodo per
where mutuo.mutuo_id=r.mutuo_id 
AND    tipo.mutuo_ripartizione_tipo_id=r.mutuo_ripartizione_tipo_id 
AND    cap.elem_id=r.elem_id 
AND    tipo_cap.elem_tipo_id=cap.elem_tipo_id 
AND    bil.bil_id=cap.bil_id 
AND    per.periodo_id=bil.periodo_id
and     mutuo.data_cancellazione  is NULL
and     r.data_cancellazione  is NULL
and     cap.data_cancellazione  is NULL
);

alter view siac.siac_v_dwh_mutuo_ripartizione owner to siac;