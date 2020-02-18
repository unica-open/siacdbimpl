/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 20.12.2016 Sofia
insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('SBLOCCA_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO','2016-01-01','batch',&ente);


insert into mif_d_flusso_elaborato_tipo
(flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc, flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RITRASM_MIF','ELABORAZIONI SBLOCCO DATI MIF MANDMIF-REVMIF','NO FLUSSO','2016-01-01','batch',&ente);

-- 22


 select *
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.flusso_elab_mif_tipo_code in ('SBLOCCA_MIF','RITRASM_MIF')
 and   tipo.ente_proprietario_id=&ente