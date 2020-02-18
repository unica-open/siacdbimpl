/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 19.04.2016 Sofia eseguito in prod bilmult
insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
(select 'SBLOCCA_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO',tipo.validita_inizio,tipo.login_operazione,tipo.ente_proprietario_id
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.data_cancellazione is null
 and   not exists (select 1 from mif_d_flusso_elaborato_tipo tipo1
 				   where tipo1.ente_proprietario_id=tipo.ente_proprietario_id
                   and   tipo1.flusso_elab_mif_tipo_code='SBLOCCA_MIF'
                   and   tipo1.data_cancellazione is null));

-- 22 righe

insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
(select 'RITRASM_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO',tipo.validita_inizio,tipo.login_operazione,tipo.ente_proprietario_id
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.data_cancellazione is null
 and   not exists (select 1 from mif_d_flusso_elaborato_tipo tipo1
 				   where tipo1.ente_proprietario_id=tipo.ente_proprietario_id
                   and   tipo1.flusso_elab_mif_tipo_code='RITRASM_MIF'
                   and   tipo1.data_cancellazione is null));

-- 22


select *
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.flusso_elab_mif_tipo_code in ('SBLOCCA_MIF','RITRASM_MIF')
 and   tipo.data_cancellazione is null