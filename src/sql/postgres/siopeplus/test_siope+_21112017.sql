/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from siac_t_ente_oil oil
where oil.ente_proprietario_id=2

select *
from siac_d_pcc_ufficio uff
where uff.ente_proprietario_id=2
and   uff.pccuff_code='UFES06'

select mif.*
from mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato mif
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine

select mif.*
from  mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
--and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_t_ordinativo_spesa mif
where mif.mif_ord_flusso_elab_mif_id=1120

select *
from mif_t_ordinativo_spesa_documenti mif
where mif.mif_ord_id=25111

select *
from mif_t_ordinativo_entrata_id

delete from mif_t_ordinativo_entrata_id