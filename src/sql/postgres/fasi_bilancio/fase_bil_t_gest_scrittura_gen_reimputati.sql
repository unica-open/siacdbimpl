/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.fase_bil_t_gest_scrittura_gen_reimputati (
  sgr_id SERIAL,
  movgest_id INTEGER,
  movgest_ts_id INTEGER,
  movgest_ts_tipo_code VARCHAR,
  classif_id INTEGER,
  regmovfin_id INTEGER,
  evento_code VARCHAR,
  ente_proprietario_id INTEGER NOT NULL,
  data_operazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  login_operazione VARCHAR DEFAULT 'fnc_fasi_bil_gest_scrittura_gen_reimputati'::character varying,
  CONSTRAINT siac_t_ente_proprietario_gest_scrittura_gen_pluri FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_gest_scrittura_gen_pluri FOREIGN KEY (movgest_id)
    REFERENCES siac.siac_t_movgest(movgest_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_gest_scrittura_gen_pluri FOREIGN KEY (movgest_ts_id)
    REFERENCES siac.siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_reg_movfin_gest_scrittura_gen_pluri FOREIGN KEY (regmovfin_id)
    REFERENCES siac.siac_t_reg_movfin(regmovfin_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);