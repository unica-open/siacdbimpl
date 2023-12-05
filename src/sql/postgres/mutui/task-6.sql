/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


ALTER TABLE siac_t_soggetto ADD column IF NOT EXISTS istituto_di_credito bool NOT NULL DEFAULT false;