/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.fase_bil_t_cap_calcolo_res (
  fase_bil_cap_calc_res_id SERIAL,
  fase_bil_elab_id INTEGER NOT NULL,
  elem_code VARCHAR(200) NOT NULL,
  elem_code2 VARCHAR(200) NOT NULL,
  elem_code3 VARCHAR(200) DEFAULT '1'::character varying NOT NULL,
  bil_id INTEGER NOT NULL,
  elem_id INTEGER,
  elem_tipo_id INTEGER,
  tot_impacc NUMERIC DEFAULT 0 NOT NULL,
  stanziamento NUMERIC DEFAULT 0 NOT NULL,
  stanziamento_cassa NUMERIC DEFAULT 0 NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_fase_bil_t_cap_calc_res PRIMARY KEY(fase_bil_cap_calc_res_id),
  CONSTRAINT fase_bil_t_elaborazione_id_fase_bil_t_cap_calc_res FOREIGN KEY (fase_bil_elab_id)
    REFERENCES siac.fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_d_bil_elem_tipo_fase_bil_t_cap_calc_res_id FOREIGN KEY (elem_tipo_id)
    REFERENCES siac.siac_d_bil_elem_tipo(elem_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_elem_fase_bil_t_cap_calc_res_id FOREIGN KEY (elem_id)
    REFERENCES siac.siac_t_bil_elem(elem_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_id_fase_bil_t_cap_calc_res FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_bil_t_cap_calc_res FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) ;

COMMENT ON TABLE siac.fase_bil_t_cap_calcolo_res
IS 'Calcolo residui presunti e stanziamento cassa';

COMMENT ON COLUMN siac.fase_bil_t_cap_calcolo_res.elem_code
IS 'Identificativo logico elemento di bilancio';

COMMENT ON COLUMN siac.fase_bil_t_cap_calcolo_res.elem_code2
IS 'Identificativo logico elemento di bilancio';

COMMENT ON COLUMN siac.fase_bil_t_cap_calcolo_res.elem_code3
IS 'Identificativo logico elemento di bilancio';

COMMENT ON COLUMN siac.fase_bil_t_cap_calcolo_res.elem_id
IS 'Identificativo elemento di bilancio';

CREATE UNIQUE INDEX idx_fase_bil_t_cap_calcolo_res_1 ON siac.fase_bil_t_cap_calcolo_res
  USING btree (elem_code COLLATE pg_catalog."default", elem_code2 COLLATE pg_catalog."default", elem_code3 COLLATE pg_catalog."default", fase_bil_elab_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE UNIQUE INDEX idx_fase_bil_t_cap_calcolo_res_2 ON siac.fase_bil_t_cap_calcolo_res
  USING btree (elem_id, fase_bil_elab_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);