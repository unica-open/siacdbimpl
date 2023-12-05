/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_gruppo_ruolo_op_account_azione (
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
    gruppo_account_id,
    account_id,
    account_code,
    gruppo_ruolo_op_id,
    gruppo_id,
    gruppo_code,
    gruppo_desc,
    ruolo_op_id,
    ruolo_op_code,
    ruolo_op_desc)
AS
SELECT rgo.ente_proprietario_id, az.azione_id, az.azione_code, az.azione_desc,
    azt.azione_tipo_id, azt.azione_tipo_code, azt.azione_tipo_desc,
    gaz.gruppo_azioni_id, gaz.gruppo_azioni_code, gaz.gruppo_azioni_desc,
    ga.gruppo_account_id, a.account_id, a.account_code, rgo.gruppo_ruolo_op_id,
    g.gruppo_id, g.gruppo_code, g.gruppo_desc, op.ruolo_op_id, op.ruolo_op_code,
    op.ruolo_op_desc
FROM siac_r_gruppo_ruolo_op rgo, siac_t_gruppo g, siac_d_ruolo_op op,
    siac_t_account a, siac_r_gruppo_account ga, siac_r_ruolo_op_azione raz,
    siac_t_azione az, siac_d_gruppo_azioni gaz, siac_d_azione_tipo azt
WHERE rgo.gruppo_id = g.gruppo_id AND op.ruolo_op_id = rgo.ruolo_operativo_id
    AND ga.gruppo_id = g.gruppo_id AND a.account_id = ga.account_id AND raz.ruolo_op_id = op.ruolo_op_id AND raz.azione_id = az.azione_id AND gaz.gruppo_azioni_id = az.gruppo_azioni_id AND azt.azione_tipo_id = az.azione_tipo_id;