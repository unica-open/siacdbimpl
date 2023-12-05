/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * from fnc_dba_add_column_params ('siac_t_file_pagopa' , 'file_pagopa_id_psp', 'varchar');
SELECT * from fnc_dba_add_column_params ('siac_t_file_pagopa', 'file_pagopa_id_flusso', 'varchar');




﻿SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_tipo_code' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_tipo_id' , 'integer');


---	Ragione Sociale
---	Cognome
---	Nome
---	Identificativo Fiscale

SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione', 'pagopa_ric_flusso_ragsoc_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione', 'pagopa_ric_flusso_nome_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione', 'pagopa_ric_flusso_cognome_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione', 'pagopa_ric_flusso_codfisc_benef' , 'varchar');


SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_ragsoc_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_nome_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_cognome_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_codfisc_benef' , 'varchar');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_soggetto_id' , 'integer');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_flag_dett' , 'boolean not null default FALSE');
SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_flag_con_dett' , 'boolean not null default FALSE');

SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_det_id' , 'integer');

SELECT * from fnc_dba_add_fk_constraint ( 'pagopa_t_riconciliazione_doc',
                            'siac_d_doc_tipo_pagopa_t_riconciliazione_doc',
                            'pagopa_ric_doc_tipo_id',
  					        'siac_d_doc_tipo',
  							'doc_tipo_id'
						   );

SELECT * from fnc_dba_add_fk_constraint ( 'pagopa_t_riconciliazione_doc',
                            'siac_t_soggetto_pagopa_t_riconciliazione_doc',
                            'pagopa_ric_doc_soggetto_id',
  					        'siac_t_soggetto',
  							'soggetto_id'
						   );



SELECT * from fnc_dba_add_fk_constraint ( 'pagopa_t_riconciliazione_doc',
                            'pagopa_t_det_pagopa_t_riconciliazione_doc',
                            'pagopa_ric_det_id',
  					        'pagopa_t_riconciliazione_det',
  							'pagopa_ric_det_id'
						   );

CREATE TABLE pagopa_t_modifica_elab
(
  pagopa_modifica_elab_id SERIAL,
  pagopa_elab_id integer not null,
  subdoc_id INTEGER  null,
  mod_id    integer not null,
  movgest_ts_id integer,
  pagopa_modifica_elab_importo numeric not null,
  pagopa_modifica_elab_note    varchar(200) null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_modifica_elab PRIMARY KEY(pagopa_modifica_elab_id),
  CONSTRAINT pagopa_t_elab_t_modifica_elab FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_subdoc_pagopa_t_modifica_elab FOREIGN KEY (subdoc_id)
    REFERENCES siac_t_subdoc(subdoc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_pagopa_t_modifica_elab FOREIGN KEY (movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_modifica_pagopa_t_modifica_elab FOREIGN KEY (mod_id)
    REFERENCES siac_t_modifica(mod_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,

  CONSTRAINT siac_t_ente_proprietario_pagopa_t_modifica_elab FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_t_modifica_elab
IS 'Tabella di elaborazione modifiche accertamenti PAGOPO ';



CREATE INDEX pagopa_t_modifica_elab_fk_ente_proprietario_id_idx ON pagopa_t_modifica_elab
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_modifica_elab_fk_pagopa_elab_id_idx ON pagopa_t_modifica_elab
  USING btree (pagopa_elab_id);


CREATE INDEX pagopa_t_modifica_elab_movgest_ts_id_idx ON pagopa_t_modifica_elab
  USING btree (movgest_ts_id);

CREATE INDEX pagopa_t_modifica_elab_subdoc_id_idx ON pagopa_t_modifica_elab
  USING btree (subdoc_id);

CREATE INDEX pagopa_t_modifica_elab_mod_id_idx ON pagopa_t_modifica_elab
  USING btree (mod_id);


insert into siac_t_attr
(
  attr_code,
  attr_desc,
  attr_tipo_id,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select 'FlagCollegamentoAccertamentoCorrispettivo',
       'FlagCollegamentoAccertamentoCorrispettivo',
       tipo.attr_tipo_id,
       'SIAC-6720',
       now(),
	   tipo.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_attr_tipo tipo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   tipo.ente_proprietario_id =ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and not exists
(
select 1
from siac_t_attr attr
where  attr.ente_proprietario_id=ente.ente_proprietario_id
and    attr.attr_tipo_id=tipo.attr_tipo_id
and    attr.attr_code='FlagCollegamentoAccertamentoCorrispettivo'
and    attr.data_cancellazione is null
and    attr.validita_fine is null
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '41',
   'ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO-FATTURA',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='41'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '42',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='42'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '43',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='43'
);
insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '44',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='44'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '45',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO (P.IVA)',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='45'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '46',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='46'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '47',
   'ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='47'
);


insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '48',
   'TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='48'
);

insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '49',
   'DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='49'
);



insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
   '50',
   'DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO',
   now(),
   'SIAC-6720',
   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16,29)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='50'
);