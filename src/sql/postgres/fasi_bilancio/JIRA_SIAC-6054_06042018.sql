/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 06.04.2018 Sofia JIRA SIAC-6054

alter table fase_bil_t_reimputazione_vincoli
 add mod_tipo_code VARCHAR,
 add reimputazione_anno integer