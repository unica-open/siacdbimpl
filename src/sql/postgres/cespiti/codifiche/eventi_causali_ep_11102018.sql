/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC_D_EVENTO_TIPO
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

