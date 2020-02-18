/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_account_ruolo_op (
    ente_proprietario_id,
    account_ruolo_op_id,
    account_id,
    account_code,
    ruolo_op_id,
    ruolo_op_code,
    ruolo_op_desc)
AS
SELECT rop.ente_proprietario_id, rop.account_ruolo_op_id, a.account_id,
    a.account_code, op.ruolo_op_id, op.ruolo_op_code, op.ruolo_op_desc
FROM siac_r_account_ruolo_op rop, siac_d_ruolo_op op, siac_t_account a
WHERE rop.account_id = a.account_id AND rop.ruolo_operativo_id = op.ruolo_op_id;