/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 06.11.2017 Sofia - attivazione siope-plus
-- CONFIGURAZIONE ENTE
-- ATTIVAZIONE SIOPE+
-- da eseguire solo in fase di attivazione effettiva

update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=2
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   r.gestione_livello_id=d.gestione_livello_id
and   dnew.ente_proprietario_id=d.ente_proprietario_id
and   dnew.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.data_cancellazione is null
and   r.validita_fine is null;


update siac_t_ente_oil e
set    ente_oil_siope_plus=true
where e.ente_proprietario_id=2;

update mif_d_flusso_elaborato_tipo tipo
set   flusso_elab_mif_nome_file='RicSisC_RS'
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='RICFIMIF';