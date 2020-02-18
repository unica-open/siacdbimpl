/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * FROM fnc_dba_add_column_params ('siac_t_iva_registro', 'ivareg_flagliquidazioneiva' , 'BOOLEAN DEFAULT true NOT NULL');