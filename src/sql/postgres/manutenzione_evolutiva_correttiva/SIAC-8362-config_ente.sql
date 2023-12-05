/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE TABLE IF NOT EXISTS siac.siac_d_config_tipo (
	config_tipo_code varchar(50) NULL,
	config_tipo_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	CONSTRAINT pk_siac_d_config_tipo PRIMARY KEY (config_tipo_code)
);

INSERT INTO siac_d_config_tipo(config_tipo_code, config_tipo_desc, validita_inizio, login_operazione)
select tmp.code, tmp.descr, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin'
from (values('FEL-DEST', 'codice amministrazione destinataria fel') ,('FEL-NUM','telefono trasmittente fel'), ('FEL-MAIL','email trasmittente fel')) as tmp(code, descr)
where not exists (
select 1
from siac_d_config_tipo da
where da.config_tipo_code = tmp.code
and da.data_cancellazione is null
);


CREATE TABLE IF NOT EXISTS siac.siac_t_config_ente (
	config_ente_id SERIAL,
	config_ente_valore varchar(500),
	config_tipo_code varchar(250),
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NOT NULL,
	CONSTRAINT pk_siac_t_ente_config PRIMARY KEY (config_ente_id),
	CONSTRAINT siac_t_config_ente_siac_d_config_tipo FOREIGN KEY (config_tipo_code) REFERENCES siac.siac_d_config_tipo(config_tipo_code),
	CONSTRAINT siac_t_ente_proprietario_siac_t_ente_config FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'idx_siac_t_config_ente'::text,
  'config_tipo_code, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'siac_t_config_ente_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'siac_t_config_ente_fk_config_tipo_code_idx'::text,
  'config_tipo_code'::text,
  '',
  false
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select 'hd_fatturaelettronica@csi.it',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-MAIL')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select '0113168111',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-NUM')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select '0000000',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-DEST')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);
