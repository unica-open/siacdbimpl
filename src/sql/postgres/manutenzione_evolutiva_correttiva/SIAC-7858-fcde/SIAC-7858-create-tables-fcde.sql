/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_d_acc_fondi_dubbia_esig_tipo
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo(
    afde_tipo_id SERIAL PRIMARY KEY,
    afde_tipo_code VARCHAR(50) NOT NULL,
    afde_tipo_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_stato
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_stato(
    afde_stato_id SERIAL PRIMARY KEY,
    afde_stato_code VARCHAR(50) NOT NULL,
    afde_stato_priorita INTEGER NOT NULL,
    afde_stato_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_stato FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media(
    afde_tipo_media_id SERIAL PRIMARY KEY,
    afde_tipo_media_code VARCHAR(50) NOT NULL,
    afde_tipo_media_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto(
    afde_tipo_media_conf_id SERIAL PRIMARY KEY,
    afde_tipo_media_conf_code VARCHAR(50) NOT NULL,
    afde_tipo_media_conf_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media_confronto FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil(
    afde_bil_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_stato_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    afde_bil_accantonamento_graduale NUMERIC,
    afde_bil_quinquennio_riferimento INTEGER,
    afde_bil_riscossione_virtuosa BOOLEAN,
    afde_bil_crediti_stralciati NUMERIC,
    afde_bil_crediti_stralciati_fcde NUMERIC,
    afde_bil_accertamenti_anni_successivi NUMERIC,
    afde_bil_accertamenti_anni_successivi_fcde NUMERIC,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_stato_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_stato_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_stato(afde_stato_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil_num
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil_num (
    afde_bil_num_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
CREATE UNIQUE INDEX siac_t_acc_fondi_dubbia_esig_bil_num_uq ON siac.siac_t_acc_fondi_dubbia_esig_bil_num USING btree (bil_id, afde_tipo_id) WHERE (data_cancellazione IS NULL);

-- siac_t_acc_fondi_dubbia_esig
-- Tutti i campi sono inizialmente nullable per evitare problematiche con il pregresso.
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_utente', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_confronto', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_note', 'TEXT');
-- SIAC-8393-8394 si aggiungono i campi dell'accantonamento per i 3 anni
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno2', 'NUMERIC');


-- Metadati
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_media_utente_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno2_originale', 'NUMERIC');

-- FK
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media', 'afde_tipo_media_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto', 'afde_tipo_media_conf_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'siac_d_acc_fondi_dubbia_esig_tipo', 'afde_tipo_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'elem_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_bil_elem_siac_t_acc_fondi_dubbia_esig', 'elem_id', 'siac_t_bil_elem', 'elem_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_acc_fondi_dubbia_esig_bil_siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'siac_t_acc_fondi_dubbia_esig_bil', 'afde_bil_id');

-- siac_d_tipo_campo
CREATE TABLE IF NOT EXISTS siac.siac_d_tipo_campo(
  tc_id SERIAL PRIMARY KEY,
  tc_code VARCHAR(250) NOT NULL,
  tc_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_d_tipo_campo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- siac_t_visibilita
CREATE TABLE IF NOT EXISTS siac.siac_t_visibilita (
  vis_id SERIAL PRIMARY KEY,
  vis_campo VARCHAR(250) NOT NULL,
  vis_visibile BOOLEAN NOT NULL,
  tc_id INTEGER NOT NULL,
  vis_funzionalita VARCHAR(250),
  azione_id INTEGER,
  vis_default TEXT,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_t_visibilita FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_d_tipo_campo_siac_t_visibilita FOREIGN KEY (tc_id) REFERENCES siac.siac_d_tipo_campo(tc_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_t_azione_siac_t_visibilita FOREIGN KEY (azione_id) REFERENCES siac.siac_t_azione(azione_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
