/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- mif_d_flusso_elaborato_tipo
-- siac_d_oil_ricevuta_tipo
-- siac_d_oil_esito_derivato
-- siac_d_oil_qualificatore
-- siac_d_oil_ricevuta_errore

-- mif_d_flusso_elaborato_tipo
--- flussi ritorno
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('RICQUMIF','Flusso acquisizione ricevute quietanze-storni ordinativi','EMAP','2016-01-01','admin',&ente);

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RICFIMIF','Flusso acquisizione ricevute firme ordinativi','EMFE','2016-01-01','admin',&ente);

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RICPCMIF','Flusso acquisizione ricevute provvisori di cassa ordinativi','EMAT','2016-01-01','admin',&ente);





-- siac_d_oil_ricevuta_tipo
select * from siac_d_oil_ricevuta_tipo
where ente_proprietario_id=&ente

/*insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc, oil_ricevuta_tipo_code_fl, validita_inizio,ente_proprietario_id,login_operazione)
select tipo.oil_ricevuta_tipo_code,tipo.oil_ricevuta_tipo_desc, tipo.oil_ricevuta_tipo_code_fl, tipo.validita_inizio,
       &ente_a,tipo.login_operazione
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=&ente_da; */

insert into siac_d_oil_ricevuta_tipo
(oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,login_operazione,ente_proprietario_id )
values
( 'F','Firma ordinativo','S',now(),'admin',3);
insert into siac_d_oil_ricevuta_tipo
(oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,login_operazione,ente_proprietario_id )
values
('P','Provvisorio di cassa','P',now(),'admin',3);
insert into siac_d_oil_ricevuta_tipo
(oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,login_operazione,ente_proprietario_id )
values
('Q','Quietanza ordinativo','R',now(),'admin',3);
insert into siac_d_oil_ricevuta_tipo
(oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,login_operazione,ente_proprietario_id )
values
('S','Storno quietanza ordinativo','R',now(),'admin',3);
insert into siac_d_oil_ricevuta_tipo
(oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,login_operazione,ente_proprietario_id )
values
('PS','Storno Provvisorio di cassa','P',now(),'admin',3);


-- siac_d_oil_esito_derivato
select * from siac_d_oil_esito_derivato
where ente_proprietario_id=&ente


INSERT INTO  siac_d_oil_esito_derivato
(oil_esito_derivato_code,oil_esito_derivato_desc,oil_ricevuta_tipo_id,validita_inizio,ente_proprietario_id,login_operazione)
(select '01','Quietanzamento ordinativo', tipo.oil_ricevuta_tipo_id, '2016-01-01', tipo.ente_proprietario_id,'admin'
  from siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='Q'
  and   tipo.ente_proprietario_id=&ente
);

INSERT INTO  siac_d_oil_esito_derivato
(oil_esito_derivato_code,oil_esito_derivato_desc,oil_ricevuta_tipo_id,validita_inizio,ente_proprietario_id,login_operazione)
(select '51','Storno quietanzamento ordinativo', tipo.oil_ricevuta_tipo_id,'2016-01-01',tipo.ente_proprietario_id,'admin'
 from siac_d_oil_ricevuta_tipo tipo
 where tipo.oil_ricevuta_tipo_code='S'
 and   tipo.ente_proprietario_id=&ente
);

