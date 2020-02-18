/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿table mif_t_ordinativo_spesa_ritenute;
drop table mif_t_ordinativo_spesa_ricevute;
drop table mif_t_ordinativo_spesa_documenti;
--drop table mif_t_subordinativo_spesa; -- non la gestisco
drop table mif_t_ordinativo_spesa_disp_ente;

drop table mif_t_ordinativo_spesa_disp_ente_benef;

drop table mif_t_ordinativo_spesa;

drop table mif_t_ordinativo_spesa_id;


drop table mif_t_flusso_elaborato;

drop table mif_d_flusso_elaborato;

drop table mif_d_flusso_elaborato_tipo;


-- record type per valorizzazione Array

drop type flussoElabMifRecType;

create type flussoElabMifRecType as
(
	 flussoElabMifId          integer,
	 flussoElabMifAttivo      boolean,
	 flussoElabMifDef         VARCHAR(200),
	 flussoElabMifElab        boolean,
	 flussoElabMifParam 	  VARCHAR(200),
	 flusso_elab_mif_campo    VARCHAR(50),
     flusso_elab_mif_tipo_id  integer,
     flusso_elab_mif_ordine   integer,
	 flusso_elab_mif_ordine_elab integer,
	 flusso_elab_mif_code        VARCHAR(500)
);

CREATE TABLE mif_d_flusso_elaborato_tipo(
 flusso_elab_mif_tipo_id          serial,
 flusso_elab_mif_tipo_code        VARCHAR(500) NOT NULL,
 flusso_elab_mif_tipo_desc        VARCHAR(500) NULL,
 flusso_elab_mif_nome_file        VARCHAR(500) NOT NULL,
 flusso_elab_mif_tipo_dec		  boolean default false not null ,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_d_flusso_elaborato_tipo PRIMARY KEY(flusso_elab_mif_tipo_id),
 CONSTRAINT siac_t_ente_proprietario_mif_d_flusso_elaborato_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_d_flusso_elaborato_tipo
IS 'Tabella  dei tipi flussi MIF';


CREATE TABLE mif_d_flusso_elaborato(
 flusso_elab_mif_id          serial,
 flusso_elab_mif_tipo_id     integer  null,
 flusso_elab_mif_ordine      integer not null,
 flusso_elab_mif_ordine_elab integer not null,
 flusso_elab_mif_code        VARCHAR(500) NOT NULL,
 flusso_elab_mif_desc        VARCHAR(500) NULL,
 flusso_elab_mif_attivo      boolean default true not null,
 flusso_elab_mif_xml_out     boolean default true not null,
 flusso_elab_mif_code_padre  VARCHAR(500) NULL,
 flusso_elab_mif_tabella     VARCHAR(50)  NULL,
 flusso_elab_mif_campo       VARCHAR(50)  NULL,
 flusso_elab_mif_default     VARCHAR(200) NULL,
 flusso_elab_mif_elab        boolean default false not null,
 flusso_elab_mif_param       VARCHAR(200) NULL,
 flusso_elab_mif_query      VARCHAR(500) NULL,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_d_flusso_elaborato PRIMARY KEY(flusso_elab_mif_id),
 CONSTRAINT siac_t_ente_proprietario_mif_d_flusso_elaborato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_d_flusso_elaborato_tipo_mif_d_flusso_elaborato FOREIGN KEY (flusso_elab_mif_tipo_id)
    REFERENCES mif_d_flusso_elaborato_tipo(flusso_elab_mif_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_d_flusso_elaborato
IS 'Tabella di configurazione dei flussi MIF';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_tipo_id
is 'Identificativo del tipo flusso [mif_d_flusso_elaborato_tipo.flusso_elab_mif_tipo_id]';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_ordine
is 'Ordine di esposizione nel file XML del tag';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_ordine_elab
is 'Ordine di elaborazione del campo nel codice plSql per popolamento della tabella di spool.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_code
is 'Nome tag.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_desc
is 'Descrizione o note del tag.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_attivo
is 'Booleano che indica se il tag ? gestito deve essere valorizzato a true per essere esposto nel file XML e elaborato dal plSql per il popolamento della tabella di spool.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_xml_out
is 'Booleano che indica se il tag ? esposto nel file XML.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_code_padre
is 'Tag padre.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_tabella
is 'Nome della tabella in cui ? salvata l'' informazione esposta nel relativo tag XML.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_campo
is 'Nome del campo in cui ? salvata l'' informazione esposta nel relativo tag XML.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_default
is 'Valore con cui ? valorizzato il campo della tabella di spool o il tag XML nel caso in cui non sia calcolato da DB.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_param
is 'Paramentri di configurazione utilizzati per gli algoritmi di determinazione delle informazioni da salvare nei campi della tabella di spool.';

comment on column mif_d_flusso_elaborato.flusso_elab_mif_elab
is 'Booleano valorizzato a true se il tag deve valorizzato con un algoritmo di calcolo nel codice plSql di popolamento della tabella di spool.
\ndeve essere sempre true se il tag ha un valori di flusso_elab_mif_ordine_elab!=0';


comment on column mif_d_flusso_elaborato.flusso_elab_mif_query
is 'Query di estrazione dei dati dalle tabelle di spool per il popolamento dei tag XML.';



CREATE UNIQUE INDEX idx_mif_d_flusso_elaborato_key ON mif_d_flusso_elaborato
  USING btree (flusso_elab_mif_tipo_id,flusso_elab_mif_code,flusso_elab_mif_tabella,flusso_elab_mif_campo, ente_proprietario_id);

CREATE TABLE mif_t_flusso_elaborato (
 flusso_elab_mif_id serial,
 flusso_elab_mif_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 flusso_elab_mif_esito varchar(10)  not null,
 flusso_elab_mif_esito_msg varchar(750)  not null,
 flusso_elab_mif_file_nome VARCHAR(500) NOT NULL,
 flusso_elab_mif_tipo_id integer not null,
 flusso_elab_mif_id_flusso_oil  integer  null,
 flusso_elab_mif_num_ord_elab numeric null,
 flusso_elab_mif_num_subord_elab numeric null,
 flusso_elab_mif_codice_flusso_oil  varchar(50) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_flusso_elaborato PRIMARY KEY(flusso_elab_mif_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_flusso_elaborato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_d_flusso_elaborato_tipo_mif_t_flusso_elaborato FOREIGN KEY (flusso_elab_mif_tipo_id)
    REFERENCES mif_d_flusso_elaborato_tipo(flusso_elab_mif_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_flusso_elaborato
IS 'Tabella di log dei flussi elaborati verso e da MIF';

comment on column mif_t_flusso_elaborato.flusso_elab_mif_id_flusso_oil
is 'Identificativo del flusso di riferimento [mif_t_ordinativo.mif_ord_id_flusso_oil]';

CREATE TABLE mif_t_ordinativo_spesa_id (
 mif_ord_id serial,
 mif_ord_ord_id INTEGER not null,
 mif_ord_codice_funzione VARCHAR(20) not null,
 mif_ord_bil_id INTEGER not null,
 mif_ord_periodo_id INTEGER not null,
 mif_ord_anno_bil integer not null,
 mif_ord_ord_anno integer not null,
 mif_ord_bil_fase_ope varchar(50) null,
 mif_ord_ord_anno_movg integer not null,
 mif_ord_ord_numero  varchar(50) not null,
 mif_ord_data_emissione varchar(10) NOT NULL,
 mif_ord_cast_cassa NUMERIC NOT NULL,
 mif_ord_cast_competenza NUMERIC NOT NULL,
 mif_ord_cast_emessi NUMERIC NOT NULL,
 mif_ord_desc varchar(500),
 mif_ord_login_creazione varchar(200)  null,
 mif_ord_login_modifica varchar(200)  null,
 mif_ord_soggetto_id INTEGER not null,
 mif_ord_modpag_id INTEGER not null,
 mif_ord_dist_id integer null,
 mif_ord_subord_id INTEGER not null,
 mif_ord_elem_id INTEGER not null,
 mif_ord_programma_id INTEGER  null,
 mif_ord_programma_code VARCHAR(10)  null,
 mif_ord_programma_desc VARCHAR(500)  null,
 mif_ord_titolo_id INTEGER  null,
 mif_ord_titolo_code VARCHAR(10) null,
 mif_ord_movgest_id INTEGER not null,
 mif_ord_movgest_ts_id INTEGER not null,
 mif_ord_liq_id INTEGER not null,
 mif_ord_atto_amm_id INTEGER  null,
 mif_ord_atto_amm_movg_id INTEGER  null,
 mif_ord_contotes_id integer null,
 mif_ord_comm_tipo_id integer null,
 mif_ord_codbollo_id integer null,
 mif_ord_notetes_id integer null,
 mif_ord_note_attr_id integer null,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa_id PRIMARY KEY(mif_ord_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_id FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
 )
WITH (oids = false);


COMMENT ON TABLE mif_t_ordinativo_spesa_id
IS 'Tabella temporanea contenente gli id degli ordinativi di spesa e delle relative informazioni da trasmettere';

CREATE TABLE mif_t_ordinativo_spesa (
 mif_ord_id serial,
 mif_ord_data_elab TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 mif_ord_flusso_elab_mif_id integer not null,
 mif_ord_bil_id INTEGER not null,
 mif_ord_ord_id INTEGER not null,
 mif_ord_anno integer not null,
 mif_ord_numero  varchar(50) not null,
 mif_ord_codice_funzione VARCHAR(20) not null,
 mif_ord_data varchar(10) NOT NULL,
 mif_ord_importo varchar(100) not null,
 mif_ord_flag_fin_loc VARCHAR(10) null,
 mif_ord_documento VARCHAR(10) null,
 mif_ord_bci_tipo_ente_pag varchar(200) null,
 mif_ord_bci_dest_ente_pag varchar(500) null,
 mif_ord_bci_conto_tes varchar(200) null,
 mif_ord_estremi_attoamm  varchar(1000) null,
 mif_ord_codice_uff_resp  varchar(500) null,
 mif_ord_data_attoamm     varchar(10) null,
 mif_ord_resp_attoamm     varchar(20) null,
 mif_ord_uff_resp_attomm  varchar(20) null,
 mif_ord_codice_abi_bt    varchar(50) not null,
 mif_ord_codice_ente      varchar(500) not null,
 mif_ord_desc_ente        varchar(500) not null,
 mif_ord_codice_ente_bt   varchar(500) not null,
 mif_ord_anno_esercizio   integer not null,
 mif_ord_codice_flusso_oil  varchar(50)   null,
 mif_ord_id_flusso_oil    integer not null,
 mif_ord_data_creazione_flusso varchar NOT NULL,
 mif_ord_anno_flusso      integer not null,
 mif_ord_codice_struttura varchar(200) null,
 mif_ord_progr_ord_struttura  varchar(200) null,
 mif_ord_ente_localita varchar(500) null,
 mif_ord_ente_indirizzo varchar(5200) null,
 mif_ord_codice_cge varchar(200) null,
 mif_ord_descr_cge varchar(500) null,
 mif_ord_tipo_contabilita  varchar(100) null,
 mif_ord_codice_raggrup    varchar(200) null,
 mif_ord_progr_benef       varchar(200) null,
 mif_ord_progr_impignor    varchar(10) null,
 mif_ord_progr_dest        varchar(10) null,
 mif_ord_bci_conto         varchar(200) null,
 mif_ord_bci_tipo_contabil  varchar(200) null,
 mif_ord_class_codice_cge   varchar(200)  null,
 mif_ord_class_importo varchar(100) null,
 mif_ord_class_codice_cup  varchar(10) null,
 mif_ord_class_codice_cpv   varchar(10) null,
 mif_ord_class_codice_gest_prov  varchar(10) null,
 mif_ord_class_codice_gest_fraz  varchar(10) null,
 mif_ord_codifica_bilancio  varchar(100) null,
 mif_ord_capitolo  varchar(100) null,
 mif_ord_articolo  varchar(100) null,
 mif_ord_voce_eco  varchar(10) null,
 mif_ord_desc_codifica varchar(1000) null,
 mif_ord_desc_codifica_bil varchar(1000) null,
 mif_ord_gestione varchar(100) null,
 mif_ord_anno_res integer null,
 mif_ord_importo_bil varchar(100)  null,
 mif_ord_stanz  varchar(100)  null,
 mif_ord_mandati_stanz varchar(100)  null,
 mif_ord_disponibilita varchar(100)  null,
 mif_ord_prev varchar(100)  null,
 mif_ord_mandati_prev varchar(100)  null,
 mif_ord_disp_cassa varchar(100)  null,
 mif_ord_anag_benef varchar(500) null,
 mif_ord_indir_benef varchar(500) null,
 mif_ord_cap_benef varchar(10) null,
 mif_ord_localita_benef varchar(100) null,
 mif_ord_prov_benef varchar(100) null,
 mif_ord_stato_benef varchar(50) null,
 mif_ord_partiva_benef varchar(50) null,
 mif_ord_codfisc_benef varchar(50) null,
 mif_ord_anag_quiet  varchar(500) null,
 mif_ord_indir_quiet varchar(500) null,
 mif_ord_cap_quiet   varchar(10) null,
 mif_ord_localita_quiet varchar(100) null,
 mif_ord_prov_quiet varchar(100) null,
 mif_ord_partiva_quiet varchar(50) null,
 mif_ord_codfisc_quiet varchar(50) null,
 mif_ord_anag_del varchar(500) null,
 mif_ord_codfisc_del varchar(50) null,
 mif_ord_cap_del varchar(10) null,
 mif_ord_localita_del varchar(100) null,
 mif_ord_prov_del varchar(50) null,
 mif_ord_invio_avviso  varchar(10) null,
 mif_ord_codfisc_avviso varchar(50) null,
 mif_ord_abi_benef varchar(10) null,
 mif_ord_cab_benef varchar(10) null,
 mif_ord_cc_benef_estero varchar(50) null,
 mif_ord_cc_benef varchar(50) null,
 mif_ord_ctrl_benef varchar(10) null,
 mif_ord_cin_benef varchar(10) null,
 mif_ord_cod_paese_benef varchar(10) null,
 mif_ord_denom_banca_benef varchar(500) null,
 mif_ord_cc_postale_benef varchar(50) null,
 mif_ord_swift_benef varchar(50) null,
 mif_ord_iban_benef  varchar(50) null,
 mif_ord_sepa_iban_tr varchar(50) null,
 mif_ord_sepa_bic_tr  varchar(50) null,
 mif_ord_sepa_id_end_tr varchar(100) null,
 mif_ord_cod_ente_benef   varchar(50) null,
 mif_ord_fl_pagam_cond_benef  varchar(50) null,
 mif_ord_bollo_esenzione  varchar(50) null,
 mif_ord_bollo_carico      varchar(100) null,
 mif_ordin_bollo_caus_esenzione varchar(500) null,
 mif_ord_bollo_importo varchar(100) null,
 mif_ord_bollo_carico_spe varchar(10) null,
 mif_ord_bollo_importo_spe varchar(100) null,
 mif_ord_commissioni_carico varchar(100) null,
 mif_ord_commissioni_importo varchar(100) null,
  mif_ord_commissioni_natura varchar(100) null,
 mif_ord_pagam_tipo varchar(500) null,
 mif_ord_pagam_code varchar(50) null,
 mif_ord_pagam_importo varchar(100) null,
 mif_ord_pagam_causale varchar(500) null,
 mif_ord_pagam_data_esec varchar(10) null,
 mif_ord_pagam_data_scad varchar(10) null,
 mif_ord_pagam_flag_val_ant varchar(10) null,
 mif_ord_pagam_divisa_estera varchar(10) null,
 mif_ord_pagam_flag_ass_circ varchar(10) null,
 mif_ord_pagam_flag_vaglia varchar(10) null,
 mif_ord_lingua varchar(10) null,
 mif_ord_rif_doc_esterno varchar(10) null,
 mif_ord_info_tesoriere varchar(500) null,
 mif_ord_tipo_utenza varchar(10) null,
 mif_ord_codice_ute varchar(10) null,
 mif_ord_cod_generico varchar(10) null,
 mif_ord_flag_copertura varchar(10) null,
 mif_ord_num_ord_colleg varchar(50) null,
 mif_ord_progr_ord_colleg varchar(50) null,
 mif_ord_anno_ord_colleg integer null,
 --mif_ord_dispe_cap_orig varchar(200) null,
-- mif_ord_dispe_articolo varchar(200) null,
-- mif_ord_dispe_descri_articolo varchar(1000) null,
-- mif_ord_dispe_somme_non_sogg varchar(100) null,
-- mif_ord_dispe_cod_trib varchar(200) null,
-- mif_ord_dispe_causale_770 varchar(200) null,
-- mif_ord_dispe_dtns_benef varchar(10) null,
-- mif_ord_dispe_cmns_benef varchar(100) null,
-- mif_ordinativo_dispe_prns_benef varchar(100) null,
-- mif_ord_dispe_note varchar(500) null,
-- mif_ord_dispe_descri_pag varchar(500) null,
-- mif_ord_dispe_descri_attoamm varchar(1000) null,
-- mif_ord_dispe_capitolo_peg varchar(10) null,
-- mif_ord_dispe_vincoli_dest varchar(10) null,
-- mif_ord_dispe_vincolato varchar(10) null,
-- mif_ord_dispe_voce_eco varchar(10) null,
-- mif_ord_dispe_distinta varchar(10) null,
-- mif_ord_dispe_data_scad_interna varchar(10) null,
-- mif_ord_dispe_rev_vinc varchar(20) null,
-- mif_ord_dispe_atto_all varchar(50) null,
-- mif_ord_dispe_liquidaz varchar(1000) null,
-- mif_ord_missione varchar(50) null,
-- mif_ord_programma varchar(50) null,
-- mif_ord_conto_econ varchar(50) null,
-- mif_ord_importo_econ varchar(100) null,
-- mif_ord_cod_ue varchar(50) null,
-- mif_ord_cofog_codice varchar(50) null,
-- mif_ord_cofog_importo varchar(100) null,
-- mif_ord_dispe_beneficiario varchar(500) null,
 mif_ord_numero_imp varchar(1000) null,
 mif_ord_numero_subimp varchar(1000) null,
 mif_ord_code_operatore varchar(100) null,
 mif_ord_nome_operatore varchar(10) null,
 mif_ord_fatture varchar(1000) null,
 mif_ord_descri_estesa_cap varchar(1000) null,
 mif_ord_descri_cap varchar(500) null,
 mif_ord_prog_cap varchar(10) null,
 mif_ord_tipo_cap varchar(10) null,
 mif_ord_siope_codice_cge varchar(50) null,
 mif_ord_siope_descri_cge varchar(500) null,
 mif_ord_codfisc_funz_del varchar(10) null,
 mif_ord_importo_funz_del varchar(100) null,
 mif_ord_tpag_funz_del varchar(10) null,
 mif_ord_npag_funz_del varchar(10) null,
 mif_ord_prg_funz_del varchar(10) null,
 mif_ord_codice_cpv varchar(10) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa PRIMARY KEY(mif_ord_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_flusso_elaborato_mif_t_ordinativo_spesa FOREIGN KEY (mif_ord_flusso_elab_mif_id)
    REFERENCES mif_t_flusso_elaborato(flusso_elab_mif_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_bil_mif_t_ordinativo_spesa FOREIGN KEY (mif_ord_bil_id)
    REFERENCES siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_spesa FOREIGN KEY (mif_ord_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa]';

comment on column mif_t_ordinativo_spesa.mif_ord_id_flusso_oil
is 'Identificativo del flusso [calcolato su siac_t_progressivi per siac_d_file_tipo.file_tipo_code]';

comment on column mif_t_ordinativo_spesa.mif_ord_flusso_elab_mif_id
is 'Identificativo del tipo flusso MIF di riferimento [mif_t_flusso_elaborato.flusso_elab_mif_id]';




CREATE TABLE mif_t_ordinativo_spesa_ritenute (
 mif_ord_rit_id serial,
 mif_ord_id     integer not null,
 mif_ord_rit_tipo varchar(10) not null,
 mif_ord_rit_importo varchar(100) not null,
 mif_ord_rit_numero  varchar(50) not null,
 mif_ord_rit_ord_id  integer not null,
 mif_ord_rit_progr_rev varchar(50) null,
 mif_ord_rit_progr_rit varchar(10) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa_ritenute PRIMARY KEY(mif_ord_rit_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_rit FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_rit FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_spesa_rit FOREIGN KEY (mif_ord_rit_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_ritenute
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa Ritenute]';


CREATE TABLE mif_t_ordinativo_spesa_ricevute (
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
 CONSTRAINT pk_mif_t_ordinativo_spesa_ricevute PRIMARY KEY(mif_ord_ric_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_ric FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_ric FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_prov_cassa_mif_t_ordinativo_spesa_ric FOREIGN KEY (mif_ord_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_ricevute
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa Ricevute]';

CREATE TABLE mif_t_ordinativo_spesa_disp_ente (
 mif_ord_dispe_id serial,
 mif_ord_id     integer not null,
 mif_ord_ts_id  integer null,
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
 CONSTRAINT pk_mif_t_ordinativo_spesa_disp_ente PRIMARY KEY(mif_ord_dispe_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_disp_ente FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_disp_ente FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_disp_ente
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa dati a disposizione ente]';

CREATE TABLE mif_t_ordinativo_spesa_documenti (
 mif_ord_doc_id serial,
 mif_ord_id     integer not null,
 mif_ord_documento varchar(100) not null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa_documenti PRIMARY KEY(mif_ord_doc_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_documenti FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_doci FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_documenti
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa documenti collegati]';

CREATE TABLE mif_t_ordinativo_spesa_disp_ente_benef (
 mif_ord_dispe_ben_id serial,
 mif_ord_id     integer not null,
 mif_ord_ord_id integer not null,
 mif_ord_dispe_codice_missione  varchar(50) not null,
 mif_ord_dispe_codice_programma varchar(50) not null,
 mif_ord_dispe_codice_economico varchar(50) null,
 mif_ord_dispe_codice_economico_imp varchar(100) null,
 mif_ord_dispe_codice_ue         varchar(50) null,
 mif_ord_dispe_cofog_codice      varchar(50) null,
 mif_ord_dispe_cofog_imp         varchar(100) null,
 mif_ord_dispe_trans_elem         varchar(100) null, -- coto
 mif_ord_dispe_codben              integer null,
 mif_ord_dispe_num_articolo        integer null,
 mif_ord_dispe_desc_pagamento      varchar(150) null,
 mif_ord_dispe_cod_bilancio        varchar(50) null,
 mif_ord_dispe_carte_corr          varchar(150) null,
 mif_ord_dispe_desc_forma_pagam    varchar(150) null,
 mif_ord_dispe_desc_abi            varchar(150) null,
 mif_ord_dispe_desc_cab            varchar(150) null,
 mif_ord_dispe_desc_cdc            varchar(150) null,
 mif_ord_dispe_desc_cod_bilancio   varchar(150) null,
 mif_ord_dispe_desc_tipofin        varchar(150) null,
 mif_ord_dispe_tipofin             varchar(50) null,
 mif_ord_dispe_finanz_mutuo        varchar(150) null,
 mif_ord_dispe_ragsoc              varchar(250) null,
 mif_ord_dispe_ragsoc_via          varchar(150) null,
 mif_ord_dispe_ragsoc_cap          varchar(10) null,
 mif_ord_dispe_ragsoc_comune       varchar(150) null,
 mif_ord_dispe_ragsoc_prov         varchar(150) null,
 mif_ord_dispe_ragsoc_codfisc      varchar(25) null,
 mif_ord_dispe_imp_ord_inc         varchar(35) null, -- coto
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa_dispe_benef PRIMARY KEY(mif_ord_dispe_ben_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_dispe_b FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_dispe_b FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_spesa_dispe_b FOREIGN KEY (mif_ord_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_disp_ente_benef
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa Dati a disposizione ente beneficiario ABI36/COTO]';



CREATE TABLE mif_t_ordinativo_spesa_disp_ente_quota (
 mif_ord_dispe_quota_id serial,
 mif_ord_id     integer not null,
 mif_ord_ord_id integer not null,
 mif_ord_dispe_qnum      varchar(50) not null,
 mif_ord_dispe_qdati_doc varchar(250) null,
 mif_ord_dispe_qimporto  varchar(50)  null,
 mif_ord_dispe_qimpegno varchar(250) null,
 mif_ord_dispe_qmutuo varchar(250) null,
 mif_ord_dispe_qannotazioni   varchar(250) null,
 mif_ord_dispe_qimpegno_prov  varchar(250) null,
 validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 validita_fine   TIMESTAMP WITHOUT TIME ZONE  NULL,
 data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
 data_cancellazione TIMESTAMP WITHOUT TIME ZONE  NULL,
 ente_proprietario_id INTEGER NOT NULL,
 login_operazione VARCHAR(200) NOT NULL,
 CONSTRAINT pk_mif_t_ordinativo_spesa_dispe_ente_quota PRIMARY KEY(mif_ord_dispe_quota_id),
 CONSTRAINT siac_t_ente_proprietario_mif_t_ordinativo_spesa_quota_e FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT mif_t_ordinativo_spesa_mif_t_ordinativo_spesa_dispe_b FOREIGN KEY (mif_ord_id)
    REFERENCES mif_t_ordinativo_spesa(mif_ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_ordinativo_mif_t_ordinativo_spesa_quota_m FOREIGN KEY (mif_ord_ord_id)
    REFERENCES siac_t_ordinativo(ord_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE mif_t_ordinativo_spesa_disp_ente_quota
IS 'Tabella di stage elaborazioni flussi MIF [Ordinativi Spesa Dati a disposizione ente beneficiario COTO-quote]';