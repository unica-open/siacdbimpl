/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿alter table migr_modpag add  codice_modpag_del    varchar(10);
alter table migr_soggetto ALTER COLUMN  partita_iva   type  varchar(50);
alter table migr_soggetto_scarto ALTER COLUMN  partita_iva   type  varchar(50);

-- 12.10.2015 dani tolto vincolo not null su sede secondaria ( per pvto che ha sedi senza via)
ALTER TABLE migr_sede_secondaria ALTER COLUMN via DROP NOT NULL;