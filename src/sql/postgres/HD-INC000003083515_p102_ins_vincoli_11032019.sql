/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 11.03.2019 Sofia HD-INC000003083515_p102
--  HD-INC000003083515_p102_ins_vincoli_11032019.sql

select tipo.avav_tipo_code,tipo.avav_tipo_desc, av.*
from siac_d_avanzovincolo_tipo tipo,siac_t_avanzovincolo av
where tipo.ente_proprietario_id=14
and   av.avav_tipo_id=tipo.avav_tipo_id