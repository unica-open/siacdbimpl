/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿insert into fase_bil_d_elaborazione_tipo
(
	fase_bil_elab_tipo_code,
    fase_bil_elab_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    'APE_GEST_VINCOLI',
    'APERTURA BILANCIO : RIBALTAMENTO VINCOLI',
    now(),
    'admin',
    e.ente_proprietario_id
from siac_t_ente_proprietario e
where not exists
(select 1
 from fase_bil_d_elaborazione_tipo tipo
 where tipo.ente_proprietario_id=e.ente_proprietario_id
 and   tipo.fase_bil_elab_tipo_code='APE_GEST_VINCOLI');