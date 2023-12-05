/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

ALTER TABLE siac_r_ordinativo_firma
  ALTER COLUMN oil_ricevuta_id DROP NOT NULL;
ALTER TABLE siac_r_ordinativo_quietanza
  ALTER COLUMN oil_ricevuta_id DROP NOT NULL;

ALTER TABLE siac_r_ordinativo_storno
  ALTER COLUMN oil_ricevuta_id DROP NOT NULL;
