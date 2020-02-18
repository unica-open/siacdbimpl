/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 16.05.2017 Sofia - creazione relazioni tra relazione_tipo=CSI e
-- CSI, PI, FA
-- create_table_oil_relaz_tipo_csi_16052017.sql
select *
from siac_d_relaz_tipo tipo
where tipo.ente_proprietario_id=3



drop table siac_d_oil_relaz_tipo
create table siac_d_oil_relaz_tipo (
  oil_relaz_tipo_id SERIAL,
  oil_relaz_tipo_code VARCHAR(200) NOT NULL,
  oil_relaz_tipo_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_oil_relaz_tipo PRIMARY KEY(oil_relaz_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_oil_relaz_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_oil_relaz_tipo_1 ON siac_d_oil_relaz_tipo
  USING btree (oil_relaz_tipo_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


drop table siac_r_oil_relaz_tipo;
CREATE TABLE siac_r_oil_relaz_tipo (
  oil_relaz_tipo_rel_id SERIAL,
  relaz_tipo_id INTEGER,
  oil_relaz_tipo_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_oil_relaz_tipo PRIMARY KEY(oil_relaz_tipo_rel_id),
  CONSTRAINT siac_d_relaz_tipo_siac_r_oil_relaz_tipo FOREIGN KEY (relaz_tipo_id)
    REFERENCES siac_d_relaz_tipo(relaz_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_oil_relaz_tipo_siac_r_oil_relaz_tipo FOREIGN KEY (oil_relaz_tipo_id)
    REFERENCES siac_d_oil_relaz_tipo(oil_relaz_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_oil_relaz_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);




insert into siac_d_oil_relaz_tipo
(
  oil_relaz_tipo_code,
  oil_relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 'CSI',
 'CESSIONE INCASSO',
 '2017-01-01'::timestamp,
 3,
 'admin'
);

insert into siac_d_oil_relaz_tipo
(
  oil_relaz_tipo_code,
  oil_relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
 'CSC',
 'CESSIONE CREDITO',
 '2017-01-01'::timestamp,
 3,
 'admin'
);


insert into siac_r_oil_relaz_tipo
(
	oil_relaz_tipo_id,
    relaz_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select  oiltipo.oil_relaz_tipo_id,
        tipo.relaz_tipo_id,
        '2017-01-01'::timestamp,
        'admin',
        tipo.ente_proprietario_id
from siac_d_oil_relaz_tipo oiltipo, siac_d_relaz_tipo tipo
where oiltipo.ente_proprietario_id=3
and   oiltipo.oil_relaz_tipo_code='CSI'
and   tipo.ente_proprietario_id=oiltipo.ente_proprietario_id
and   tipo.relaz_tipo_code in ('CSI','PI','FA')

select tipo.relaz_tipo_code, tipo.relaz_tipo_desc
from siac_r_oil_relaz_tipo r, siac_d_relaz_tipo tipo, siac_d_oil_relaz_tipo oil
where oil.ente_proprietario_id=3
and   oil.oil_relaz_tipo_code='CSI'
and   r.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
and   tipo.relaz_tipo_id=r.relaz_tipo_id



begin;
insert into siac_d_oil_relaz_tipo
(
  oil_relaz_tipo_code,
  oil_relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select  'CSI',
		'CESSIONE INCASSO',
	    '2017-01-01'::timestamp,
	    e.ente_proprietario_id,
	    'admin'
from siac_t_ente_proprietario e
where  not exists (select 1 from siac_d_oil_relaz_tipo tipo
                   where tipo.ente_proprietario_id=e.ente_proprietario_id
                   and   tipo.oil_relaz_tipo_code='CSI'
	              );

insert into siac_d_oil_relaz_tipo
(
  oil_relaz_tipo_code,
  oil_relaz_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select  'CSC',
		'CESSIONE CREDITO',
	    '2017-01-01'::timestamp,
	    e.ente_proprietario_id,
	    'admin'
from siac_t_ente_proprietario e
where  not exists (select 1 from siac_d_oil_relaz_tipo tipo
                   where tipo.ente_proprietario_id=e.ente_proprietario_id
                   and   tipo.oil_relaz_tipo_code='CSC'
	              );

begin;
delete from siac_r_oil_relaz_tipo r
where r.ente_proprietario_id!=3;

begin;
insert into siac_r_oil_relaz_tipo
(
	oil_relaz_tipo_id,
    relaz_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select  oiltipo.oil_relaz_tipo_id,
        tipo.relaz_tipo_id,
        '2017-01-01'::timestamp,
        'admin',
        tipo.ente_proprietario_id
from siac_t_ente_proprietario e, siac_d_oil_relaz_tipo oiltipo, siac_d_relaz_tipo tipo
where oiltipo.ente_proprietario_id=e.ente_proprietario_id
and   oiltipo.oil_relaz_tipo_code='CSI'
and   tipo.ente_proprietario_id=oiltipo.ente_proprietario_id
and   tipo.relaz_tipo_code in ('CSI','PI','FA')
and   not exists ( select 1 from siac_r_oil_relaz_tipo r
                   where r.relaz_tipo_id=tipo.relaz_tipo_id
                   and   r.oil_relaz_tipo_id=oiltipo.oil_relaz_tipo_id
                   and   r.data_cancellazione is null
                   and   r.validita_fine is null
                 )


------------
select rmdp.*
from siac_t_bil bil,siac_t_periodo per,
     siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_modpag rmdp, siac_r_soggrel_modpag r,
     siac_r_soggetto_relaz rel, siac_d_relaz_tipo reltipo
where bil.ente_proprietario_id=3
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2017
and   ord.bil_id=bil.bil_id
and   tipo.ord_tipo_id=ord.ord_tipo_id
and   tipo.ord_tipo_code='P'
--and   ord.ord_numero=2604
and   rmdp.ord_id=ord.ord_id
and   r.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   rel.soggetto_relaz_id=r.soggetto_relaz_id
and   reltipo.relaz_tipo_id=rel.relaz_tipo_id
and   reltipo.relaz_tipo_code='CSI'
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rel.data_cancellazione is null
and   rel.validita_fine is null


