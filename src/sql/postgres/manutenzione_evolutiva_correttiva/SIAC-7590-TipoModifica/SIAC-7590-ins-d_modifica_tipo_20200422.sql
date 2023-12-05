/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 22.04.2020 Filippo SIAC-7590-ins-d_modifica_tipo
-- SIAC-7590-ins-d_modifica_tipo_20200422.sql
/*Aggiunte i motivi per le modifiche di accertamento per insussistenza e inesigibilità per utenti con codice_fiscale 01907990012

Si aggiungono alla lista dei valori di "Modifica motivo" i seguenti:
	ROR - Cancellazione per Insussistenza (tipo modifica INSROR)
	ROR - Cancellazione per Inesigibilità (tipo modifica INEROR)
*/

 
insert into siac_d_modifica_tipo
(
  mod_tipo_code,
  mod_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
'INSROR',
'ROR - Cancellazione per Insussistenza',
    now(),
    'SIAC-7590',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.codice_fiscale in ('01907990012')
and not exists
(
select 1
from siac_d_modifica_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.mod_tipo_code='INSROR'
and   tipo.mod_tipo_desc='ROR - Cancellazione per Insussistenza'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


insert into siac_d_modifica_tipo
(
  mod_tipo_code,
  mod_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
'INEROR',
'ROR - Cancellazione per Inesigibilita''',
    now(),
    'SIAC-7590',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.codice_fiscale in ('01907990012')
and   not exists
(
select 1
from siac_d_modifica_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.mod_tipo_code='INEROR'
and   tipo.mod_tipo_desc='ROR - Cancellazione per Inesigibilita'''
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);


