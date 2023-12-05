/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--	SIAC-6888
--	A seguito della segnalazione viene eseguito un controllo sui livelli gestione associati all'Ente.
--	Tale controllo, assicura che se un ente viene abilitato al
--  livello -> ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO
--	permette l'inserimento di accertamenti automatici, sia in caso di inserimento di una nuova quota documento che di aggiornamento.
--	A seguire le query utilizzate per abilitare/disabilitare un Ente.

-- STEP 1  - ABILITAZIONE

-- inserimento tipo
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_tipo


INSERT INTO siac_d_gestione_tipo
(gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac_t_ente_proprietario tep
CROSS JOIN
(VALUES ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'))
AS tmp (code, descr)
WHERE NOT EXISTS
(
    SELECT 1
    FROM siac_d_gestione_tipo dgt
    WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
    AND dgt.gestione_tipo_code = tmp.code
);



-- inserimento livello
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_livello


INSERT INTO siac_d_gestione_livello
(gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
JOIN
  (VALUES ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO')
  ) AS tmp(code, descr, tipo) ON (tmp.tipo = dgt.gestione_tipo_code)
WHERE
NOT EXISTS
(
    SELECT 1
    FROM siac_d_gestione_livello dgl
    WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
    AND   dgl.gestione_livello_code = tmp.code
    AND   dgl.gestione_tipo_id = dgt.gestione_tipo_id
);

-- inserimento siac_r_gestione_ente
insert into siac_r_gestione_ente
(
  gestione_livello_id,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select dgl.gestione_livello_id,
       'SIAC-6888',
       now(),
       dgl.ente_proprietario_id
from siac_t_ente_proprietario tep, siac_d_gestione_livello dgl, siac_d_gestione_tipo dgt
where dgt.ente_proprietario_id=tep.ente_proprietario_id
and   dgt.gestione_tipo_code='ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   dgl.gestione_tipo_id=dgt.gestione_tipo_id
and   dgl.gestione_livello_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   dgl.data_cancellazione  is null
and   dgt.data_cancellazione  is null
and   not exists
(
select 1
from siac_r_gestione_ente r
where r.gestione_livello_id=dgl.gestione_livello_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);

-- STEP 2 - DISABILITAZIONE

-- disabilitazione siac_r_gestione_ente
update siac_r_gestione_ente rge 
set validita_fine = now(), 
    data_cancellazione = now(), 
    login_operazione = rge.login_operazione||'-SIAC-6888'
from siac_t_ente_proprietario tep, siac_d_gestione_livello dgl, siac_d_gestione_tipo dgt
where dgt.ente_proprietario_id=tep.ente_proprietario_id
and   dgt.gestione_tipo_code='ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   dgl.gestione_tipo_id=dgt.gestione_tipo_id
and   dgl.gestione_livello_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   rge.gestione_livello_id = dgl.gestione_livello_id
and   rge.data_cancellazione  is null
and   rge.validita_fine is null
and   dgl.data_cancellazione  is null
and   dgt.data_cancellazione  is null;


-- QUERY INVALIDAZIONE RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_livello


update siac_d_gestione_livello dgt
set    validita_fine = now(),
       data_cancellazione = now(),
       login_operazione = dgt.login_Operazione||'-SIAC-6888'
from siac_t_ente_proprietario tep, siac_d_gestione_tipo dgl
where dgt.ente_proprietario_id=tep.ente_proprietario_id
and   dgt.gestione_livello_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   dgl.gestione_tipo_id=dgt.gestione_tipo_id
and   dgl.gestione_tipo_code='ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and   dgt.data_cancellazione is null
and   dgt.validita_fine is null;

-- QUERY INVALIDAZIONE RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_tipo

update siac_d_gestione_tipo dgt
set    validita_fine = now(),
       data_cancellazione = now(),
       login_operazione = dgt.login_operazione||'-SIAC-6888'
from siac_t_ente_proprietario tep
where  dgt.ente_proprietario_id=tep.ente_proprietario_id
and    dgt.gestione_tipo_code = 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO'
and    dgt.data_cancellazione is null
and    dgt.validita_fine is null;

