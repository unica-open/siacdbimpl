/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_iva_aliquota', 'codice', 'varchar(4)');

COMMENT ON COLUMN siac.siac_t_iva_aliquota.codice IS 'Codice Natura';

SELECT * FROM  fnc_dba_add_fk_constraint('siac_t_iva_aliquota', 'siac_t_iva_aliquota_sirfel_d_natura', 'codice,ente_proprietario_id', 'sirfel_d_natura', 'codice,ente_proprietario_id');