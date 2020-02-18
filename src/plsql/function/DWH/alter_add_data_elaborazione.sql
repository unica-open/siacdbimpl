/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac.siac_dwh_accertamento
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_capitolo_entrata
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_capitolo_spesa
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_documento_entrata
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_documento_spesa
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_impegno
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_liquidazione
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_ordinativo_incasso
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_ordinativo_pagamento
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_programma
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_soggetto
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_subaccertamento
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_subimpegno
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_subordinativo_incasso
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_subordinativo_pagamento
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_vincolo
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();
ALTER TABLE siac.siac_dwh_iva
ADD COLUMN data_elaborazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now();