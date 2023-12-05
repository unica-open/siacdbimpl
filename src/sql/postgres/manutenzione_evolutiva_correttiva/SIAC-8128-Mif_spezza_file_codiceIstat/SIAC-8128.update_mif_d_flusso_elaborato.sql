/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_param='0000101|800000619',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code in ('MANDMIF_SPLUS','REVMIF_SPLUS')
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='codice_istat_ente';

update mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null limit 1',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%mif_t_ordinativo_spesa%limit 1%'
and   mif.flusso_elab_mif_query not like '%anno_esercizio%';

update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null limit 1',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%anno_esercizio%limit 1%';


update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%anno_esercizio%limit%OFFSET%';

begin;
update mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null limit 1',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%mif_t_ordinativo_entrata%limit 1%'
and   mif.flusso_elab_mif_query not like '%anno_esercizio%';

update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null limit 1',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%anno_esercizio%limit 1%';


update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_query='select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and mif_ord_anno_esercizio=:mif_ord_anno_esercizio and mif_ord_codice_ente_istat=:mif_ord_codice_ente_istat and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',
        data_modifica=now(),
        login_operazione=mif.login_operazione||'-SIAC-8128'
from  mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_query like '%anno_esercizio%limit%OFFSET%';