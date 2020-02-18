/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select mif.flusso_elab_mif_code,
       mif.flusso_elab_mif_desc,
       mif.flusso_elab_mif_code_padre,
       mif.flusso_elab_mif_ordine,
       mif.flusso_elab_mif_ordine_elab,
       mif.flusso_elab_mif_elab,
       mif.flusso_elab_mif_attivo,
       mif.flusso_elab_mif_xml_out,
       mif.flusso_elab_mif_default,
       mif.flusso_elab_mif_param
from mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato mif
where tipo.ente_proprietario_id=4
and   tipo.flusso_elab_mif_tipo_code='INVIO_AVVISO_EMAIL_BONIF'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_attivo=true
order by mif.flusso_elab_mif_ordine


select mif.*
from  mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=4
and   mif.flusso_elab_mif_attivo=true
and   exists ( select 1 from mif_d_flusso_elaborato_tipo tipo
			   where tipo.ente_proprietario_id=mif.ente_proprietario_id
               and   tipo.flusso_elab_mif_tipo_code='INVIO_AVVISO_EMAIL_BONIF'
               and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
		     )
order by mif.flusso_elab_mif_ordine


select  * from mif_d_flusso_elaborato
where ente_proprietario_id=4
and   flusso_elab_mif_code like '%Email_Bonif'

update mif_d_flusso_elaborato set flusso_elab_mif_tipo_id=171
where ente_proprietario_id=4
and   flusso_elab_mif_code like '%Email_Bonif'

select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=4


insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code,flusso_elab_mif_tipo_desc,flusso_elab_mif_nome_file,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
 )
 values
 ('INVIO_AVVISO_EMAIL_BONIF','INVIO AVVISO VIA EMAIL PER PAGAMENTI SU BONIFICI AVVENUTI','NO_FILE',
  '2017-01-01','admin',4
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Oggetto_Email_Bonif','Oggetto della email per avviso pagamento bonifico',
  'Oggetto_Email_Bonif',
  1,1,
  true,true,false,
  null,
  null,
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Ente_Oggetto_Email_Bonif','Ente destinatario email',
  'Oggetto_Email_Bonif',
  2,2,
  true,true,
  'REGIONE PIEMONTE -',
  null,
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Avviso_Oggetto_Email_Bonif','Descrizione avviso email',
  'Oggetto_Email_Bonif',
  3,3,
  true,true,
  'Avviso di Bonifico - Ordinativo N. ',
  'ord_numero',
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Testo_Email_Bonif','Testo della email per avviso pagamento bonifico',
  'Testo_Email_Bonif',
  4,4,
  true,true,false,
  null,
  null,
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Mittente_Testo_Email_Bonif','Mittente avviso email',
  'Testo_Email_Bonif',
  5,5,
  true,true,
  'Ragioneria.avvisi@regione.piemonte.it',
  null,
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Importo_Testo_Email_Bonif','Testo per importo pagato per avviso email',
  'Testo_Email_Bonif',
  6,6,
  true,true,
  'Si comunica che e'' stato disposto il pagamento della somma di ',
  'ord_importo',
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Causale_Testo_Email_Bonif','Testo per causale pagamento per avviso email',
  'Testo_Email_Bonif',
  7,7,
  true,true,
  'per la seguente causale : ',
  'ord_desc',
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('ModPag_Testo_Email_Bonif','Testo per modalita'' pagamento per avviso email',
  'Testo_Email_Bonif',
  8,8,
  true,true,
  'con la seguente modalita'' : ',
  'accredito_tipo_desc',
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Iban_Testo_Email_Quiet_Bonif','Testo per modalita'' pagamento IBAN per avviso email',
  'Testo_Email_Bonif',
  9,9,
  true,true,
  'IBAN :',
  null,
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Fatture_Testo_Email_Bonif','Fatture collegate a pagamento per avviso email',
  'Testo_Email_Bonif',
  10,10,
  true,true,
  'Fatture collegate al mandato:',
  'Anno Tipo   Emessa    Numero/Quota                       Importo',
  '2017-01-01',
  4,
  'admin'
 );

insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Nota_Testo_Email_Bonif','Testo per saluti per avviso email',
  'Testo_Email_Bonif',
  11,11,
  true,true,
  'Cordiali saluti.',
  null,
  '2017-01-01',
  4,
  'admin'
 );


 insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Ente_Coda_Testo_Email_Bonif','Testo per coda (ente) per avviso email',
  'Testo_Email_Bonif',
  12,12,
  true,true,
  'Regione Piemonte. Direzione Risorse Finanziarie - Settore Ragioneria.',
  null,
  '2017-01-01',
  4,
  'admin'
 );

  insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Sede_Ente_Coda_Testo_Email_Bonif','Testo per coda (sede) per avviso email',
  'Testo_Email_Bonif',
  13,13,
  true,true,
  'Piazza Castello 165 - 10122 Torino',
  null,
  '2017-01-01',
  4,
  'admin'
 );


  insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Tel_Ente_Coda_Testo_Email_Bonif','Testo per coda (telefono) per avviso email',
  'Testo_Email_Bonif',
  14,14,
  true,true,
  'Tel. 800 333 444',
  null,
  '2017-01-01',
  4,
  'admin'
 );

