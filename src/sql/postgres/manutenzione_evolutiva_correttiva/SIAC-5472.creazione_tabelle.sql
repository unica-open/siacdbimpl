/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- drop TABLE IF EXISTS siac.siac_t_conf_indicatori_entrata;

CREATE TABLE siac.siac_t_conf_indicatori_entrata (
  --
  conf_ind_id SERIAL,
  classif_id_titolo INTEGER NOT NULL,
  classif_id_tipologia INTEGER NOT NULL,
  bil_id INTEGER NOT NULL,
  conf_ind_importo_accert_anno_prec NUMERIC,
  conf_ind_importo_accert_anno_prec_1 NUMERIC,
  conf_ind_importo_accert_anno_prec_2 NUMERIC,
  conf_ind_importo_riscoss_anno_prec NUMERIC,
  conf_ind_importo_riscoss_anno_prec_1 NUMERIC,
  conf_ind_importo_riscoss_anno_prec_2 NUMERIC,
  --
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  --
  CONSTRAINT pk_siac_t_conf_indicatori_entrata PRIMARY KEY(conf_ind_id),
  CONSTRAINT siac_t_class_siac_t_conf_indicatori_entrata_tit FOREIGN KEY (classif_id_titolo)
    REFERENCES siac.siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_class_siac_t_conf_indicatori_entrata_tip FOREIGN KEY (classif_id_tipologia)
    REFERENCES siac.siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_siac_t_conf_indicatori_entrata FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_conf_indicatori_entrata FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);



-- drop TABLE IF EXISTS siac.siac_t_conf_indicatori_spesa;

CREATE TABLE siac.siac_t_conf_indicatori_spesa (
  --
  conf_ind_id SERIAL,
  classif_id_missione INTEGER NOT NULL,
  classif_id_programma INTEGER NOT NULL,
  bil_id INTEGER NOT NULL,
  conf_ind_importo_fpv_anno_prec NUMERIC,
  conf_ind_importo_fpv_anno_prec_1 NUMERIC,
  conf_ind_importo_fpv_anno_prec_2 NUMERIC,
  conf_ind_importo_impegni_anno_prec NUMERIC,
  conf_ind_importo_impegni_anno_prec_1 NUMERIC,
  conf_ind_importo_impegni_anno_prec_2 NUMERIC,
  conf_ind_importo_pag_comp_anno_prec NUMERIC,
  conf_ind_importo_pag_comp_anno_prec_1 NUMERIC,
  conf_ind_importo_pag_comp_anno_prec_2 NUMERIC,
  conf_ind_importo_pag_res_anno_prec NUMERIC,
  conf_ind_importo_pag_res_anno_prec_1 NUMERIC,
  conf_ind_importo_pag_res_anno_prec_2 NUMERIC,
  conf_ind_importo_res_def_anno_prec NUMERIC,
  conf_ind_importo_res_def_anno_prec_1 NUMERIC,
  conf_ind_importo_res_def_anno_prec_2 NUMERIC,
  --
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  --
  CONSTRAINT pk_siac_t_conf_indicatori_spesa PRIMARY KEY(conf_ind_id),
  CONSTRAINT siac_t_class_siac_t_conf_indicatori_spesa_m FOREIGN KEY (classif_id_missione)
    REFERENCES siac.siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_class_siac_t_conf_indicatori_spesa_p FOREIGN KEY (classif_id_programma)
    REFERENCES siac.siac_t_class(classif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_siac_t_conf_indicatori_spesa FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_conf_indicatori_spesa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);





-- drop TABLE IF EXISTS siac.siac_t_voce_conf_indicatori_sint;

CREATE TABLE siac.siac_t_voce_conf_indicatori_sint (
  --
  voce_conf_ind_id SERIAL,
  voce_conf_ind_codice VARCHAR(200) NOT NULL,
  voce_conf_ind_desc VARCHAR(500) NOT NULL,
  voce_conf_ind_decimali INTEGER NOT NULL,
  voce_conf_ind_num_anni_input INTEGER NOT NULL,
  voce_conf_ind_split_missione_13 BOOLEAN DEFAULT FALSE NOT NULL,
  --
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  --
  CONSTRAINT pk_siac_t_voce_conf_indicatori_sint PRIMARY KEY(voce_conf_ind_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_voce_conf_indicatori_sint FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);



-- drop TABLE IF EXISTS siac.siac_t_conf_indicatori_sint;

CREATE TABLE siac.siac_t_conf_indicatori_sint (
  --
  conf_ind_id SERIAL,
  voce_conf_ind_id INTEGER NOT NULL,
  bil_id INTEGER NOT NULL,
  conf_ind_valore_anno NUMERIC,
  conf_ind_valore_anno_1 NUMERIC,
  conf_ind_valore_anno_2 NUMERIC,
  conf_ind_valore_tot_miss_13_anno NUMERIC,
  conf_ind_valore_tot_miss_13_anno_1 NUMERIC,
  conf_ind_valore_tot_miss_13_anno_2 NUMERIC,
  conf_ind_valore_tutte_spese_anno NUMERIC,
  conf_ind_valore_tutte_spese_anno_1 NUMERIC,
  conf_ind_valore_tutte_spese_anno_2 NUMERIC,
  --
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  --
  CONSTRAINT pk_siac_t_conf_indicatori_sint PRIMARY KEY(conf_ind_id),
  CONSTRAINT siac_t_voce_conf_indicatori_sint_siac_t_conf_indicatori_sint FOREIGN KEY (voce_conf_ind_id)
    REFERENCES siac.siac_t_voce_conf_indicatori_sint(voce_conf_ind_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_siac_t_conf_indicatori_sint FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_conf_indicatori_sint FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);