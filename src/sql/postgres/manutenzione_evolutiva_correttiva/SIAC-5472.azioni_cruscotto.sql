/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-BKOF012-configuraNumeroAnniBilancioPrev',
'Configura indicatori (numero anni bilancio previsione)',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FUN_ACCESSORIE' 
and not exists 
(select 1 from siac_t_azione z 
	where z.azione_code='OP-BKOF012-configuraNumeroAnniBilancioPrev'
	and z.ente_proprietario_id=a.ente_proprietario_id
);




INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-BKOF008-gestioneConfIndicatoriEntrata',
'Configura Indicatori Entrata',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FUN_ACCESSORIE' 
and not exists 
(select 1 from siac_t_azione z 
	where z.azione_code='OP-BKOF008-gestioneConfIndicatoriEntrata'
	and z.ente_proprietario_id=a.ente_proprietario_id
);



INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-BKOF009-gestioneConfIndicatoriSpesa',
'Configura Indicatori Spesa',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FUN_ACCESSORIE' 
and not exists 
(select 1 from siac_t_azione z 
	where z.azione_code='OP-BKOF009-gestioneConfIndicatoriSpesa'
	and z.ente_proprietario_id=a.ente_proprietario_id
);



INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-BKOF010-gestioneConfIndicatoriSint',
'Configura Indicatori Sintetici',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b, siac_t_ente_proprietario e
where
b.ente_proprietario_id=A.ente_proprietario_id
and b.ente_proprietario_id=e.ente_proprietario_id
and e.codice_fiscale <> '80087670016' -- REGP ESCLUSA
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FUN_ACCESSORIE' 
and not exists 
(select 1 from siac_t_azione z 
	where z.azione_code='OP-BKOF010-gestioneConfIndicatoriSint'
	and z.ente_proprietario_id=a.ente_proprietario_id
);






INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-BKOF011-gestioneConfIndicatoriSintMiss13',
'Configura Indicatori Sintetici',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b, siac_t_ente_proprietario e
where
b.ente_proprietario_id=A.ente_proprietario_id
and b.ente_proprietario_id=e.ente_proprietario_id
and e.codice_fiscale='80087670016' -- SOLTANTO REGP
and
a.azione_tipo_code='ATTIVITA_SINGOLA'
and b.gruppo_azioni_code='FUN_ACCESSORIE' 
and not exists 
(select 1 from siac_t_azione z 
	where z.azione_code='OP-BKOF011-gestioneConfIndicatoriSintMiss13'
	and z.ente_proprietario_id=a.ente_proprietario_id
);




