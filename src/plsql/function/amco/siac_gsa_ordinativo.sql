/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop table if exists siac.siac_gsa_ordinativo;

 CREATE TABLE siac.siac_gsa_ordinativo
 (
	ente_proprietario_id integer NOT NULL,
	anno_bilancio integer NOT NULL,
	data_elaborazione timestamp NULL DEFAULT now(),	
	ord_tipo    varchar(1),
	ord_anno  integer,
	ord_numero numeric,
	ord_desc varchar(500),
	ord_stato_code varchar(10),
	ord_data_emissione varchar(8),
	ord_data_firma  varchar(8),
	ord_data_quietanza varchar(8),
	ord_data_annullo varchar(8),
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
    liq_anno integer,
    liq_numero integer,
    liq_attoamm_tipo_code  varchar(5) NULL,
    liq_attoamm_anno integer,
    liq_attoamm_numero integer,
    liq_attoamm_sac  varchar(6) NULL
)
WITH (oids = false);

CREATE INDEX siac_gsa_ordinativo_ente_idx ON siac.siac_gsa_ordinativo USING btree (ente_proprietario_id);

CREATE INDEX siac_gsa_ordinativo_anno_tipo_ente_idx ON siac.siac_gsa_ordinativo USING btree (anno_bilancio,ord_tipo, ente_proprietario_id);


COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_tipo
IS 'ord_tipo_code=OP-U, OI-E';


COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_anno
IS 'siac_gsa_ordinativo*.ord_anno';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_numero
IS 'siac_gsa_ordinativo*.ord_numero';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_desc
IS 'siac_gsa_ordinativo*.ord_desc';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_stato_code
IS 'siac_gsa_ordinativo*.ord_stato_code';


COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_data_emissione
IS 'siac_gsa_ordinativo*.ord_data_emissione';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_data_firma
IS 'siac_gsa_ordinativo*.ord_data_firma';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_data_quietanza
IS 'siac_gsa_ordinativo*.ord_data_quietanza';


COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_data_annullo
IS 'siac_gsa_ordinativo*.ord_data_annullo';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.numero_capitolo
IS 'siac_gsa_ordinativo*.numero_capitolo';
 
COMMENT ON COLUMN siac.siac_gsa_ordinativo.numero_articolo
IS 'siac_gsa_ordinativo*.numero_articolo';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.capitolo_desc
IS 'siac_gsa_ordinativo*.capitolo_desc';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.soggetto_code
IS 'siac_gsa_ordinativo*.soggetto_code';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.soggetto_desc
IS 'siac_gsa_ordinativo*.soggetto_desc';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.pdc_fin_liv_1
IS 'siac_gsa_ordinativo*.pdc_fin_liv_1';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.pdc_fin_liv_2
IS 'siac_gsa_ordinativo*.pdc_fin_liv_2';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.pdc_fin_liv_3
IS 'siac_gsa_ordinativo*.pdc_fin_liv_3';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.pdc_fin_liv_4
IS 'siac_gsa_ordinativo*.pdc_fin_liv_4';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.pdc_fin_liv_5
IS 'siac_gsa_ordinativo*.pdc_fin_liv_5';




COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_sub_numero
IS 'siac_gsa_ordinativo*.ord_sub_numero';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_sub_desc
IS 'siac_gsa_ordinativo*.ord_sub_desc';


COMMENT ON COLUMN siac.siac_gsa_ordinativo.ord_sub_importo
IS 'siac_gsa_ordinativo*.ord_sub_importo';


COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_anno
IS 'siac_gsa_ordinativo*.movgest_anno';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_numero
IS 'siac_gsa_ordinativo*.movgest_numero';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_sub_numero
IS 'siac_gsa_ordinativo*.movgest_sub_numero';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_attoamm_tipo_code
IS 'siac_gsa_ordinativo*.movgest_attoamm_tipo_code';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_attoamm_anno
IS 'siac_gsa_ordinativo*.movgest_attoamm_anno';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_attoamm_numero
IS 'siac_gsa_ordinativo*.movgest_attoamm_numero';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.movgest_attoamm_sac
IS 'siac_gsa_ordinativo*.movgest_attoamm_sac';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_anno
IS 'siac_gsa_ordinativo_pagamento.liq_anno per ord_tipo_code=U';
COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_numero
IS 'siac_gsa_ordinativo_pagamento.liq_numero per ord_tipo_code=U';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_attoamm_tipo_code
IS 'siac_gsa_ordinativo_pagamento.liq_attoamm_tipo_code per ord_tipo_code=U, siac_gsa_ordinativo_incasso.ord_attoamm_tipo_code per ord_tipo_code=E';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_attoamm_anno
IS 'siac_gsa_ordinativo_pagamento.liq_attoamm_anno per   per ord_tipo_code=U, siac_gsa_ordinativo_incasso.ord_attoamm_anno per ord_tipo_code=E';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_attoamm_numero
IS 'siac_gsa_ordinativo_pagamento.liq_attoamm_numero per   per ord_tipo_code=U, siac_gsa_ordinativo_incasso.ord_attoamm_numero per ord_tipo_code=E';

COMMENT ON COLUMN siac.siac_gsa_ordinativo.liq_attoamm_sac
IS 'siac_gsa_ordinativo_pagamento.liq_attoamm_sac per   per ord_tipo_code=U, siac_gsa_ordinativo_incasso.ord_attoamm_sac per ord_tipo_code=E';


