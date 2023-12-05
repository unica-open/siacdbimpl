/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table siac_dwh_programma_cronop

CREATE TABLE siac_dwh_programma_cronop
(
ente_proprietario_id    INTEGER,
ente_denominazione      VARCHAR(500),
data_elaborazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
programma_code          VARCHAR(200),
programma_desc          VARCHAR(500),
programma_stato_code    VARCHAR(200),
programma_stato_desc    VARCHAR(500),
programma_ambito_code   VARCHAR(200),
programma_ambito_desc   VARCHAR(500),
programma_rilevante_fpv VARCHAR(1),
programma_valore_complessivo   numeric,
programma_gara_data_indizione  TIMESTAMP WITHOUT TIME ZONE,
programma_gara_data_aggiudic           TIMESTAMP WITHOUT TIME ZONE,
programma_investimento_in_def            BOOLEAN,
programma_note                           VARCHAR(500),
programma_anno_atto_amm                  VARCHAR(4),
programma_num_atto_amm                   VARCHAR(500),
programma_oggetto_atto_amm               VARCHAR(500),
programma_note_atto_amm                  VARCHAR(500),
programma_code_tipo_atto_amm             VARCHAR(200),
programma_desc_tipo_atto_amm             VARCHAR(500),
programma_code_stato_atto_amm            VARCHAR(200),
programma_desc_stato_atto_amm            VARCHAR(500),
programma_code_cdr_atto_amm              VARCHAR(200),
programma_desc_cdr_atto_amm              VARCHAR(500),
programma_code_cdc_atto_amm              VARCHAR(200),
programma_desc_cdc_atto_amm              VARCHAR(500),
programma_cronop_bil_anno                varchar(4),
programma_cronop_tipo                    VARCHAR(1),
programma_cronop_versione                varchar(200),
programma_cronop_desc                    varchar(500),
programma_cronop_anno_comp               varchar(4),
programma_cronop_cap_tipo                VARCHAR(200),
programma_cronop_cap_articolo            VARCHAR(200),
programma_cronop_classif_bil             VARCHAR(200),
programma_cronop_anno_entrata            varchar(4),
programma_cronop_valore_prev             numeric,
-- siac-6255 Sofia 29.04.2019
-- siac_t_programma
programma_anno_bilancio                 VARCHAR(4),
programma_responsabile_unico            VARCHAR(500),
programma_spazi_finanziari              boolean,
programma_affidamento_code              VARCHAR(200),
programma_affidamento_desc              VARCHAR(500),
programma_tipo_code                     VARCHAR(200),
programma_tipo_code                     VARCHAR(500),
-- siac_t_cronop
programma_cronop_data_appfat	   TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_appdef	   TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_appesec      TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_avviopr      TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_agglav       TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_inizlav      TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_data_finelav      TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_giorni_dur		   integer,
programma_cronop_data_coll         TIMESTAMP WITHOUT TIME ZONE,
programma_cronop_gest_quad_eco       BOOLEAN,
programma_cronop_us_per_fpv_pr       BOOLEAN,
programma_cronop_ann_atto_amm       VARCHAR(4),
programma_cronop_num_atto_amm        VARCHAR(500),
programma_cronop_ogg_atto_amm               VARCHAR(500),
programma_cronop_nte_atto_amm                  VARCHAR(500),
programma_cronop_tpc_atto_amm             VARCHAR(200),
programma_cronop_tpd_atto_amm             VARCHAR(500),
programma_cronop_stc_atto_amm            VARCHAR(200),
programma_cronop_std_atto_amm            VARCHAR(500),
programma_cronop_crc_atto_amm              VARCHAR(200),
programma_cronop_crd_atto_amm              VARCHAR(500),
programma_cronop_cdc_atto_amm              VARCHAR(200),
programma_cronop_cdd_atto_amm              VARCHAR(500)
)
WITH (oids = false);



