/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from fase_bil_d_elaborazione_tipo tipo 
where tipo.ente_Proprietario_id=2

-- da g anno-1  a  p anno  gp    - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
-- da g anno     a  p anno  GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti 
-- da p anno     a  g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
insert into fase_bil_d_elaborazione_tipo
(
 fase_bil_elab_tipo_code,
 fase_bil_elab_tipo_desc,
 fase_bil_elab_tipo_param,
 validita_inizio ,
 login_operazione ,
 ente_proprietario_id 
)
select 'APE_GEST_ALL_PROGRAMMI',
			'APERTURA BILANCIO : ALLINEAMENTO PROGRAMMI-CRONOP',
			'gp|GP|PG',
			now(),
			'SIAC-8633',
			ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from fase_bil_d_elaborazione_tipo tipo 
where tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.fase_bil_elab_tipo_code ='APE_GEST_ALL_PROGRAMMI'
and      tipo.data_cancellazione is null 
and      tipo.validita_fine is null 
);


fase_bil_t_elaborazione

select nextval('fase_bil_t_elaborazione_fase_bil_elab_id_seq')