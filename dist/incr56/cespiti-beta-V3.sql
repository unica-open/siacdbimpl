/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- CAUSALI ED EVENTI INIZIO

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


 --- CAUSALI ED EVENTI FINE 
  
  
--INIZIO fnc_ammortamento annuo
DROP FUNCTION IF EXISTS fnc_siac_cespiti_elab_ammortamenti(
   integer,
   varchar,
   integer
);


CREATE OR REPLACE FUNCTION fnc_siac_cespiti_elab_ammortamenti (
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_anno integer,
  out numcespiti INTEGER,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    dataElaborazione timestamp 	:= now();
    strMessaggio VARCHAR(1500)	:='Inizio elab.';
    rec_elab_ammortamenti 		record;
    rec_elab_x_cespite    		record;
    v_elab_id 					INTEGER;        
    v_ces_id 					INTEGER;
    v_elab_dett_id_dare 		INTEGER;
    v_elab_dett_id_avere 		INTEGER;
    v_pnota_id 					INTEGER;
    v_ces_amm_dett_id			INTEGER;
begin
    numcespiti:=0;
    select elab_id into v_elab_id from siac_t_cespiti_elab_ammortamenti 
    where anno = p_anno and ente_proprietario_id = p_enteproprietarioid and data_cancellazione is null;
    
    if v_elab_id is not null then
    
      update  siac_r_cespiti_cespiti_elab_ammortamenti set data_cancellazione = now() ,validita_fine = now() where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti_dett    set data_cancellazione = now() ,validita_fine = now() where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti         set data_cancellazione = now() ,validita_fine = now() where elab_id = v_elab_id;
	
    end if;

    insert into siac_t_cespiti_elab_ammortamenti (anno,stato_elaborazione,data_elaborazione,validita_inizio,validita_fine ,ente_proprietario_id,data_cancellazione,login_operazione) 
    values(p_anno,'AVVIATO',now(),now(),null, p_enteproprietarioid ,null,p_loginoperazione) RETURNING elab_id INTO v_elab_id;


    for rec_elab_ammortamenti in (	
         select 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id, 
        dct.pdce_conto_fondo_ammortamento_code, 
        dct.pdce_conto_fondo_ammortamento_desc,
        COALESCE(count(*),0) numero_cespiti,
        coalesce(sum(tamd.ces_amm_dett_importo), 0) importo
        from siac_t_cespiti tc
        , siac_d_cespiti_bene_tipo dct 
        , siac_t_cespiti_ammortamento tam 
        , siac_t_cespiti_ammortamento_dett tamd 
        where (tc.data_cessazione is null OR (EXTRACT(YEAR FROM tc.data_cessazione))::INTEGER = p_anno)
        and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
        and tam.ces_id = tc.ces_id and tam.data_cancellazione is null
        and tamd.ces_amm_id = tam.ces_amm_id 
        and tamd.data_cancellazione is null 
        and tamd.num_reg_def_ammortamento is null
        and dct.pdce_conto_ammortamento_id is not null 
        and dct.pdce_conto_fondo_ammortamento_id is not null
        and tamd.ces_amm_dett_anno = p_anno 
        and tamd.ente_proprietario_id = p_enteproprietarioid  
        group by 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id,
        dct.pdce_conto_fondo_ammortamento_code,
        dct.pdce_conto_fondo_ammortamento_desc
     ) loop
	
	strMessaggio :='inserimento in siac_t_cespiti_elab_ammortamenti_dett.';

    insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Dare'        
        ,rec_elab_ammortamenti.numero_cespiti        
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    ) returning elab_dett_id into v_elab_dett_id_dare ;



   insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Avere'        
        ,rec_elab_ammortamenti.numero_cespiti      
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    )returning elab_dett_id into v_elab_dett_id_avere ;

      for rec_elab_ammortamenti in (	
          select         	
              tc.ces_id   
              ,tamd.ces_amm_dett_id         
          from 
            siac_t_cespiti tc
          , siac_d_cespiti_bene_tipo dct 
          , siac_t_cespiti_ammortamento tam 
          , siac_t_cespiti_ammortamento_dett tamd 
          where tc.data_cessazione is null 
          and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
          and tam.ces_id = tc.ces_id 
          and tam.data_cancellazione is null
          and tamd.ces_amm_id = tam.ces_amm_id         
          and dct.pdce_conto_ammortamento_id       = rec_elab_ammortamenti.pdce_conto_ammortamento_id
          and dct.pdce_conto_fondo_ammortamento_id = rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id
          and tamd.data_cancellazione is null 
          and tamd.num_reg_def_ammortamento  is null
          and dct.pdce_conto_ammortamento_id is not null 
          and dct.pdce_conto_fondo_ammortamento_id is not null
          and tamd.ces_amm_dett_anno = p_anno::integer
          and tamd.ente_proprietario_id = p_enteproprietarioid
      ) loop


          insert into siac_r_cespiti_cespiti_elab_ammortamenti(
               ces_id
              ,elab_id
              ,elab_dett_id_dare
              ,elab_dett_id_avere
              ,ente_proprietario_id
              ,pnota_id
              ,validita_inizio
              ,validita_fine
              ,data_cancellazione
              ,login_operazione  
              ,ces_amm_dett_id  
          )values(
               rec_elab_ammortamenti.ces_id
              ,v_elab_id
              ,v_elab_dett_id_dare
              ,v_elab_dett_id_avere
              ,p_enteproprietarioid
              ,null--v_pnota_id,
              ,now()
              ,null
              ,null
              ,p_loginoperazione
              ,rec_elab_ammortamenti.ces_amm_dett_id
          );

			numcespiti := numcespiti + 1;
      end loop;

	end loop;	
    

	if numcespiti > 0 then
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO' where elab_id = v_elab_id;
	else
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO SENZA CESPITI' , data_cancellazione = now() where elab_id = v_elab_id;
 	end if;

    messaggiorisultato := 'OK. Fine Elaborazione.';
    
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	--update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;

        return;
	when others  THEN
		raise notice ' %  % ERRORE DB: %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        --update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;
        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
  
--fnc_ammortamento_annuo FINE
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.urlapplicazione , FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
    -- V03
	('OP-INV-gestisciAmmAnnuo','Inserisci ammortamento annuo', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),	
	('OP-FLUSSO-CESPITI','Gestione flusso cespiti', 'ATTIVITA_SINGOLA', 'INV', '/../siacintegser/ElaboraFileService')	
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code, urlapplicazione) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);
        
-- INIZIO elaborazione massiva cespiti

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
    WHERE ft.file_tipo_code='CESPITI' 
    AND ft.ente_proprietario_id=e.ente_proprietario_id
);

-- FINE elaborazione massiva cespiti
          
  