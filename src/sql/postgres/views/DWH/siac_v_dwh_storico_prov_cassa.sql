/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop VIEW if exists siac.siac_v_dwh_storico_prov_cassa;
CREATE OR REPLACE VIEW siac.siac_v_dwh_storico_prov_cassa
(
    ente_proprietario_id,
    ente_denominazione,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    sac_code,
	sac_desc,
	sac_tipo_code,
	sac_tipo_desc,
	provc_data_invio_servizio,
	validita_inizio_storico,
	validita_fine_storico
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione, 
       tipo.provc_tipo_code,
       tipo.provc_tipo_desc,
       p.provc_anno,
       p.provc_numero,
       s.sac_code,
       s.sac_desc,
       s.sac_tipo_code,
       s.sac_tipo_desc,
       s.provc_data_invio_servizio,
       s.validita_inizio,
       s.validita_fine
from siac_s_prov_cassa  s ,siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo,
     siac_t_ente_proprietario ente
where  tipo.ente_proprietario_id=ente.ente_proprietario_id 
and    p.provc_tipo_id=tipo.provc_tipo_id
and    s.provc_id=p.provc_id
and    p.data_cancellazione is null
and    s.data_cancellazione is null;


alter view siac.siac_v_dwh_storico_prov_cassa OWNER to siac;
