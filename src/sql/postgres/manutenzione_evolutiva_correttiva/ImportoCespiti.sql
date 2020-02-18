/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * FROM fnc_dba_add_column_params ('siac_r_cespiti_mov_ep_det', 'importo_su_prima_nota' , 'NUMERIC NOT NULL DEFAULT 0');
--importo_su_prima_nota ,