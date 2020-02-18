/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 20.06.2018 siac-6175

alter table siac_dwh_ordinativo_pagamento add ord_da_trasmettere boolean;

alter table siac_dwh_ordinativo_incasso   add ord_da_trasmettere boolean;