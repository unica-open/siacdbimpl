/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿alter table migr_impegno add column parere_finanziario INTEGER;
alter table migr_accertamento add column parere_finanziario INTEGER;