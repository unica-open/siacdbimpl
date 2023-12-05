/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_ente_proprietario (
    ente_proprietario_id,
    ente_denominazione)
AS
SELECT a.ente_proprietario_id, a.ente_denominazione
FROM siac_t_ente_proprietario a;