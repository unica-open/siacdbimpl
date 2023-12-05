/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
alter table siac_dwh_accertamento add flag_attiva_gsa varchar(1);

alter table siac_dwh_subaccertamento add flag_attiva_gsa varchar(1);