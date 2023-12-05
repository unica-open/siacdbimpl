/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- mif_d_flusso_elaborato_tipo
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

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc, oil_ricevuta_tipo_code_fl, validita_inizio,ente_proprietario_id,login_operazione)
select tipo.oil_ricevuta_tipo_code,tipo.oil_ricevuta_tipo_desc, tipo.oil_ricevuta_tipo_code_fl, tipo.validita_inizio,
       &ente_a,tipo.login_operazione
from siac_d_oil_ricevuta_tipo tipo
where tipo.ente_proprietario_id=&ente_da;

/*insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code, oil_ricevuta_tipo_desc, oil_ricevuta_tipo_code_fl, validita_inizio, ente_proprietario_id, login_operazione)
values
( 'F','Firma ordinativo', 'S', '2016-01-01',&ente,'admin');

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,ente_proprietario_id,login_operazione)
values
( 'P','Provvisorio di cassa','P','2016-01-01',&ente,'admin');

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code, oil_ricevuta_tipo_desc, oil_ricevuta_tipo_code_fl, validita_inizio, ente_proprietario_id, login_operazione)
values
( 'Q','Quietanza ordinativo','R','2016-01-01',&ente,'admin');

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc,oil_ricevuta_tipo_code_fl,validita_inizio,ente_proprietario_id,login_operazione)
values
( 'S','Storno quietanza ordinativo','R','2016-01-01',&ente,'admin');

insert into siac_d_oil_ricevuta_tipo
( oil_ricevuta_tipo_code,oil_ricevuta_tipo_desc, oil_ricevuta_tipo_code_fl, validita_inizio,ente_proprietario_id,login_operazione)
values
( 'PS', 'Storno Provvisorio di cassa','P','2016-01-01',&ente,'admin');*/

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

insert into siac_d_oil_ricevuta_errore
(oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione)
(select errore.oil_ricevuta_errore_code, errore.oil_ricevuta_errore_desc,errore.validita_inizio,&ente,errore.login_operazione
 from siac_d_oil_ricevuta_errore errore
 where errore.ente_proprietario_id=&ente_da);

select count(*) from siac_d_oil_ricevuta_errore
where ente_proprietario_id=&ente;
/*select
'insert into siac_d_oil_ricevuta_errore
 (oil_ricevuta_errore_code, oil_ricevuta_errore_desc,validita_inizio,ente_proprietario_id,login_operazione )
 values ( '
 ||quote_nullable(e.oil_ricevuta_errore_code)||','
 ||quote_nullable(e.oil_ricevuta_errore_desc)||','
 ||quote_nullable('2015-01-01')||','
 ||e.ente_proprietario_id||','
 ||quote_nullable(e.login_operazione)||');'
from siac_d_oil_ricevuta_errore e
where ente_proprietario_id=15*/