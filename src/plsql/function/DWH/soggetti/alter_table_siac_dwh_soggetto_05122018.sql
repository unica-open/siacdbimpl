/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*soggetto_tipo_fonte_durc CHAR(1),
soggetto_fine_validita_durc DATE,
soggetto_fonte_durc_manuale_classif_id INTEGER,
soggetto_fonte_durc_automatica TEXT,
soggetto_note_durc TEXT,*/

-- 05.12.2018 Sofia SIAC-6261
alter table  siac_dwh_soggetto
  add soggetto_tipo_fonte_durc varchar(1),
  add soggetto_fonte_durc_automatica varchar(500),
  add soggetto_note_durc varchar(500),
  add soggetto_fine_validita_durc TIMESTAMP WITHOUT TIME ZONE,
  add soggetto_fonte_durc_manuale_code varchar(200),
  add soggetto_fonte_durc_manuale_desc varchar(500);


