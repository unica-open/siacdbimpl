/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


create table if not exists siac_t_saldo_vincolo_sotto_conto_elab(
	saldo_vincolo_conto_el_id serial NOT NULL,
	vincolo_id integer NOT NULL,
	contotes_id integer NOT NULL,
	saldo_iniziale numeric NULL,
	saldo_finale numeric NULL,
    ripiano_iniziale numeric NULL,
	ripiano_finale numeric NULL,
	bil_id integer NOT NULL,
	tipo_caricamento varchar(1) not null,
	saldo_vincolo_conto_elab_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_elab_pk PRIMARY KEY (saldo_vincolo_conto_el_id),
	CONSTRAINT siac_d_contotesoreria_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_bil_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_el_siac_t_vincolo FOREIGN KEY (vincolo_id) REFERENCES siac.siac_t_vincolo(vincolo_id)
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_vincolo_id_idx'::text,
  'vincolo_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_contotes_id'::text,
  'contotes_id'::text,
  '',
  false
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_elab_id_idx'::text,
  'saldo_vincolo_conto_elab_id'::text,
  '',
  false
);


create table if not exists siac_t_saldo_vincolo_sotto_conto_da_file
(
	saldo_vincolo_conto_da_file_id serial NOT NULL,
	vincolo_code varchar(200) NOT NULL,
	conto_code varchar(200) NOT NULL,
	saldo_iniziale numeric NULL,
	saldo_finale   numeric NULL,
	ripiano_iniziale numeric NULL,
	ripiano_finale numeric NULL,
	anno_bilancio_iniziale integer,
	anno_bilancio_finale   integer,
	tipo_caricamento varchar(10) not null,
	fl_caricato varchar(1) default 'N' not null,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_da_f_pk PRIMARY KEY (saldo_vincolo_conto_da_file_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_saldo_vincolo_sotto_conto_da_f FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_da_file'::text,
  'siac_t_saldo_vincolo_sotto_conto_da_f_fk_ente_propr_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);


insert into siac_d_gestione_tipo 
(
	gestione_tipo_code,
	gestione_tipo_desc,
	validita_inizio,
	login_operazione,
	ente_proprietario_id 
)
select 'SALDO_SOTTO_CONTI_VINC',
       'Calcolo saldo sotto conti vincolati',
       now(),
       'SIAC-8017-CMTO',
       ente.ente_proprietario_id 
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id =3
	

insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'GEST_SALDO_SOTTO_CONTI_VINC',
       'Calcolo automatico finale-iniziali in ape gestione',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017-CMTO',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC';


insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC',
       'Aggiornamento automatico saldi iniziali',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017-CMTO',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC';

insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'AGGIORNA_FINAL_SALDO_SOTTO_CONTI_VINC',
       'Aggiornamento automatico saldi finali',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017-CMTO',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC';
