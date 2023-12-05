/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table if exists siac.siac_gsa_ordinativo_incasso;

CREATE TABLE siac.siac_gsa_ordinativo_incasso
(
	ente_proprietario_id integer NOT NULL,
	anno_bilancio integer NOT NULL,
	data_elaborazione timestamp NULL DEFAULT now(),	
	ord_anno  integer,
	ord_numero numeric,
	ord_desc varchar(500),
	ord_stato_code varchar(10),
	ord_data_emissione timestamp,
	ord_data_firma  timestamp,
	ord_data_quietanza timestamp,
	ord_data_annullo timestamp,
    numero_capitolo integer,
    numero_articolo integer,
    capitolo_desc  varchar(500) NULL,
    soggetto_code integer,
    soggetto_desc  varchar(500) NULL,
   	pdc_fin_liv_1  varchar(16) NULL,
	pdc_fin_liv_2  varchar(16) NULL,
	pdc_fin_liv_3  varchar(16) NULL,
	pdc_fin_liv_4  varchar(16) NULL,
    pdc_fin_liv_5  varchar(16) NULL,
	ord_sub_numero integer, 
	ord_sub_importo numeric,
	ord_sub_desc  varchar(500) NULL,
    movgest_anno integer,
    movgest_numero integer,
    movgest_sub_numero integer,
	movgest_gsa boolean default false,
    movgest_attoamm_tipo_code  varchar(5) NULL,
    movgest_attoamm_anno integer,
    movgest_attoamm_numero integer,
    movgest_attoamm_sac  varchar(6) NULL,
    ord_attoamm_tipo_code  varchar(5) NULL,
    ord_attoamm_anno integer,
    ord_attoamm_numero integer,
    ord_attoamm_sac  varchar(6) NULL
)
WITH (oids = false);

CREATE INDEX siac_gsa_ordinativo_inc_anno_ente_idx ON siac.siac_gsa_ordinativo_incasso USING btree (anno_bilancio, ente_proprietario_id);

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_anno
IS 'siac_t_ordinativo.ord_anno';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_numero
IS 'siac_t_ordinativo.ord_num';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_desc
IS 'siac_t_ordinativo.ord_desc';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_stato_code
IS 'siac_d_ordinativo_stato.ord_stato_code';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_data_emissione
IS 'siac_t_ordinativo.ord_emissione_data';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_data_firma
IS 'siac_r_ordinativo_firma.ord_firma_data';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_data_quietanza
IS 'siac_r_ordinativo_quietanza.ord_quietanza_data';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_data_annullo
IS 'siac_r_ordinativo_stato.validita_inizio per siac_d_ordinativo_stato.ord_stato_code=''A''';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.numero_capitolo
IS 'siac_t_bil_elem.elem_code per siac_r_ordinativo_bil_elem.elem_id';
 
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.numero_articolo
IS 'siac_t_bil_elem.elem_code2 per siac_r_ordinativo_bil_elem.elem_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.capitolo_desc
IS 'siac_t_bil_elem.elem_desc per siac_r_ordinativo_bil_elem.elem_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.soggetto_code
IS 'siac_t_soggetto.soggetto_code per siac_r_ordinativo_soggetto.soggetto_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.soggetto_desc
IS 'siac_t_soggetto.soggetto_desc per siac_r_ordinativo_soggetto.soggetto_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.pdc_fin_liv_1
IS 'siac_t_class.classif_code per siac_r_ordinativo_class.classif_id siac_d_class_tipo.classif_tipo_code=PDC_I';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.pdc_fin_liv_2
IS 'siac_t_class.classif_code per siac_r_ordinativo_class.classif_id siac_d_class_tipo.classif_tipo_code=PDC_II';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.pdc_fin_liv_3
IS 'siac_t_class.classif_code per siac_r_ordinativo_class.classif_id siac_d_class_tipo.classif_tipo_code=PDC_III';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.pdc_fin_liv_4
IS 'siac_t_class.classif_code per siac_r_ordinativo_class.classif_id siac_d_class_tipo.classif_tipo_code=PDC_IV';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.pdc_fin_liv_5
IS 'siac_t_class.classif_code per siac_r_ordinativo_class.classif_id siac_d_class_tipo.classif_tipo_code=PDC_V';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_sub_numero
IS 'siac_t_ordinativo_ts.ord_ts_code';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_sub_desc
IS 'siac_t_ordinativo_ts.ord_ts_desc';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_sub_importo
IS 'siac_t_ordinativo_ts_det.ord_ts_det_importo per siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code=''A''';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_anno
IS 'siac_t_movgest.movgest_anno per siac_t_movgest_ts.movgest_id, siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_numero
IS 'siac_t_movgest.movgest_numero per siac_t_movgest_ts.movgest_id, siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';
COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_sub_numero
IS 'siac_t_movgest_ts.movgest_ts_code per siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_attoamm_tipo_code
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code per siac_t_atto_amm, siac_r_movgest_ts_atto_amm,  siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_attoamm_anno
IS 'siac_t_atto_amm.attoamm_anno per  siac_r_movgest_ts_atto_amm,  siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_attoamm_numero
IS 'siac_t_atto_amm.attoamm_numero per  siac_r_movgest_ts_atto_amm,  siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.movgest_attoamm_sac
IS 'siac_t_class.classif_code  per  siac_d_class_tipo.classif_tipo_code CDC,CDR siac_r_atto_amm_class, siac_r_movgest_ts_atto_amm,  siac_r_liquidazione_movgest.movgest_ts_id,siac_r_liquidazione_ord [liq_id,sord_id],siac_t_ordiantivo_ts.ord_ts_id';


COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_attoamm_tipo_code
IS 'siac_d_atto_amm_tipo.attoamm_tipo_code per siac_t_atto_amm, siac_r_ordinativo_atto_amm';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_attoamm_anno
IS 'siac_t_atto_amm.attoamm_anno per siac_r_ordinativo_atto_amm';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_attoamm_numero
IS 'siac_t_atto_amm.attoamm_numero per  siac_r_ordinativo_atto_amm';

COMMENT ON COLUMN siac.siac_gsa_ordinativo_incasso.ord_attoamm_sac
IS 'siac_t_class.classif_code per siac_d_class_tipo.classif_tipo_code CDC,CDR siac_r_atto_amm_class.classif_id,siac_r_ordinativo_atto_amm';


