/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 19.04.2018 Sofia JIRA SIAC-5934, 6067, 6097


alter table mif_t_ordinativo_sbloccato
add mif_ord_spostamento_data TIMESTAMP WITHOUT TIME ZONE,
add mif_ord_data_firma TIMESTAMP WITHOUT TIME ZONE,
add mif_ord_emissione_data TIMESTAMP WITHOUT TIME ZONE;



alter table mif_t_ordinativo_sbloccato_log
add mif_ord_inizio_st_firma TIMESTAMP WITHOUT TIME ZONE,
add    mif_ord_fine_st_firma TIMESTAMP WITHOUT TIME ZONE;

alter table mif_t_ordinativo_sbloccato_log
add mif_ord_spostamento_data  TIMESTAMP WITHOUT TIME ZONE;

alter table siac_t_ente_oil
add ente_oil_invio_escl_annulli boolean default false not null;

begin;
update siac_t_ente_oil oil
set    ente_oil_invio_escl_annulli=true
where oil.ente_oil_siope_plus=true;


update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CSI|CO|6|REGOLARIZZAZIONE|COMPENSAZIONE|DISPOSIZIONE DOCUMENTO ESTERNO|F24EP|ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A|ACCREDITO CONTO CORRENTE POSTALE'
where mif.flusso_elab_mif_code='creditore_effettivo'
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
);