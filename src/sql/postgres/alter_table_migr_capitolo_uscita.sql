/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿alter table migr_capitolo_uscita add dicuiimpegnato_anno1 NUMERIC DEFAULT 0 NOT NULL;

alter table migr_capitolo_uscita add dicuiimpegnato_anno2 NUMERIC DEFAULT 0 NOT NULL;
alter table migr_capitolo_uscita add dicuiimpegnato_anno3 NUMERIC DEFAULT 0 NOT NULL;

-- Davide - 30.03.016
alter table migr_capitolo_uscita add trasferimenti_comunitari varchar(1) default null;
alter table migr_capitolo_uscita add funzioni_delegate        varchar(1) default null;

-- DAVIDE - 22.08.2016 - aggiunto per COTO, PVTO
alter table migr_capitolo_uscita add spesa_ricorrente varchar(50);
