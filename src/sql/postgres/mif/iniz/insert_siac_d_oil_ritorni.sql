/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select * from siac_d_oil_ricevuta_tipo
select * from siac_d_oil_esito_derivato
select * from siac_d_oil_qualificatore

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'F',
  'Firma ordinativo',
  'S',
  now(),
  2,
  'mif'
);

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'P',
  'Provvisorio di cassa',
  'P',
  now(),
  2,
  'mif'
);

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'Q',
  'Quietanza ordinativo',
  'R',
  now(),
  2,
  'mif'
);

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'S',
  'Storno quietanza ordinativo',
  'R',
  now(),
  2,
  'mif'
);

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,
  oil_ricevuta_tipo_desc,
  oil_ricevuta_tipo_code_fl,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'PS',
  'Storno Provvisorio di cassa',
  'P',
  now(),
  2,
  'mif'
);

INSERT INTO  siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 (select
  '01',
  'Quietanzamento ordinativo',
  tipo.oil_ricevuta_tipo_id,
  now(),
  2,
  'mif'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='Q'
  and   tipo.ente_proprietario_id=2
);

INSERT INTO  siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 (select
  '51',
  'Storno quietanzamento ordinativo',
  tipo.oil_ricevuta_tipo_id,
  now(),
  2,
  'mif'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='S'
  and   tipo.ente_proprietario_id=2

);


INSERT INTO  siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 (select
  '00',
  'Firma ordinativo',
  tipo.oil_ricevuta_tipo_id,
  now(),
  2,
  'mif'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='F'
  and   tipo.ente_proprietario_id=2

);

INSERT INTO  siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 (select
  '52',
  'Comunicazione di pagamento/incasso',
  tipo.oil_ricevuta_tipo_id,
  now(),
  2,
  'mif'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   tipo.ente_proprietario_id=2

);

INSERT INTO  siac_d_oil_esito_derivato
(
  oil_esito_derivato_code,
  oil_esito_derivato_desc,
  oil_ricevuta_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 (select
  '53',
  'Storno di una comunicazione di pagamento/incasso',
  tipo.oil_ricevuta_tipo_id,
  now(),
  2,
  'mif'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='PS'
  and   tipo.ente_proprietario_id=2

);


insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'PM',
  'Pagamento mandato',
  'U',
  1,
  now(),
  2,
  'mif'
);
insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'RM',
  'Regolarizzazione mandato',
  'U',
  1,
  now(),
  2,
  'mif'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'SM',
  'Storno mandato',
  'U',
  2,
  now(),
  2,
  'mif'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'SRM',
  'Storno regolarizzazione mandato',
  'U',
  2,
  now(),
  2,
  'mif'
);


insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'IR',
  'Pagamento reversale',
  'E',
  1,
  now(),
  2,
  'mif'
);
insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'RR',
  'Regolarizzazione reversale',
  'E',
  1,
  now(),
  2,
  'mif'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'SR',
  'Storno reversale',
  'E',
  2,
  now(),
  2,
  'mif'
);
insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'SRR',
  'Storno regolarizzazione reversale',
  'E',
  2,
  now(),
  2,
  'mif'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'FM',
  'Pacchetto di Mandati Firmati',
  'U',
  3,
  now(),
  2,
  'mif'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'FR',
  'Pacchetto di Reversali Firmati',
  'E',
  3,
  now(),
  2,
  'mif'
);


insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
(
  select 'PSU',
         'Pagamento sospesi uscita',
         'U',
         o.oil_esito_derivato_id,
         now(),
         15,
        'mif'
  from siac_d_oil_esito_derivato o
  where o.ente_proprietario_id=15
  and   o.oil_esito_derivato_code='52'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
(
  select 'SSU',
         'Storno sospesi uscita',
         'U',
         o.oil_esito_derivato_id,
         now(),
         2,
        'mif'
  from siac_d_oil_esito_derivato o
  where o.ente_proprietario_id=15
  and   o.oil_esito_derivato_code='53'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
(
  select 'ISE',
         'Incasso sospesi entrata',
         'E',
         o.oil_esito_derivato_id,
         now(),
         15,
        'mif'
  from siac_d_oil_esito_derivato o
  where o.ente_proprietario_id=15
  and   o.oil_esito_derivato_code='52'
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,
  oil_qualificatore_desc,
  oil_qualificatore_segno,
  oil_esito_derivato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
(
  select 'SSE',
         'Storno sospesi entrata',
         'E',
         o.oil_esito_derivato_id,
         now(),
         15,
        'mif'
  from siac_d_oil_esito_derivato o
  where o.ente_proprietario_id=15
  and   o.oil_esito_derivato_code='53'
);



select
'insert into siac_d_oil_ricevuta_errore
 (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione )
 values ( '
 ||quote_nullable(e.oil_ricevuta_errore_code)||','
 ||quote_nullable(e.oil_ricevuta_errore_desc)||','
 ||quote_nullable('2015-01-01')||','
 ||e.ente_proprietario_id||','
 ||quote_nullable(e.login_operazione)||');'
from siac_d_oil_ricevuta_errore e
where ente_proprietario_id=15