INSERT INTO  siac_d_oil_esito_derivato
(oil_esito_derivato_code, oil_esito_derivato_desc, oil_ricevuta_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
(select '00','Firma ordinativo',tipo.oil_ricevuta_tipo_id,'2016-01-01',tipo.ente_proprietario_id,'admin'
 from siac_d_oil_ricevuta_tipo tipo
 where tipo.oil_ricevuta_tipo_code='F'
 and   tipo.ente_proprietario_id=&ente
);

INSERT INTO  siac_d_oil_esito_derivato
(oil_esito_derivato_code,oil_esito_derivato_desc,oil_ricevuta_tipo_id,validita_inizio,ente_proprietario_id,login_operazione)
(select '52','Comunicazione di pagamento/incasso', tipo.oil_ricevuta_tipo_id,'2016-01-01',tipo.ente_proprietario_id,'admin'
 from siac_d_oil_ricevuta_tipo tipo
 where tipo.oil_ricevuta_tipo_code='P'
 and   tipo.ente_proprietario_id=&ente
);

INSERT INTO  siac_d_oil_esito_derivato
( oil_esito_derivato_code,oil_esito_derivato_desc,oil_ricevuta_tipo_id,validita_inizio,ente_proprietario_id,login_operazione)
(select '53','Storno di una comunicazione di pagamento/incasso', tipo.oil_ricevuta_tipo_id,'2016-01-01',tipo.ente_proprietario_id,'admin'
 from siac_d_oil_ricevuta_tipo tipo
 where tipo.oil_ricevuta_tipo_code='PS'
 and   tipo.ente_proprietario_id=&ente
);


-- siac_d_oil_qualificatore
select * from siac_d_oil_qualificatore
where ente_proprietario_id=&ente;

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'PM', 'Pagamento mandato', 'U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='01'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'RM','Regolarizzazione mandato','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='01'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code, oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'SM','Storno mandato','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='51'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'SRM','Storno regolarizzazione mandato','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='51'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code, oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'IR','Pagamento reversale','E',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='01'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'RR','Regolarizzazione reversale','E',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='01'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'SR','Storno reversale','E',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='51'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio, ente_proprietario_id,login_operazione)
(select 'SRR','Storno regolarizzazione reversale','E',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='01'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'FM','Pacchetto di Mandati Firmati','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='00'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code, oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
(select 'FR','Pacchetto di Reversali Firmati','E',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
 from siac_d_oil_esito_derivato d
 where d.oil_esito_derivato_code='00'
 and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
( select 'PSU','Pagamento sospesi uscita','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
  from siac_d_oil_esito_derivato d
  where d.oil_esito_derivato_code='52'
  and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
( select 'SSU','Storno sospesi uscita','U',d.oil_esito_derivato_id,'2016-01-01', d.ente_proprietario_id,'admin'
  from siac_d_oil_esito_derivato d
  where d.oil_esito_derivato_code='53'
  and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
( select 'ISE','Incasso sospesi entrata','E',d.oil_esito_derivato_id, '2016-01-01',d.ente_proprietario_id,'admin'
  from siac_d_oil_esito_derivato d
  where d.oil_esito_derivato_code='52'
  and   d.ente_proprietario_id=&ente
);

insert into siac_d_oil_qualificatore
( oil_qualificatore_code,oil_qualificatore_desc,oil_qualificatore_segno,oil_esito_derivato_id,validita_inizio,ente_proprietario_id,login_operazione)
( select 'SSE','Storno sospesi entrata','E', d.oil_esito_derivato_id,'2016-01-01',d.ente_proprietario_id,'admin'
  from siac_d_oil_esito_derivato d
  where d.oil_esito_derivato_code='53'
  and   d.ente_proprietario_id=&ente
);


-- siac_d_oil_ricevuta_errore

select ente_proprietario_id,count(*)
from siac_d_oil_ricevuta_errore
group by ente_proprietario_id

/*insert into siac_d_oil_ricevuta_errore
(oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione)
(select errore.oil_ricevuta_errore_code, errore.oil_ricevuta_errore_desc,errore.validita_inizio,&ente,errore.login_operazione
 from siac_d_oil_ricevuta_errore errore
 where errore.ente_proprietario_id=&ente_da); */

select count(*) from siac_d_oil_ricevuta_errore
where ente_proprietario_id=&ente;


insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('48','ORDINATIVO NON FIRMATO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('49','ORDINATIVO QUIETANZATO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('58','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO DATA ANNULLAMENTO VALORIZZATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('59','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI INSERIMENTO NUOVO PROVVISORIO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('0','ELABORAZIONE VALIDA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('1','RECORD TESTATA NON PRESENTE',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('2','RECORD CODA NON PRESENTE',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('3','RECORD RICEVUTA NON PRESENTE',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('4','RECORD DETTAGLIO RICEVUTA NON PRESENTE',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('5','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( QUIETANZE )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('6','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( FIRME )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('7','TIPO FLUSSO  NON INDICATO SU RECORD TESTATA ( PROVVISORI CASSA )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('8','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( QUIETANZE )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('9','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( FIRME )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('10','TIPO FLUSSO  NON INDICATO SU RECORD CODA ( PROVVISORI CASSA )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('11','DATA ORA FLUSSO NON PRESENTE SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('12','NUMERO RICEVUTE NON PRESENTE SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('13','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('14','DATA ORA FLUSSO NON PRESENTE SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('15','NUMERO RICEVUTE NON PRESENTE SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('16','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD DI TESTATA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('17','RECORD RICEVUTA SENZA RECORD DI DETTAGLIO ',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('18','RECORD DETTAGLIO RICEVUTA SENZA RECORD DI RIFERIMENTO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('19','TIPO RECORD NON INDICATO O ERRATO SU RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('20','TIPO RECORD NON INDICATO O ERRATO SU DETTAGLIO RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('21','PROGRESSIVO NON VALORIZZATO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('22','DATA O ORA MESSAGGIO NON INDICATO RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('23','ESITO DERIVATO NON INDICATO O NON AMMESSO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('24','DATI ENTE NON PRESENTI O NON VALIDI SU RECORD RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('25','CODICE ESISTO NON POSITIVO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('26','CODICE FUNZIONE NON VALORIZZATO O NON AMMESSO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('27','CODICE QUALIFICATORE NON VALORIZZATO O NON AMMESSO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('28','DATI ORDINATIVO NON INDICATI ( ANNO, NUMERO, DATA PAGAMENTO ) PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('29','ANNO ORDINATIVO NON CORRETTO RISPETTO ANNO BILANCIO CORRENTE PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('30','ORDINATIVO NON ESISTENTE PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('31','ORDINATIVO ANNULLATO PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('32','ORDINATIVO EMESSO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('57','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO PROVVISORIO SOGGETTO INCONGRUENTE',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('33','ORDINATIVO NON TRASMESSO O TRASMESSO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('34','ORDINATIVO FIRMATO IN DATA SUCCESSIVA ALLA DATA DI  RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('35','RECORD DETTAGLIO RICEVUTA CON PROGRESSIVO_RICEVUTA NON VALORIZZATO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('36','RECORD DETTAGLIO RICEVUTA CON NUMERO_RICEVUTA NON VALORIZZATO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('37','RECORD DETTAGLIO RICEVUTA CON IMPORTO_RICEVUTA NON VALORIZZATO O NON VALIDO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('38','TOTALE RICEVUTA SU RECORD DETTAGLIO NEGATIVO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('39','ERRORE IN LETTURA NUMERO RICEVUTA SU RECORD DI DETTAGLIO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('40','ERRORE IN LETTURA IMPORTO ORDINATIVO PER CONFRONTO CON IMPORTO RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('41','ERRORE IN LETTURA QUIETANZA ORDINATIVO IN FASE DI STORNO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('42','TOTALE QUIETANZATO SUPERIORE ALL''IMPORTO DELL''ORDINATIVO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('43','TOTALE QUIETANZATO NEGATIVO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('44','STATO ATTUALE ORDINATIVO NON CONGRUENTE CON L''OPERAZIONE DI AGGIORNAMENTO RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('45','DATI FIRMA NON INDICATI PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('46','ORDINATIVO FIRMATO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('47','ORDINATIVO QUIETANZATO IN DATA ANTECENDENTE ALLA DATA DI RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('50','DATI PROVVISSORIO DI CASSA NON INDICATI ( ANNO NUMERO DATA IMPORTO )',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('51','ANNO PROVVISORIO DI CASSA NON CORRETTO  RISPETTO ANNO BILANCIO CORRENTE PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('52','DATA EMISSIONE PROVVISORIO DI CASSA NON CORRETTA  RISPETTO ALLA DATA DI ELABORAZIONE PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('53','IMPORTO PROVVISORIO DI CASSA NON CORRETTO   PER RICEVUTA',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('54','PROVVISORIO DI CASSA INESISTENTE PER RICEVUTA DI STORNO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('55','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO COLLEGATO A ORDINATIVO',now(),3,'admin');
insert into siac_d_oil_ricevuta_errore (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione) values ('56','PROVVISORIO DI CASSA ESISTENTE PER RICEVUTA DI STORNO IMPORTO DI STORNO SUPERIORE IMPORTO PROVVISORIO',now(),3,'admin');