-- da lasciare poi disattivo
insert into  mif_d_flusso_elaborato
(  flusso_elab_mif_code,flusso_elab_mif_desc,
   flusso_elab_mif_code_padre,
   flusso_elab_mif_ordine, flusso_elab_mif_ordine_elab,
   flusso_elab_mif_elab,flusso_elab_mif_attivo,
   flusso_elab_mif_default,
   flusso_elab_mif_param,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 values
 ('Codfisc_Ente_Coda_Testo_Email_Bonif','Testo per coda (codice fiscale) per avviso email',
  'Testo_Email_Bonif',
  15,15,
  true,true,
  '999999999999999',
  null,
  '2017-01-01',
  4,
  'admin'
 );


select * from mif_t_oil_ricevuta_invio_email


create table mif_t_oil_ricevuta_invio_email
 (
  oil_ricevuta_email_id SERIAL,
  flusso_elab_mif_id INTEGER NOT NULL,
  flusso_elab_mif_quiet_id integer not null,
  oil_ricevuta_id    INTEGER NOT NULL,
  oil_ricevuta_data  TIMESTAMP WITHOUT TIME ZONE,
  ord_id             INTEGER NOT NULL,
  ord_anno           INTEGER NOT NULL,
  ord_numero         INTEGER NOT NULL,
  ord_importo        numeric not null,
  ord_desc           varchar(500) not null,
  soggetto_id        integer not null,
  modpag_id          integer not null,
  accredito_tipo_id  integer not null,
  accredito_tipo_code varchar(10) not null,
  accredito_tipo_desc varchar(500) not null,
  codice_iban         varchar(50) not null,
  codice_email        varchar(100) not null,
  mittente_email      varchar(100) not null,
  oggetto_email       varchar(2000) not null,
  testo_email         text   not null,
  oil_ricevuta_email_invio boolean DEFAULT false not null,
  oil_ricevuta_email_data_invio TIMESTAMP WITHOUT TIME ZONE,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_mif_t_oil_ricevuta_invio_email PRIMARY KEY(oil_ricevuta_email_id),
  CONSTRAINT mif_t_flusso_elaborato_mif_t_oil_ricevuta_invio_email FOREIGN KEY (flusso_elab_mif_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_oil_ricevuta_mif_t_oil_ricevuta_invio_email FOREIGN KEY (oil_ricevuta_id)
    REFERENCES siac_t_oil_ricevuta(oil_ricevuta_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ordinativo_mif_t_oil_ricevuta_invio_email FOREIGN KEY (ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_soggetto_mif_t_oil_ricevuta_invio_email FOREIGN KEY (soggetto_id)
    REFERENCES siac_t_soggetto(soggetto_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_modpag_mif_t_oil_ricevuta_invio_email FOREIGN KEY (modpag_id)
    REFERENCES siac_t_modpag(modpag_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_accredito_tipo_mif_t_oil_ricevuta_invio_email FOREIGN KEY (accredito_tipo_id)
    REFERENCES siac_d_accredito_tipo(accredito_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_mif_t_oil_ricevuta_invio_email FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT mif_t_flusso_elaborato_mif_t_flusso_elaborato_quiet FOREIGN KEY (flusso_elab_mif_quiet_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_oil_ricevuta_invio_email
IS 'Tabella di elaborazione invio email per avviso pagamenti.';


alter table siac_t_ente_oil add ente_oil_invio_email_cb boolean default false not null;

select * from siac_t_ente_oil  where ente_proprietario_id=4

update siac_t_ente_oil set ente_oil_invio_email_cb=true where ente_proprietario_id=4;



alter table mif_t_flusso_elaborato add flusso_elab_mif_quiet_id integer null;

alter table mif_t_flusso_elaborato add
  CONSTRAINT mif_t_flusso_elaborato_mif_t_flusso_elaborato_quiet FOREIGN KEY (flusso_elab_mif_quiet_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE