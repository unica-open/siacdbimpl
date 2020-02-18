/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac_dwh_accertamento 
ADD COLUMN   data_inizio_val_stato_accer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_accer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_accer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_accer TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE siac_dwh_subaccertamento 
ADD COLUMN   data_inizio_val_stato_subaccer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_subaccer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_subaccer TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_subaccer TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE siac_dwh_impegno
ADD COLUMN   data_inizio_val_stato_imp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_imp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_imp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_imp TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE siac_dwh_subimpegno 
ADD COLUMN   data_inizio_val_stato_subimp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_subimp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_subimp TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_subimp TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE siac_dwh_liquidazione
ADD COLUMN   data_inizio_val_stato_liquidaz TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_liquidaz TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_liquidaz TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_liquidaz TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE  siac_dwh_ordinativo_incasso
ADD COLUMN   data_inizio_val_stato_ordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_ordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_ordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_ordin TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE  siac_dwh_subordinativo_incasso
ADD COLUMN   data_inizio_val_stato_ordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_subordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_subordin TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_subordin TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE  siac_dwh_ordinativo_pagamento
ADD COLUMN   data_inizio_val_stato_ordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_ordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_ordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_ordpg TIMESTAMP WITHOUT TIME ZONE;

ALTER TABLE  siac_dwh_subordinativo_pagamento
ADD COLUMN   data_inizio_val_stato_ordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_inizio_val_subordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_creazione_subordpg TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN   data_modifica_subordpg TIMESTAMP WITHOUT TIME ZONE;