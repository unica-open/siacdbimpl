/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--siac-tasks Issue #186 - Maurizio - INIZIO
--Configurazione delle cartelle per i report di Previsione 2024.

--Enti locali
insert into siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilPrev-2024', 'Reportistica Bilancio di Previsione 2024 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'siac-tasks Issues #186'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilPrev-2024');  

-- Regione.
insert into siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilPrev-2024', 'Reportistica Bilancio di Previsione 2024 (Regione)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'siac-tasks Issues #186'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilPrev-2024');  
			
			
--INSERIMENTO DELLA CONFIGURAZIONE DEI RUOLI COPIANDOLI DALLE CARTELLE 2023.	
--Enti Locali.
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilPrev-2024'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'siac-tasks Issues #186'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilPrev-2023'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilPrev-2024');		

--Regione
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilPrev-2024'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'siac-tasks Issues #186'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilPrev-2023'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilPrev-2024');		

--siac-tasks Issue #186 - Maurizio - FINE

