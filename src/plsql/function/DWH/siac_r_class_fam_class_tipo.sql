/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_r_class_fam_class_tipo (
  famclassif_id SERIAL,
  classif_fam_id INTEGER NOT NULL,
  classif_tipo_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_class_fam_class_tipo PRIMARY KEY(famclassif_id),
  CONSTRAINT siac_d_class_fam_siac_r_class_fam_class_tipo FOREIGN KEY (classif_fam_id)
    REFERENCES siac.siac_d_class_fam(classif_fam_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_class_tipo_siac_r_class_fam_class_tipo FOREIGN KEY (classif_tipo_id)
    REFERENCES siac.siac_d_class_tipo(classif_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_r_class_fam_class_tipo_1 ON siac.siac_r_class_fam_class_tipo
  USING btree (classif_fam_id, classif_tipo_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);