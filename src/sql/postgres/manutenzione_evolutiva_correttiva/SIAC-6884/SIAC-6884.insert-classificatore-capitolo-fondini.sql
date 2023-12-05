/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--update desc classificatore3
update siac.siac_d_class_tipo set classif_tipo_desc='Capitolo Budget' 
where classif_tipo_code='CLASSIFICATORE_3' and ente_proprietario_id in 
(select ente_proprietario_id from siac.siac_t_ente_proprietario);

--insert values for Capitolo fondini
insert into siac.siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '01','SI', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac.siac_d_class_tipo tipo,  siac.siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac.siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='01'
  )


insert into siac.siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '02','NO', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac.siac_d_class_tipo tipo,  siac.siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac.siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='02'
  )
