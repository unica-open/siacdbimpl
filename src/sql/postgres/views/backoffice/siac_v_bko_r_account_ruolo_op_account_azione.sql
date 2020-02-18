/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_account_ruolo_op_account_azione (
    ente_proprietario_id,
    azione_id,
    azione_code,
    azione_desc,
    azione_tipo_id,
    azione_tipo_code,
    azione_tipo_desc,
    gruppo_azioni_id,
    gruppo_azioni_code,
    gruppo_azioni_desc,
    account_ruolo_op_id,
    account_id,
    account_code,
    ruolo_op_id,
    ruolo_op_code,
    ruolo_op_desc)
AS
SELECT rop.ente_proprietario_id, az.azione_id, az.azione_code, az.azione_desc,
    azt.azione_tipo_id, azt.azione_tipo_code, azt.azione_tipo_desc,
    gaz.gruppo_azioni_id, gaz.gruppo_azioni_code, gaz.gruppo_azioni_desc,
    rop.account_ruolo_op_id, a.account_id, a.account_code, op.ruolo_op_id,
    op.ruolo_op_code, op.ruolo_op_desc
FROM siac_r_account_ruolo_op rop, siac_d_ruolo_op op, siac_t_account a,
    siac_r_ruolo_op_azione raz, siac_t_azione az, siac_d_gruppo_azioni gaz,
    siac_d_azione_tipo azt
WHERE rop.account_id = a.account_id AND rop.ruolo_operativo_id = op.ruolo_op_id
    AND raz.ruolo_op_id = op.ruolo_op_id AND raz.azione_id = az.azione_id AND gaz.gruppo_azioni_id = az.gruppo_azioni_id AND azt.azione_tipo_id = az.azione_tipo_id;