/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 11/10/2019	Alessandro T.	inizio	SIAC-6888 
-- A seguito della segnalazione viene esguito un controllo sui livelli gestione associati all'Ente.
-- Tale controllo, gestito dal GenericBilancioModel, assicura che se un ente viene abilitato al livello -> ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO
-- ne permetterà l'inserimento accertamenti automatici, sia in caso di inserimento di una nuova quota che di aggiornamento.
-- A seguire le query utilizzate per abilitare/disabilitare un Ente. 

-- STEP 1 inserimento tipo
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_tipo


INSERT INTO siac.siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac.siac_t_ente_proprietario tep
CROSS JOIN (VALUES
    ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO')
) AS tmp (code, descr)
WHERE NOT EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_tipo dgt
    WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
    AND dgt.gestione_tipo_code = tmp.code
);


-- STEP 2 inserimento livello
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_livello


INSERT INTO siac.siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac.siac_t_ente_proprietario tep
JOIN siac.siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
JOIN (VALUES
    ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO')
) AS tmp(code, descr, tipo) ON (tmp.tipo = dgt.gestione_tipo_code)
WHERE NOT EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_livello dgl
    WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
    AND dgl.gestione_tipo_code = tmp.code
    AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
);


-- QUERY INVALIDAZIONE RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_tipo


update siac.siac_d_gestione_tipo dgt set validita_fine = now(), data_cancellazione = now(), login_operazione = 'SIAC-6888'
from siac.siac_t_ente_proprietario tep, siac.siac_d_gestione_livello dgl
where dgt.gestione_tipo_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
AND EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_tipo dgt
    WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
    AND dgt.gestione_tipo_code = dgl.gestione_livello_code
);


-- QUERY INVALIDAZIONE RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_livello


update siac.siac_d_gestione_livello dgt set validita_fine = now(), data_cancellazione = now(), login_operazione = 'SIAC-6888'
from siac.siac_t_ente_proprietario tep, siac.siac_d_gestione_livello dgl
where dgt.gestione_livello_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
AND EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_livello dgt
    WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
    AND dgt.gestione_livello_code = dgl.gestione_livello_code
);

-- 11/10/2019	Alessandro T.	fine	SIAC-6888 