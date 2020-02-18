/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_gruppo_ruolo_op_account (
    ente_proprietario_id,
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
SELECT rgo.ente_proprietario_id, ga.gruppo_account_id, a.account_id,
    a.account_code, rgo.gruppo_ruolo_op_id, g.gruppo_id, g.gruppo_code,
    g.gruppo_desc, op.ruolo_op_id, op.ruolo_op_code, op.ruolo_op_desc
FROM siac_r_gruppo_ruolo_op rgo, siac_t_gruppo g, siac_d_ruolo_op op,
    siac_t_account a, siac_r_gruppo_account ga
WHERE rgo.gruppo_id = g.gruppo_id AND op.ruolo_op_id = rgo.ruolo_operativo_id
    AND ga.gruppo_id = g.gruppo_id AND a.account_id = ga.account_id;