/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
p table mif_t_ordinativo_entrata_id;
drop table mif_t_ordinativo_entrata_ricevute;
drop table mif_t_ordinativo_entrata_disp_ente;
drop table mif_t_ordinativo_entrata;

CREATE TABLE mif_t_ordinativo_entrata_id
(
 mif_ord_id	serial,
 mif_ord_ord_id	 INTEGER not null,
 mif_ord_codice_funzione	 VARCHAR(20) not null,
 mif_ord_bil_id	 INTEGER not null,
 mif_ord_periodo_id	 INTEGER not null,
 mif_ord_anno_bil	 INTEGER not null,
 mif_ord_ord_anno	 INTEGER not null,
 mif_ord_bil_fase_ope varchar(50) null,
 mif_ord_ord_numero  	varchar(50) not null,
 mif_ord_data_emissione	varchar(10) not null,
 mif_ord_cast_cassa NUMERIC NOT NULL,
 mif_ord_cast_competenza NUMERIC NOT NULL,
 mif_ord_cast_emessi NUMERIC NOT NULL,
 mif_ord_desc varchar(500),
 mif_ord_login_creazione varchar(200)  null,
 mif_ord_login_modifica varchar(200)  null,
 mif_ord_ord_anno_movg integer not null,
 mif_ord_soggetto_id	 INTEGER not null,
 mif_ord_subord_id	 INTEGER not null,
 mif_ord_elem_id	 INTEGER not null,
 mif_ord_tipologia_id INTEGER  null,
 mif_ord_tipologia_code VARCHAR(10) null,
 mif_ord_tipologia_desc VARCHAR(500) null,
 mif_ord_movgest_id	 INTEGER not null,
 mif_ord_movgest_ts_id	 INTEGER not null,
 mif_ord_atto_amm_id	 INTEGER not null,
 mif_ord_atto_amm_movg_id INTEGER  null,
 mif_ord_contotes_id integer null,
 mif_ord_notetes_id integer null,
 mif_ord_dist_id integer null,
 mif_ord_note_attr_id integer null,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_entrata_id PRIMARY KEY(mif_ord_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_entrata_id FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
 )
WITH (oids = false);


COMMENT ON TABLE mif_t_ordinativo_entrata_id
IS 'Tabella temporanea contenente gli id degli ordinativi di entrata e delle relative informazioni da trasmettere';

CREATE TABLE mif_t_ordinativo_entrata
(
 mif_ord_id	serial,
 mif_ord_data_elab	TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 mif_ord_flusso_elab_mif_id	integer not null,
 mif_ord_ord_id	integer not null,
 mif_ord_bil_id	integer not null,
 mif_ord_anno	integer not null,
 mif_ord_codice_funzione	VARCHAR(20) NOT NULL,
 mif_ord_numero	VARCHAR(50) NOT NULL,
 mif_ord_data	VARCHAR(10) NOT NULL,
 mif_ord_importo	VARCHAR(100) NOT NULL,
 mif_ord_bci_tipo_contabil	VARCHAR(50) NULL,
 mif_ord_bci_tipo_entrata	VARCHAR(50) NULL,
 mif_ord_bci_numero_doc	VARCHAR(50) NULL,
 mif_ord_destinazione	VARCHAR(50) NULL,
 mif_ord_codice_abi_bt	VARCHAR(50) NOT NULL,
 mif_ord_codice_ente	VARCHAR(50) NOT NULL,
 mif_ord_desc_ente	VARCHAR(500) NOT NULL,
 mif_ord_codice_ente_bt	VARCHAR(50) NOT NULL,
 mif_ord_anno_esercizio	integer not null,
 mif_ord_codice_flusso_oil  varchar(50)  null,
 mif_ord_id_flusso_oil	integer not null,
 mif_ord_data_creazione_flusso	VARCHAR(50) NOT NULL,
 mif_ord_anno_flusso	integer not null,
 mif_ord_codice_struttura	VARCHAR(50) NULL,
 mif_ord_ente_localita	VARCHAR(500) NULL,
 mif_ord_ente_indirizzo	VARCHAR(500) NULL,
 mif_ord_progr_vers	VARCHAR(50) NULL,
 mif_ord_class_codice_cge	VARCHAR(50) NULL,
 mif_ord_class_importo	VARCHAR(500) NULL,
 mif_ord_codifica_bilancio	VARCHAR(100) NULL,
 mif_ord_capitolo  varchar(100) null,
 mif_ord_articolo	VARCHAR(50) NULL,
 mif_ord_desc_codifica	VARCHAR(500) NULL,
 mif_ord_desc_codifica_bil	VARCHAR(1000) NULL,
 mif_ord_gestione	VARCHAR(100) NULL,
 mif_ord_anno_res	integer  null,
 mif_ord_importo_bil	VARCHAR(100) NULL,
 mif_ord_anag_versante	VARCHAR(500) NULL,
 mif_ord_indir_versante	VARCHAR(500) NULL,
 mif_ord_cap_versante	varchar(10) null,
 mif_ord_localita_versante	VARCHAR(500) NULL,
 mif_ord_prov_versante	VARCHAR(500) NULL,
 mif_ord_partiva_versante	VARCHAR(50) NULL,
 mif_ord_codfisc_versante	VARCHAR(50) NULL,
 mif_ord_bollo_esenzione	VARCHAR(50) NULL,
 mif_ord_vers_tipo_riscos	VARCHAR(50) NULL,
 mif_ord_vers_cod_riscos	VARCHAR(50) NULL,
 mif_ord_vers_importo	VARCHAR(100) NULL,
 mif_ord_vers_causale	VARCHAR(500) NULL,
 mif_ord_lingua	varchar(10) null,
 mif_ord_rif_doc_esterno	varchar(10) null,
 mif_ord_info_tesoriere	VARCHAR(500) NULL,
 mif_ord_flag_copertura	varchar(10) null,
 mif_ord_sost_rev	varchar(10) null,
 mif_ord_num_ord_colleg	VARCHAR(50) NULL,
 mif_ord_progr_ord_colleg	VARCHAR(50) NULL,
 mif_ord_anno_ord_colleg	integer  null,
 mif_ord_numero_acc	varchar(500) null,
 mif_ord_code_operatore	varchar(100) null,
 mif_ord_siope_codice_cge	VARCHAR(50) NULL,
 mif_ord_siope_descri_cge	VARCHAR(500) NULL,
 mif_ord_descri_estesa_cap	varchar(1000) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_entrata PRIMARY KEY(mif_ord_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_entrata FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_flusso_elaborato_mif_t_ordinativo_entrata FOREIGN KEY (mif_ord_flusso_elab_mif_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_mif_t_ordinativo_entrata FOREIGN KEY (mif_ord_bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_entrata FOREIGN KEY (mif_ord_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_entrata
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Entrata]';

comment on column mif_t_ordinativo_entrata.mif_ord_id_flusso_oil
is 'Identificativo del flusso [calcolato su siac_t_progressivi per siac_d_file_tipo.file_tipo_code]';

comment on column mif_t_ordinativo_entrata.mif_ord_flusso_elab_mif_id
is 'Identificativo del tipo flusso MIF di riferimento [mif_t_flusso_elaborato.flusso_elab_mif_id]';


CREATE TABLE mif_t_ordinativo_entrata_ricevute (
 mif_ord_ric_id serial,
 mif_ord_id     integer not null,
 mif_ord_ric_anno varchar(50) not null,
 mif_ord_ric_numero varchar(50) not null,
 mif_ord_provc_id integer not null,
 mif_ord_ric_importo varchar(100) not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_entrata_ricevute PRIMARY KEY(mif_ord_ric_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_entrata_ric FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_entrata_mif_t_ordinativo_entrata_ric FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_entrata(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_prov_cassa_mif_t_ordinativo_entrata_ric FOREIGN KEY (mif_ord_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_entrata_ricevute
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Entrata Ricevute]';

CREATE TABLE mif_t_ordinativo_entrata_disp_ente (
 mif_ord_dispe_id serial,
 mif_ord_id     integer not null,
 mif_ord_ts_id  integer null,
 mif_ord_id_a integer null,
 mif_ord_dispe_ordine integer not null,
 mif_ord_dispe_nome   varchar(100) not null,
 mif_ord_dispe_valore varchar(500) not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_entrata_disp_ente PRIMARY KEY(mif_ord_dispe_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_entrata_disp_ente FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_entrata_mif_t_ordinativo_entrata_disp_ente FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_entrata(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_entrata_disp_ente
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Entrata dati a disposizione ente]';


CREATE TABLE mif_t_ordinativo_entrata_disp_ente_vers (
 mif_ord_dispe_vers_id serial,
 mif_ord_id     integer not null,
 mif_ord_ord_id integer not null,
 mif_ord_dispe_codice_economico varchar(50) null,
 mif_ord_dispe_codice_economico_imp varchar(100) null,
 mif_ord_dispe_codice_ue         varchar(50) null,
 mif_ord_dispe_codice_entrata         varchar(50) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_entrata_dispe_vers PRIMARY KEY(mif_ord_dispe_vers_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_entrata_dispe_v FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_entrata_dispe_v FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_entrata(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_entrata_dispe_v FOREIGN KEY (mif_ord_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_entrata_disp_ente_vers
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Entrata Dati a disposizione ente versante ABI36]';