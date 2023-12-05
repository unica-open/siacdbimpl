 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
ALTER TABLE siac.sirfel_d_natura ALTER COLUMN codice TYPE varchar(4);
ALTER TABLE siac.sirfel_t_riepilogo_beni ALTER COLUMN natura TYPE VARCHAR(4);
ALTER TABLE siac.sirfel_t_cassa_previdenziale ALTER COLUMN natura TYPE VARCHAR(4);

/*
* N2.X Campi non soggetti
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.1',
'non soggette ad IVA ai sensi degli articoli da 7 a 7- septies del D.P.R. n. 633/1972'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.2',
'non soggette - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N3.X Campi non imponibili
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.1',
'non imponibili - esportazioni'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.2',
'non imponibili - cessioni intracomunitarie'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.3',
'non imponibili - cessioni verso San Marino'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.4',
'non imponibili - operazioni assimilate alle cessioni all’esportazione'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.5',
'non imponibili - a seguito di dichiarazioni d’intento'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.6',
'non imponibili - altre operazioni che non concorrono alla formazione del plafond'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N6.X Campi inversione contabile
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.1',
'inversione contabile - cessione di rottami e altri materiali di recupero'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.2',
'inversione contabile - cessione di oro e argento puro'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.3',
'inversione contabile - subappalto nel settore edile'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.4',
'inversione contabile - cessione di fabbricati'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.5',
'inversione contabile - cessione di telefoni cellulari'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.6',
'inversione contabile - cessione di prodotti elettronici'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.7',
'inversione contabile - prestazioni comparto edile e settori connessi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.7'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.8',
'inversione contabile - operazioni settore energetico'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.8'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.9',
'inversione contabile - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.9'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);




