/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2015-01-01','admin',2);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2015-01-01','admin',2);


--delete from mif_d_flusso_elaborato where ente_proprietario_id=15

-- da eseguire dopo avere caricato i dati con CSV
update mif_d_flusso_elaborato  set
       flusso_elab_mif_tipo_id= (select t.flusso_elab_mif_tipo_id  from mif_d_flusso_elaborato_tipo t where t.flusso_elab_mif_tipo_code='MANDMIF' and t.ente_proprietario_id=15)

update mif_d_flusso_elaborato set ente_proprietario_id=15


--- flussi ritorno
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('RICQUMIF','Flusso acquisizione ricevute quietanze-storni ordinativi','EMAP','2015-01-01','admin',2);

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RICFIMIF','Flusso acquisizione ricevute firme ordinativi','EMFE','2015-01-01','admin',2);

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('RICPCMIF','Flusso acquisizione ricevute provvisori di cassa ordinativi','EMAT','2015-01-01','admin',2);