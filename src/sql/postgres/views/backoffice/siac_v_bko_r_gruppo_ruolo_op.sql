/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_r_gruppo_ruolo_op (
    ente_proprietario_id,
    gruppo_ruolo_op_id,
    gruppo_id,
    gruppo_code,
    gruppo_desc,
    ruolo_op_id,
    ruolo_op_code,
    ruolo_op_desc)
AS
SELECT rgo.ente_proprietario_id, rgo.gruppo_ruolo_op_id, g.gruppo_id,
    g.gruppo_code, g.gruppo_desc, op.ruolo_op_id, op.ruolo_op_code,
    op.ruolo_op_desc
FROM siac_r_gruppo_ruolo_op rgo, siac_t_gruppo g, siac_d_ruolo_op op
WHERE rgo.gruppo_id = g.gruppo_id AND op.ruolo_op_id = rgo.ruolo_operativo_id;