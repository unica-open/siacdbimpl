/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 20.02.2018 Sofia siac-5849

create table siac_d_oil_natura_spesa
(
	oil_natura_spesa_id   serial,
    oil_natura_spesa_code varchar,
    oil_natura_spesa_desc varchar,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL
);

create table siac_r_oil_natura_spesa_titolo
(
	oil_natura_spesa_rel_id    serial,
    oil_natura_spesa_id        integer,
    oil_natura_spesa_titolo_id integer,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
	login_operazione VARCHAR(200) NOT NULL
);

insert into siac_d_oil_natura_spesa
(oil_natura_spesa_code,oil_natura_spesa_desc,validita_inizio,login_operazione,ente_proprietario_id)
values
('1','CORRENTE',now(),'admin-siope+',2);

insert into siac_d_oil_natura_spesa
(oil_natura_spesa_code,oil_natura_spesa_desc,validita_inizio,login_operazione,ente_proprietario_id)
values
('2','CAPITALE',now(),'admin-siope+',2);

insert into siac_r_oil_natura_spesa_titolo
(
	oil_natura_spesa_id,
    oil_natura_spesa_titolo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select oil.oil_natura_spesa_id,
       c.classif_id,
       now(),
       'admin-siope+',
       tipo.ente_proprietario_id
from siac_d_oil_natura_spesa oil , siac_t_class c ,siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='TITOLO_SPESA'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.classif_code in ('1','4')
and   oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_natura_spesa_code='1';

select *
from siac_r_oil_natura_spesa_titolo



select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='CAPITALE',
       flusso_elab_mif_param=null
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='CAPITALE',
       flusso_elab_mif_param='MACROAGGREGATO|Spesa - TitoliMacroaggregati'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='natura_spesa_siope'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

alter table if exists mif_r_conto_tesoreria_vincolato
 alter column vincolato TYPE varchar(50);
begin;
update mif_r_conto_tesoreria_vincolato  r
set    vincolato='LIBERA'
where  vincolato='LIBERO';
update mif_r_conto_tesoreria_vincolato  r
set    vincolato='VINCOLATA'
where  vincolato='VINCOLATO';


select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='destinazione'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
rollback;
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_attivo=true,
       flusso_elab_mif_xml_out=true
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='destinazione'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_attivo=true,
       flusso_elab_mif_xml_out=true
where mif.flusso_elab_mif_code='destinazione'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
and   exists
(
select 1 from  siac_r_sistema_esterno_ente r
where r.ente_proprietario_id=mif.ente_proprietario_id
and   r.extsys_ente_code='CMTO'
);
