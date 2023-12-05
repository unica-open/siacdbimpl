/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿ALTER TABLE MIGR_LIQUIDAZIONE ADD codice_progben varchar(10);
ALTER TABLE MIGR_LIQUIDAZIONE ALTER COLUMN numero_provvedimento DROP NOT NULL;
ALTER TABLE MIGR_LIQUIDAZIONE ALTER COLUMN anno_provvedimento DROP NOT NULL;
ALTER TABLE MIGR_LIQUIDAZIONE ADD numero_liquidazione_orig integer;
ALTER TABLE MIGR_LIQUIDAZIONE ADD anno_esercizio_orig varchar(4);
ALTER TABLE MIGR_LIQUIDAZIONE ADD data_emissione_orig varchar(10);

ALTER TABLE MIGR_LIQUIDAZIONE ADD codice_modpag_del	varchar(10);

ALTER TABLE MIGR_LIQUIDAZIONE ADD  sede_id INTEGER;

CREATE  INDEX idx_siac_t_migr_liquidazione ON migr_liquidazione
  USING btree (numero_liquidazione,anno_esercizio,ente_proprietario_id);
CREATE  INDEX idx_siac_t_migr_liquidazione_movgest ON migr_liquidazione
  USING btree (anno_impegno,numero_impegno,ente_proprietario_id);

-- 18.09.2015 nuovo campo
ALTER TABLE MIGR_LIQUIDAZIONE ADD numero_provvedimento_calcolato INTEGER;

-- 05.11.2015
CREATE INDEX idx_siac_t_migr_liquidazione_ente2 ON siac.migr_liquidazione
  USING btree (ente_proprietario_id,fl_elab);

-- 20.11.2015 aggiunto campo siope_spesa
ALTER TABLE migr_liquidazione ADD siope_spesa VARCHAR(50)  NULL;