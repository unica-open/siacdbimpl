/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

insert into fase_bil_d_elaborazione_tipo  
(
fase_bil_elab_tipo_code, 
fase_bil_elab_tipo_desc ,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select 'APE_PREV_VINCOLI',
            'APERTURA BILANCIO PREVISIONE: ALLINEAMENTO VINCOLI',
            now(),
            'SIAC-TASK-234',
            ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (3,4,5,10,16)
and      not exists 
(
select 1 
from fase_bil_d_elaborazione_tipo  tipo 
where tipo.ente_proprietario_id =ente.ente_proprietario_id 
and     tipo.fase_bil_elab_tipo_code ='APE_PREV_VINCOLI'
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
);