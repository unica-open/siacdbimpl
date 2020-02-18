/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- file comprendente tutto quanto rilasciato nei vari rilasci nel fiole cespiti-beta precedentemente per il rilascio in produzione

--- gruppo azioni INV-INVENTARIO INIZIO

INSERT INTO
  siac.siac_d_gruppo_azioni
(
  gruppo_azioni_code,
  gruppo_azioni_desc,
  titolo, 
  validita_inizio,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  login_operazione
)
select 'INV',
'Inventario',
'12 - Inventario',
now(),
a.ente_proprietario_id,
now(),
now(),
'admin'
from siac_t_ente_proprietario a
where
not exists (select 1 
from siac_d_gruppo_azioni z 
where z.gruppo_azioni_code='INV'
and z.ente_proprietario_id=a.ente_proprietario_id
and z.data_cancellazione is null);

--- gruppo azioni INV-INVENTARIO FINE

-- AZIONI INIZIO
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.urlapplicazione , FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	--CATEGORIA
	('OP-INV-insCategCespiti', 'Inserisci Categoria Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciCategCespiti', 'Gestisci Categoria Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricCategCespiti', 'Ricerca Categoria Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--TIPO BENE
	('OP-INV-insTipoBene', 'Inserisci Tipo Bene', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciTipoBene', 'Gestisci Tipo Bene', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricTipoBene', 'Ricerca Tipo Bene', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--CESPITE
	('OP-INV-insCespite', 'Inserisci Scheda Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciCespite', 'Gestisci Scheda Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricCespite', 'Ricerca Scheda Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insDonazione', 'Inserisci Donazione/Rinvenimento Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--VARIAZIONI CESPITE
	('OP-INV-gestisciVarCespite', 'Gestisci Variazione Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insRivCespite', 'Inserisci Rivalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricRivCespite', 'Ricerca Rivalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insSvalCespite', 'Inserisci Svalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricSvalCespite', 'Ricerca Svalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--DISMISSIONI CESPITE
	('OP-INV-insDisCespite', 'Inserisci Dismissione Beni', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciDisCespite', 'Gestisci Dismissione Beni', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricDisCespite', 'Ricerca Dismissione Beni', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	-- *****************************************************************************************
	------ V02
	('OP-INV-gestisciAmmMassivo','Ammortamento Massivo', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciAmmAnnuo','Ammortamento Annuo', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	---V03
	('OP-FLUSSO-CESPITI','Gestione flusso cespiti', 'ATTIVITA_SINGOLA', 'INV', '/../siacintegser/ElaboraFileService'),
	--V04
	('OP-INV-ricRegistroB', 'Ricerca Prime Note Elaborate Dall''Inventario', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciRegistroB', 'Gestisci registro B', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-validaRegistroB', 'Valida registro B', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),	
	--V05
	-- REGISTRO A
	('OP-INV-ricRegistroA', 'Ricerca Registro Prime Note Definitive Verso Inventario Contabile', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciRegistroA', 'Gestisci Registro Prime Note Definitive Verso Inventario Contabile', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	-- Per comodita' di scrittura
	(null, null, null, null, null)
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code, urlapplicazione) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);
--AZIONI FINE

--------------- CODIFICHE INIZIO ------------------
-- AMBITO INIZIO
insert into siac_d_ambito
(
	ambito_code,
    ambito_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 'AMBITO_INV',
       'Ambito Inventario Beni Mobili',
       '2016-01-01'::timestamp,
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_ambito a1
 where a1.ente_proprietario_id=ente.ente_proprietario_id
 and   a1.ambito_code='AMBITO_INV');
-- AMBITO FINE

-- EVENTI e CAUSALI INIZIO (INC000002793194)

insert into SIAC_D_EVENTO_TIPO
(
 evento_tipo_code,
 evento_tipo_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id )
select 'INV-COGE',
       'Da Inventario Beni Mobili a CoGe',
       '2016-01-01'::timestamp,
       'INC000002793194',
       e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(select 1 from SIAC_D_EVENTO_TIPO tipo where tipo.ente_proprietario_id=e.ente_proprietario_id and tipo.evento_tipo_code='INV-COGE');

insert into SIAC_D_EVENTO_TIPO
(
 evento_tipo_code,
 evento_tipo_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id )
select 'COGE-INV',
       'Da CoGe a Inventario Beni Mobili',
       '2016-01-01'::timestamp,
       'INC000002793194',
       e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(select 1 from SIAC_D_EVENTO_TIPO tipo where tipo.ente_proprietario_id=e.ente_proprietario_id and tipo.evento_tipo_code='COGE-INV');


-- SIAC_D_EVENTO

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'DON',
       'Donazione/Rinvenimento',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='DON');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'RIV',
       'Donazione Bene MobileRivalutazione Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento.evento_code='RIV');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'AMA',
       'Ammortamento Annuo Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='AMA');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'DIS',
       'Dismissione Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='DIS');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'VEP',
       'Vendita Bene Mobile con Plusvalenza',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='VEP');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'VEM',
       'Vendita bene Mobile con Minusvalenza',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='VEM');


insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'SVA',
       'Svalutazione Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='SVA');

insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'AMR',
       'Ammortamento Residuo Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='AMR');


insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'ACQ',
       'Acquisto bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='COGE-INV'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='ACQ');


insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'VEN',
       'Vendita Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='COGE-INV'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='VEN');


insert into SIAC_D_EVENTO
(evento_code,
 evento_desc,
 evento_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'MVA',
       'Modifica Valore Bene Mobile',
        tipo.evento_tipo_id,
        '2016-01-01'::timestamp,
        'INC000002793194',
        e.ente_proprietario_id
from siac_t_ente_proprietario e,siac_d_evento_tipo tipo
where tipo.evento_tipo_code='COGE-INV'
and   tipo.ente_proprietario_id=e.ente_proprietario_id
and not exists
(select 1 from siac_d_evento evento
 where evento.evento_tipo_id = tipo.evento_tipo_id and evento_code='MVA');


-- SIAC_T_CAUSALE_EP

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'DON',
       'Donazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='DON'
);


insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'DON',
       'Donazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='DON'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'RIV',
       'Rivalutazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='RIV'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'RIV',
       'Rivalutazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='RIV'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'AMA',
       'Ammortamento Annuo Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='AMA'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'AMA',
       'Ammortamento Annuo Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='AMA'
);


insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'DIS',
       'Dismissione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='DIS'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'DIS',
       'Dismissione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='DIS'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'VEP',
       'Vendita Bene Mobile con Plusvalenza',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='VEP'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'VEP',
       'Vendita Bene Mobile con Plusvalenza',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='VEP'
);




insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'VEM',
       'Vendita bene Mobile con Minusvalenza',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='VEM'
);


insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'VEM',
       'Vendita bene Mobile con Minusvalenza',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='VEM'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'SVA',
       'Svalutazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='SVA'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'SVA',
       'Svalutazione Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='SVA'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'AMR',
       'Ammortamento Residuo Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_INV'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='AMR'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'AMR',
       'Ammortamento Residuo Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='AMR'
);

insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'ACQ',
       'Acquisto bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='ACQ'
);


insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'VEN',
       'Vendita Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='VEN'
);


insert into siac_t_causale_ep
( causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  ambito_id,
  validita_inizio,
  login_operazione,
  login_creazione,
  login_modifica,
  ente_proprietario_id
)
select 'MVA',
       'Modifica Valore Bene Mobile',
       tipo.causale_ep_tipo_id,
       ambito.ambito_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       'INC000002793194',
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1
 from siac_t_causale_ep ep
 where ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
 and   ep.ambito_id=ambito.ambito_id
 and   ep.causale_ep_code='MVA'
);




-- SIAC_R_CAUSALE_EP_STATO
insert into siac_r_causale_ep_stato
(
	causale_ep_id,
    causale_ep_stato_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select ep.causale_ep_id,
       stato.causale_ep_stato_id,
       'INC000002793194',
       '2016-01-01'::timestamp,
       ep.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_d_causale_ep_stato stato,
     siac_t_causale_ep ep, siac_d_causale_ep_tipo tipo, siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code in ('AMBITO_INV','AMBITO_FIN')
and   ep.ambito_id=ambito.ambito_id
and   ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
and   ep.causale_ep_code in ('DON','RIV','AMA','DIS','VEP','VEM','SVA','AMR')
and   stato.ente_proprietario_id=ente.ente_proprietario_id
and   stato.causale_ep_stato_code='V'
and   not exists
(select 1 from siac_r_causale_ep_stato r
 where r.causale_ep_id=ep.causale_ep_id
 and   r.causale_ep_stato_id=stato.causale_ep_stato_id
 and   r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);


insert into siac_r_causale_ep_stato
(
	causale_ep_id,
    causale_ep_stato_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select ep.causale_ep_id,
       stato.causale_ep_stato_id,
       'INC000002793194',
       '2016-01-01'::timestamp,
       ep.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_d_causale_ep_stato stato,
     siac_t_causale_ep ep, siac_d_causale_ep_tipo tipo, siac_d_ambito ambito
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   ambito.ente_proprietario_id=tipo.ente_proprietario_id
and   ambito.ambito_code='AMBITO_FIN'
and   ep.ambito_id=ambito.ambito_id
and   ep.causale_ep_tipo_id=tipo.causale_ep_tipo_id
and   ep.causale_ep_code in ('ACQ','VEN','MVA')
and   stato.ente_proprietario_id=ente.ente_proprietario_id
and   stato.causale_ep_stato_code='V'
and   not exists
(select 1 from siac_r_causale_ep_stato r
 where r.causale_ep_id=ep.causale_ep_id
 and   r.causale_ep_stato_id=stato.causale_ep_stato_id
 and   r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);


-- SIAC_R_EVENTO_CAUSALE
insert into SIAC_R_EVENTO_CAUSALE
(
 evento_id,
 causale_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select evento.evento_id,
       ep.causale_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_causale_ep ep, siac_d_evento evento, siac_t_ente_proprietario ente,siac_d_ambito ambito
where ep.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_code in ('DON','RIV','AMA','DIS','VEP','VEM','SVA','AMR')
and   ep.ente_proprietario_id=evento.ente_proprietario_id
and   evento.ente_proprietario_id=ep.ente_proprietario_id
and   evento.evento_code=ep.causale_ep_code
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   not exists
(select 1 from siac_r_evento_causale r
 where r.evento_id=evento.evento_id and r.causale_ep_id=ep.causale_ep_id
 and   r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null);

-- SIAC_R_EVENTO_CAUSALE
insert into SIAC_R_EVENTO_CAUSALE
(
 evento_id,
 causale_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select evento.evento_id,
       ep.causale_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ente.ente_proprietario_id
from siac_t_causale_ep ep, siac_d_evento evento, siac_t_ente_proprietario ente,siac_d_ambito ambito
where ep.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_code in ('ACQ','VEN','MVA')
and   evento.ente_proprietario_id=ep.ente_proprietario_id
and   evento.evento_code=ep.causale_ep_code
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code='AMBITO_FIN'
and   not exists
(select 1 from siac_r_evento_causale r
 where r.evento_id=evento.evento_id and r.causale_ep_id=ep.causale_ep_id
 and   r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null);



-- SIAC_R_CAUSALE_EP_PDCE_CONTO
insert into SIAC_R_CAUSALE_EP_PDCE_CONTO
(
	causale_ep_id,
    pdce_conto_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select ep.causale_ep_id,
       conto.pdce_conto_id,
       'INC000002793194',
       '2016-01-01'::timestamp,
       ep.ente_proprietario_id
from siac_t_causale_ep ep, siac_t_pdce_conto conto, siac_t_ente_proprietario ente,siac_d_ambito ambito
where ep.ente_proprietario_id=ente.ente_proprietario_id
and  ep.causale_ep_code in ('DON','RIV')
and  ambito.ambito_id=ep.ambito_id
and  ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and  conto.ente_proprietario_id=ente.ente_proprietario_id
and  conto.pdce_conto_code='5.2.3.99.99.001'
and  not exists
(select 1 from siac_r_causale_ep_pdce_conto r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.causale_ep_id=ep.causale_ep_id
 and   r.pdce_conto_id=conto.pdce_conto_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);


insert into SIAC_R_CAUSALE_EP_PDCE_CONTO
(
	causale_ep_id,
    pdce_conto_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select ep.causale_ep_id,
       conto.pdce_conto_id,
       'INC000002793194',
       '2016-01-01'::timestamp,
       ep.ente_proprietario_id
from siac_t_causale_ep ep, siac_t_pdce_conto conto, siac_t_ente_proprietario ente,siac_d_ambito ambito
where ep.ente_proprietario_id=ente.ente_proprietario_id
and  ep.causale_ep_code ='SVA'
and  ambito.ambito_id=ep.ambito_id
and  ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and  conto.ente_proprietario_id=ente.ente_proprietario_id
and  conto.pdce_conto_code='5.1.2.01.01.001'
and  not exists
(select 1 from siac_r_causale_ep_pdce_conto r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.causale_ep_id=ep.causale_ep_id
 and   r.pdce_conto_id=conto.pdce_conto_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);



-- SIAC_R_CAUSALE_EP_PDCE_CONTO_OP

insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='AVERE'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='DON'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.2.3.99.99.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);


insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='LORDO'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='DON'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.2.3.99.99.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);


insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='AVERE'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='RIV'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.2.3.99.99.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);


insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='LORDO'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='RIV'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.2.3.99.99.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);


insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='DARE'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='SVA'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.1.2.01.01.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);


insert into siac_r_causale_ep_pdce_conto_oper
(
 causale_ep_pdce_conto_id,
 oper_ep_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select r.causale_ep_pdce_conto_id,
       op.oper_ep_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       ep.ente_proprietario_id
from siac_t_causale_ep ep, SIAC_R_CAUSALE_EP_PDCE_CONTO r,siac_t_pdce_conto conto,
     siac_d_operazione_ep op,siac_t_ente_proprietario ente,siac_d_ambito ambito
where op.ente_proprietario_id=ente.ente_proprietario_id
and   op.oper_ep_code='LORDO'
and   r.ente_proprietario_id=ente.ente_proprietario_id
and   ep.causale_ep_id=r.causale_ep_id
and   ep.causale_ep_code='SVA'
and   ambito.ambito_id=ep.ambito_id
and   ambito.ambito_code in ('AMBITO_FIN','AMBITO_INV')
and   conto.pdce_conto_id=r.pdce_conto_id
and   conto.pdce_conto_code='5.1.2.01.01.001'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(select 1 from siac_r_causale_ep_pdce_conto_oper r1
 where r1.ente_proprietario_id=ente.ente_proprietario_id
 and   r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
 and   r1.oper_ep_id=op.oper_ep_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);

-- SIAC_R_CAUSALE_EP_TIPO_EVENTO_T

insert into siac_r_causale_ep_tipo_evento_tipo
( causale_ep_tipo_id,
  evento_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tipo.causale_ep_tipo_id,
       evento_tipo.evento_tipo_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       evento_tipo.ente_proprietario_id
from  siac_d_causale_ep_tipo tipo, siac_d_evento_tipo evento_tipo,siac_t_ente_proprietario ente
where evento_tipo.ente_proprietario_id=ente.ente_proprietario_id
and   evento_tipo.evento_tipo_code='INV-COGE'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   not exists
(select 1 from siac_r_causale_ep_tipo_evento_tipo r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.evento_tipo_id=evento_tipo.evento_tipo_id
 and   tipo.causale_ep_tipo_id=r.causale_ep_tipo_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);

insert into siac_r_causale_ep_tipo_evento_tipo
( causale_ep_tipo_id,
  evento_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tipo.causale_ep_tipo_id,
       evento_tipo.evento_tipo_id,
       '2016-01-01'::timestamp,
       'INC000002793194',
       evento_tipo.ente_proprietario_id
from  siac_d_causale_ep_tipo tipo, siac_d_evento_tipo evento_tipo,siac_t_ente_proprietario ente
where evento_tipo.ente_proprietario_id=ente.ente_proprietario_id
and   evento_tipo.evento_tipo_code='COGE-INV'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.causale_ep_tipo_code='LIB'
and   not exists
(select 1 from siac_r_causale_ep_tipo_evento_tipo r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.evento_tipo_id=evento_tipo.evento_tipo_id
 and   tipo.causale_ep_tipo_id=r.causale_ep_tipo_id
 and   r.data_cancellazione is null
 and   r.validita_fine is null
);

-- EVENTI e CAUSALI FINE

-- TIPO CALCOLO INIZIO
INSERT INTO
  siac.siac_d_cespiti_categoria_calcolo_tipo
(
  cescat_calcolo_tipo_code,
  cescat_calcolo_tipo_desc,
  ente_proprietario_id,  
  validita_inizio,  
  data_creazione,
  data_modifica,
  login_operazione
)
SELECT tmp.code, tmp.descr, tep.ente_proprietario_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), now(),now(),'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('100', 'Quota intera'), ('50', '50% quota'),('12', 'In 12-esimi'),('365', 'In 365-esimi')) AS tmp(code, descr)
WHERE NOT EXISTS (select 1 
	from siac_d_cespiti_categoria_calcolo_tipo z 
	where z.cescat_calcolo_tipo_code=tmp.code
	and z.ente_proprietario_id=tep.ente_proprietario_id
	and z.data_cancellazione is null
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-- TIPO CALCOLO FINE

-- CLASSIFICAZIONE GIURIDICA INIZIO

insert into	siac_d_cespiti_classificazione_giuridica
(ces_class_giu_code,  ces_class_giu_desc, validita_inizio, data_creazione, ente_proprietario_id,  login_operazione)
SELECT tmp.code, tmp.descr,to_timestamp('2016-01-01', 'YYYY-MM-DD'), now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep           
CROSS JOIN(VALUES ('1','BENE DISPONIBILE'), ('2','BENE INDISPONIBILE'), ('3','BENE DEMANIALE')) as tmp(code, descr)
WHERE not exists (
 SELECT 1 FROM siac_d_cespiti_classificazione_giuridica et
 WHERE et.ces_class_giu_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.data_cancellazione is null); 
 
-- CLASSIFICAZIONE GIURIDICA INIZIO

-- STATO DISMISSIONE INIZIO

INSERT INTO siac_d_cespiti_dismissioni_stato (ces_dismissioni_stato_code, ces_dismissioni_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ces_dismissioni_stato_code, tmp.ces_dismissioni_stato_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('P', 'Provvisorio'),
	('D', 'Definitivo'),
	('N.D.', 'Scritture non presenti')
) AS tmp(ces_dismissioni_stato_code, ces_dismissioni_stato_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cespiti_dismissioni_stato dcvs
	WHERE dcvs.ces_dismissioni_stato_code = tmp.ces_dismissioni_stato_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ces_dismissioni_stato_code;

-- STATO DISMISSIONE FINE

-- STATO PRIME NOTE INIZIO
INSERT INTO siac_d_pn_prov_accettazione_stato (pn_sta_acc_prov_code, pn_sta_acc_prov_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.pn_sta_acc_prov_code, tmp.pn_sta_acc_prov_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('1', 'Definitivo'),
	('2', 'Rifiutato'),
	('3', 'Provvisorio')
) AS tmp(pn_sta_acc_prov_code, pn_sta_acc_prov_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_pn_prov_accettazione_stato dcvs
	WHERE dcvs.pn_sta_acc_prov_code = tmp.pn_sta_acc_prov_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.pn_sta_acc_prov_code;

INSERT INTO siac_d_pn_def_accettazione_stato (pn_sta_acc_def_code, pn_sta_acc_def_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.pn_sta_acc_def_code, tmp.pn_sta_acc_def_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('1', 'Integrato con inventario'),
	('2', 'Rifiutato'),
	('3', 'Da accettare')
) AS tmp(pn_sta_acc_def_code, pn_sta_acc_def_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_pn_def_accettazione_stato dcvs
	WHERE dcvs.pn_sta_acc_def_code = tmp.pn_sta_acc_def_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.pn_sta_acc_def_code;

-- STATO PRIME NOTE FINE

-- STATO VARIAZIONE INIZIO

INSERT INTO siac_d_cespiti_variazione_stato (ces_var_stato_code, ces_var_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ces_var_stato_code, tmp.ces_var_stato_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('P', 'Provvisorio'),
	('D', 'Definitivo'),
	('A', 'Annullato')
) AS tmp(ces_var_stato_code, ces_var_stato_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cespiti_variazione_stato dcvs
	WHERE dcvs.ces_var_stato_code = tmp.ces_var_stato_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ces_var_stato_code;

-- STATO VARIAZIONE FINE

--  RELAZIONI PRIME NOTE INIZIO
INSERT INTO
  siac.siac_d_prima_nota_rel_tipo
(
  pnota_rel_tipo_code,
  pnota_rel_tipo_desc,
  ente_proprietario_id,  
  validita_inizio,  
  data_creazione,
  data_modifica,
  login_operazione
)
SELECT tmp.code, tmp.descr, tep.ente_proprietario_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), now(),now(),'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('COGE-INV', 'Prima nota da contabilita generale'), ('INV-COGE', 'Prima nota da inventario contabile')) AS tmp(code, descr)
WHERE NOT EXISTS (select 1 
	from siac_d_prima_nota_rel_tipo z 
	where z.pnota_rel_tipo_code=tmp.code
	and z.ente_proprietario_id=tep.ente_proprietario_id
	and z.data_cancellazione is null
)
ORDER BY tep.ente_proprietario_id, tmp.code;
--  RELAZIONI PRIME NOTE FINE

-- FILE TIPO ELABORAZIONE CESPITI INIZIO
INSERT INTO siac_d_file_tipo
( file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
SELECT 
	'CESPITI',
    'Caricamento massivo cespiti',
    (SELECT a.azione_id FROM siac_t_azione a 
    WHERE a.azione_code='OP-FLUSSO-CESPITI' 
    AND a.ente_proprietario_id=e.ente_proprietario_id),
    NOW(),
    e.ente_proprietario_id,
	'admin'    
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT 1 FROM siac_d_file_tipo ft
    WHERE ft.file_tipo_code='FLUSSO_CESPITI' 
    AND ft.ente_proprietario_id=e.ente_proprietario_id
);
-- FILE TIPO ELABORAZIONE CESPITI INIZIO


--------------- CODIFICHE INIZIO ------------------

--- aggiornamento tipo cespite su conti - inizio

update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.02.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.03.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.04.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.05.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.06.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.03.07.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.04.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.06.02.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.06.99.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.99.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.1.99.01.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.01.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.01.02.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.01.03.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.01.99.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.01.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.01.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.01.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.03.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.03.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.03.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.03.99.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.04.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.04.99.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.05.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.05.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.05.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.06.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.04.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.05.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.07.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.08.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.08.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.04.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.05.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.07.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.08.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.09.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.10.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.11.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.13.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.14.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.16.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.17.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.18.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.19.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.09.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.04.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.05.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.06.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.07.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.08.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.09.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.10.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.11.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.12.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.12.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.12.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.13.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.13.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.02.13.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.02.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.03.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.04.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.05.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.03.06.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.04.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.04.02.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.01.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.01.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.01.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.01.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.03.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.03.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.03.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.04.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.04.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.05.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.05.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.05.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.06.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.04.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.05.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.07.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.08.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.08.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.03.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.04.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.05.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.06.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.07.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.08.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.09.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.10.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.11.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.12.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.13.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.14.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.09.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.10.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.11.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.11.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.11.99.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.12.01.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.12.02.001' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;
update siac_t_pdce_conto conto set pdce_ct_tipo_id=tipo.pdce_ct_tipo_id, data_modifica=now(), login_operazione=conto.login_operazione||'-INC000002818806'   from   siac_d_pdce_conto_tipo tipo,siac_t_ente_proprietario ente  where  tipo.pdce_ct_tipo_code='CES'  and    ente.ente_proprietario_id=tipo.ente_proprietario_id  and    conto.ente_proprietario_id=ente.ente_proprietario_id  and    conto.pdce_conto_code='1.2.2.05.12.03.999' and    conto.pdce_ct_tipo_id!=tipo.pdce_ct_tipo_id  and    conto.data_cancellazione is null  and    conto.validita_fine is null;


--- aggiornamento tipo cespite su conti - fine



