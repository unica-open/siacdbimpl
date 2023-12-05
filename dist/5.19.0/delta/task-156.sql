/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


/*
*Paolo Simone
*/
UPDATE siac_t_soggetto SET istituto_di_credito = FALSE WHERE istituto_di_credito IS NULL;
ALTER TABLE siac.siac_t_soggetto ALTER COLUMN istituto_di_credito SET NOT NULL;
