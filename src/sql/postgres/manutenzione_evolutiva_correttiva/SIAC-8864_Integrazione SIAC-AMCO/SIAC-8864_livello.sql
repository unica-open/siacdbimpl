/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'SCARICO_GSA_ORD_ANNO_PREC',
         'Attivazione scarico ordinativi GSA per annoBilancio-1',
         now(),
         'SIAC-8864',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id in (2,3,4,5,10,16)
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='SCARICO_GSA_ORD_ANNO_PREC'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	'2022',
    '2022_'||tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_proprietario_id in (2,3,4,5,10,16)
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='SCARICO_GSA_ORD_ANNO_PREC'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code='2022'
  );