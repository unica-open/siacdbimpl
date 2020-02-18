/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select * from fnc_siac_bko_crea_sac_00_ente (16,to_timestamp('01/01/2013','01/01/2013')::timestamp)


select * from siac_d_class_tipo
where ente_proprietario_id=16
-- 1392 CDC
-- 1429 CDR

select * from siac_t_class
where classif_tipo_id in ( 1429, 1392)