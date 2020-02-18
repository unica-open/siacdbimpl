/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac_r_bil_elem_fpv
(
  elem_fpv_r_id SERIAL,
  elem_id INTEGER,
  elem_fpv_id INTEGER NOT NULL,
  elem_fpv_importo NUMERIC,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_bil_elem_fpv PRIMARY KEY(elem_fpv_r_id),
  CONSTRAINT siac_t_ente_proprietario_siac_r_bil_elem_fpv FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv FOREIGN KEY (elem_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv_1 FOREIGN KEY (elem_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_siac_r_bil_elem_fpv_2 FOREIGN KEY (elem_fpv_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_r_bil_elem_fpv_1 ON siac.siac_r_bil_elem_fpv
  USING btree (elem_id, elem_fpv_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_r_bil_elem_fpv_fk_ente_proprietario_id_idx ON siac.siac_r_bil_elem_fpv
  USING btree (ente_proprietario_id);

CREATE INDEX siac_r_bil_elem_fpv_fk_bil_elem_id_idx ON siac.siac_r_bil_elem_fpv
  USING btree (elem_id);

CREATE INDEX siac_r_bil_elem_fpv_fk_bil_elem_fpv_id_idx ON siac.siac_r_bil_elem_fpv
  USING btree (elem_fpv_id);

  