/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select * from fnc_dba_add_column_params ( 'siac_r_movgest_bil_elem', 'elem_det_comp_tipo_id', 'INTEGER');
select * from fnc_dba_add_fk_constraint('siac_r_movgest_bil_elem', 'siac_t_bil_elem_det_comp_tipo_siac_r_movgest_bil_elem', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
	