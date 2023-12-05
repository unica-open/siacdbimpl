/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--inserimento azioni
/****** OP-SPE-gestImprROR *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-SPE-gestImprROR','Ricerca Impegni ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-SPE-gestImprROR'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-SPE-gestImprROR'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;

/****** OP-SPE-gestImpRORdecentrato *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-SPE-gestImpRORdecentrato','Ricerca Impegno ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-SPE-gestImpRORdecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

 update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-SPE-gestImpRORdecentrato'
  and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;


/****** OP-ENT-gestAccROR *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-ENT-gestAccROR','Ricerca Accertamento ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-gestAccROR'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
 
 update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-ENT-gestAccROR'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;



/****** OP-ENT-gestAccRORdecentrato *******/
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-ENT-gestAccRORdecentrato','Ricerca Accertamento ROR',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacfinapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'AZIONE_SECONDARIA'
AND b.gruppo_azioni_code = 'FIN_BASE1'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-gestAccRORdecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
 

update siac_t_azione az set azione_tipo_id = tipoazione.azione_tipo_id from 
(select b.azione_tipo_id, b.ente_proprietario_id as ente from siac_d_azione_tipo b  where azione_tipo_code = 'AZIONE_SECONDARIA'
 ) as tipoazione
 where az.azione_code ='OP-ENT-gestAccRORdecentrato'
 and az.ente_proprietario_id= tipoazione.ente
 and tipoazione.azione_tipo_id <> az.azione_tipo_id
 ;