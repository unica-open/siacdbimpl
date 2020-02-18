/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select mif.*
from mif_d_flusso_elaborato mif
where mif.flusso_elab_mif_code = 'invio_avviso'
and   EXISTS
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=mif.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
order by mif.ente_proprietario_id, mif.flusso_elab_mif_ordine


begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='C'
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code = 'invio_avviso'
and   mif.flusso_elab_mif_default is not null
and   mif.flusso_elab_mif_default='B';
