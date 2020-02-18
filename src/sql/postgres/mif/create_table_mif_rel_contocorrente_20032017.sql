/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/**
Descrizione
Sirichiede di impostare, ove non diversamente specificato dall'utente, questi default per i flag in oggetto:

in base al sottoconto (conto tesoreria) impostare i dati di fruttifero e vincolato.
conto 100 -- fruttifero/libero
conto 110/120/130/140/301 -- infruttifero/vincolato
conto 210/9201/9301 -- fruttifero/vincolato

Se il sottoconto non fosse presente lasciare i default attuali.


Grazie

*/

select *
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=3
and   exists ( select 1 from mif_d_flusso_elaborato_tipo tipo
               where tipo.ente_proprietario_id=mif.ente_proprietario_id
               and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
               and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
             )
and  mif.flusso_elab_mif_code='destinazione_ente_pagante'
order by mif.flusso_elab_mif_ordine


select *
from siac_d_contotesoreria c
where c.ente_proprietario_id=3



create table mif_r_conto_tesoreria_fruttifero
(
 mif_contotes_frut_id serial,
 contotes_id          integer not null,
 fruttifero           char not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine TIMESTAMP WITHOUT TIME ZONE,
 ente_proprietario_id INTEGER,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_r_conto_tesoreria_fruttifero PRIMARY KEY(mif_contotes_frut_id),
  CONSTRAINT siac_t_ente_proprietario_mif_r_conto_tesoreria_fruttifero FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_contotesoreria_mif_r_conto_tesoreria_fruttifero FOREIGN KEY (contotes_id)
    REFERENCES siac_d_contotesoreria(contotes_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table mif_r_conto_tesoreria_vincolato
(
 mif_contotes_vinc_id serial,
 contotes_id          integer not null,
 vincolato            char not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine TIMESTAMP WITHOUT TIME ZONE,
 ente_proprietario_id INTEGER,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_r_conto_tesoreria_vincolato PRIMARY KEY(mif_contotes_vinc_id),
  CONSTRAINT siac_t_ente_proprietario_mif_r_conto_tesoreria_vincolato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_contotesoreria_mif_r_conto_tesoreria_vincolato FOREIGN KEY (contotes_id)
    REFERENCES siac_d_contotesoreria(contotes_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


-- conto 100 -- fruttifero/libero
insert into mif_r_conto_tesoreria_fruttifero
(contotes_id,
 fruttifero,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'F',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code like '%100'

insert into mif_r_conto_tesoreria_vincolato
(contotes_id,
 vincolato,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'L',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code like '%100'

-- conto 110/120/130/140/301 -- infruttifero/vincolato
insert into mif_r_conto_tesoreria_fruttifero
(contotes_id,
 fruttifero,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'I',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (110,120,130,140,301)


insert into mif_r_conto_tesoreria_vincolato
(contotes_id,
 vincolato,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'V',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (110,120,130,140,301)


-- conto 201/9201/9301 -- fruttifero/vincolato
insert into mif_r_conto_tesoreria_fruttifero
(contotes_id,
 fruttifero,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'F',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (9201,9301)

insert into mif_r_conto_tesoreria_fruttifero
(contotes_id,
 fruttifero,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'F',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (210)

insert into mif_r_conto_tesoreria_vincolato
(contotes_id,
 vincolato,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'V',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (9201,9301)

insert into mif_r_conto_tesoreria_vincolato
(contotes_id,
 vincolato,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select conto.contotes_id,
       'V',
       '2017-01-01',
       'admin',
       conto.ente_proprietario_id
from siac_d_contotesoreria conto
where conto.ente_proprietario_id=3
and   conto.contotes_code::integer in (210)

select d.contotes_code, r.vincolato
from mif_r_conto_tesoreria_vincolato r, siac_d_contotesoreria d
where d.ente_proprietario_id=3
and   r.contotes_id=d.contotes_id

select d.contotes_code, r.fruttifero
from mif_r_conto_tesoreria_fruttifero r, siac_d_contotesoreria d
where d.ente_proprietario_id=3
and   r.contotes_id=d.contotes_id



select *
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=3
and   exists ( select 1 from mif_d_flusso_elaborato_tipo tipo
               where tipo.ente_proprietario_id=mif.ente_proprietario_id
               and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
               and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
             )
and  mif.flusso_elab_mif_code='Vincolato'
order by mif.flusso_elab_mif_ordine


select *
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=3
and   exists ( select 1 from mif_d_flusso_elaborato_tipo tipo
               where tipo.ente_proprietario_id=mif.ente_proprietario_id
               and   tipo.flusso_elab_mif_tipo_code='REVMIF'
               and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
             )
--and  mif.flusso_elab_mif_code='Vincolato'
order by mif.flusso_elab_mif_ordine