COMMENT ON TABLE siac_dwh_programma_cronop
IS 'Scarico programmi-cronoprammi validi';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code
IS 'Codice programma (siac_t_programma.programma_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc
IS 'Descrizione programma (siac_t_programma.programma_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_stato_code
IS 'Codice stato programma (siac_d_programma_stato.programma_stato_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_stato_desc
IS 'Descrizione stato programma (siac_d_programma_stato.programma_stato_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_ambito_code
IS 'Codice ambito programma (siac_t_class.classif_code [TIPO_AMBITO] siac_r_programma_class)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_ambito_desc
IS 'Descrizione ambito programma (siac_t_class.classif_desc [TIPO_AMBITO] siac_r_programma_class)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_rilevante_fpv
IS 'Rilevanza FPV  (siac_r_programma_attr.boolean, siac_t_attr [FlagRilevanteFPV])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_valore_complessivo
IS 'Importo complessivo programma (siac_r_programma_attr.numerico, siac_t_attr [ValoreComplessivoProgramma])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_gara_data_indizione
IS 'Data indizione gara  programma (siac_t_programma.programma_data_gara_indizione)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_gara_data_aggiudic
IS 'Data aggiudicazione gara  programma (siac_t_programma.programma_data_gara_aggiudicazione)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_investimento_in_def
IS 'Investimento in definizione per  programma (siac_t_programma.programma_investimento_in_def)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_note
IS 'Note  programma (siac_r_programma_attr.testo, siac_t_attr [Note])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_anno_atto_amm
IS 'Anno Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_anno)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_num_atto_amm
IS 'Numero Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_numero)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_oggetto_atto_amm
IS 'Oggetto Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_oggetto)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_note_atto_amm
IS 'Note Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_note)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_tipo_atto_amm
IS 'Codice tipo Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_tipo_id, siac_d_attoamm_tipo)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_tipo_atto_amm
IS 'Descrizione tipo Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm.attoamm_tipo_id, siac_d_attoamm_tipo)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_stato_atto_amm
IS 'Codice stato Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm , siac_d_atto_amm_stato)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_stato_atto_amm
IS 'Descrizione stato Atto amministrativo programma (siac_r_programma_atto_amm, siac_t_atto_amm , siac_d_atto_amm_stato)';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_cdr_atto_amm
IS 'Codice CDR Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDR])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_cdr_atto_amm
IS 'Descrizione CDR Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDR])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_code_cdr_atto_amm
IS 'Codice CDC Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDC])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_desc_cdr_atto_amm
IS 'Descrizione CDC Atto amministrativo programma (siac_r_programma_atto_amm, siac_r_atto_amm_class , siac_t_class [CDC])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_tipo
IS 'Cronoprogramma tipo  (Uscita [CAP-UP,CAP-UG], Entrata [CAP-EP,CAP-EG])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_cap_tipo
IS 'Cronoprogramma tipo capitolo associato (siac_t_cronop_elem.elem_tipo_id [CAP-UP,CAP-UG,CAP-EP,CAP-EG])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_versione
IS 'Cronoprogramma versione (siac_t_cronop.cronop_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_desc
IS 'Cronoprogramma descrizione (siac_t_cronop.cronop_desc)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_bil_anno
IS 'Cronoprogramma anno di bilancio (siac_t_cronop.bil_id [siac_t_periodo.anno])';


COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_anno_comp
IS 'Cronoprogramma anno di competenza (siac_t_cronop_elem_det.periodo_id [siac_t_periodo.anno])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_cap_articolo
IS 'Cronoprogramma capitolo-articolo (siac_t_cronop_elem.cronop_elem_code/siac_t_cronop_elem.cronop_elem_code)';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_classif_bil
IS 'Cronoprogramma classificazione bilancio capitolo-articolo ( titolo_code-tipologia_code,  siac_r_cronop_elem_class,siac_t_cronop_elem , siac_t_class [TIPOLOGIA])';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_anno_entrata
IS 'Cronoprogramma spesa, anno rif. entrata ( siac_t_cronop_elem_det.anno_entrata [CAP-UP,CAP-UG] )';

COMMENT ON COLUMN siac_dwh_programma_cronop.programma_cronop_valore_prev
IS 'Cronoprogramma valore di riferimento ( siac_t_cronop_elem_det.cronop_elem_det_importo )';