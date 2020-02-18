/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table SIAC_R_MOVGEST_TS_STORICO_IMP_ACC;
CREATE TABLE SIAC_R_MOVGEST_TS_STORICO_IMP_ACC
(
  movgest_ts_r_storico_id SERIAL,
  movgest_ts_id INTEGER,
  movgest_anno_acc integer,
  movgest_numero_acc integer,
  movgest_subnumero_acc integer	,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_movgest_ts_storico PRIMARY KEY(movgest_ts_r_storico_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_movgest_ts_st FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_siac_r_movgest_ts_st FOREIGN KEY (movgest_ts_id)
    REFERENCES siac.siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_r_movgest_ts_storico_1 ON siac_r_movgest_ts_storico_imp_acc
  USING btree (movgest_anno_acc, movgest_numero_acc, movgest_subnumero_acc, movgest_ts_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE INDEX idx_siac_r_movgest_ts_storico_2 ON siac_r_movgest_ts_storico_imp_acc
  USING btree ( movgest_ts_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX idx_siac_r_movgest_ts_storico_3 ON siac_r_movgest_ts_storico_imp_acc
  USING btree (movgest_anno_acc, movgest_numero_acc, movgest_subnumero_acc, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_r_movgest_ts_st_fk_ente_proprietario_id_idx ON siac.siac_r_movgest_ts_storico_imp_acc
  USING btree (ente_proprietario_id);
  
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select 'OP-SPE-gestisciStoricoImpAcc', 'Gestisci legami storici', ta.azione_tipo_id, ga.gruppo_azioni_id,
 '/../siacfinapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'),
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = 'ATTIVITA_SINGOLA'
  and ga.gruppo_azioni_code = 'FIN_BASE1'
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code='OP-SPE-gestisciStoricoImpAcc')
  ;
  