/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_movgest_ts_det_mod', 'mtdm_aggiudicazione_flag', 'boolean');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_movgest_ts_det_mod', 'mtdm_aggiudicazione_soggetto_id', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_movgest_ts_det_mod', 'mtdm_aggiudicazione_classe_id', 'integer');

SELECT * FROM  fnc_dba_add_fk_constraint ( 'siac_t_movgest_ts_det_mod', 'siac_t_soggetto_siac_t_movgest_ts_dmod_id', 'mtdm_aggiudicazione_soggetto_id', 'siac_t_soggetto', 'soggetto_id');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'siac_t_movgest_ts_det_mod', 'siac_d_soggetto_cl_siac_t_movgest_ts_dmod_id', 'mtdm_aggiudicazione_classe_id', 'siac_d_soggetto_classe', 'soggetto_classe_id');

CREATE TABLE IF NOT EXISTS siac_r_movgest_aggiudicazione
( movgest_aggiudicazione_r_id SERIAL,
	movgest_id_da integer NOT NULL,
	movgest_id_a integer NOT NULL,
	attoamm_id integer NOT NULL,
	mod_id integer NOT NULL,
	validita_inizio timestamp without time zone NOT NULL,
    validita_fine timestamp without time zone,
    ente_proprietario_id integer NOT NULL,
    data_creazione timestamp without time zone NOT NULL DEFAULT now(),
    data_modifica timestamp without time zone NOT NULL DEFAULT now(),
    data_cancellazione timestamp without time zone,
    login_operazione character varying(200) NOT null,
CONSTRAINT siac_r_movgest_aggiudicazione_id PRIMARY KEY(movgest_aggiudicazione_r_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_movgest_ag FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_da_siac_r_movgest_ag FOREIGN KEY (movgest_id_da)
    REFERENCES siac.siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_movgest_ts_a_siac_r_movgest_ag FOREIGN KEY (movgest_id_a)
    REFERENCES siac.siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_attoamm_siac_r_movgest_ag FOREIGN KEY (attoamm_id)
    REFERENCES siac.siac_t_atto_amm(attoamm_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT siac_t_modifica_siac_r_movgest_ag FOREIGN KEY (mod_id)
    REFERENCES siac.siac_t_modifica(mod_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);


INSERT INTO siac_t_attr
(
	attr_code,
	attr_desc,
	attr_tipo_id,
	validita_inizio,
	ente_proprietario_id,
	login_operazione
)
select
		'annoPrenotazioneOrigine' ,
		'Anno di origine della prenotazione',
		tipo.attr_tipo_id,
		now(),
		ente.ente_proprietario_id,
		'SIAC-6868'
from  siac_t_ente_proprietario ente,
      siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='X'
and   not exists
(
select 1
from siac_t_attr attr
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_tipo_id=tipo.attr_tipo_id
and   attr.attr_code='annoPrenotazioneOrigine'
and   attr.data_cancellazione is null
);

insert into siac_d_modifica_tipo
(
  mod_tipo_code,
  mod_tipo_desc,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select 'AGG',
       'Aggiudicazione',
       'SIAC-6865',
       now(),
	   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo dbt
	WHERE dbt.ente_proprietario_id = ente.ente_proprietario_id
	AND dbt.mod_tipo_id=(SELECT mod_tipo_id
	 FROM siac_d_modifica_tipo
	 WHERE mod_tipo_code=TRIM('AGG')  AND ente_proprietario_id=ente.ente_proprietario_id )
);


-- siac_dwh_impegno
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'annoprenotazioneorigine', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'anno_impegno_aggiudicazione', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'num_impegno_aggiudicazione', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'num_modif_aggiudicazione', 'integer');