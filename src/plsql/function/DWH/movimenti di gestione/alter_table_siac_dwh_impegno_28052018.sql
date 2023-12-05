/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

alter table siac_dwh_impegno add flag_attiva_gsa varchar(1);

alter table siac_dwh_subimpegno add flag_attiva_gsa varchar(1);