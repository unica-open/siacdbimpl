/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * FROM fnc_dba_add_column_params ('siac_r_cespiti_mov_ep_det', 'ces_contestuale' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_r_cespiti_mov_ep_det', 'pnota_alienazione_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_r_cespiti_mov_ep_det',
	'siac_t_prima_nota_siac_r_cespiti_mov_ep_det',
    'pnota_alienazione_id',
  	'siac_t_prima_nota',
    'pnota_id'
);