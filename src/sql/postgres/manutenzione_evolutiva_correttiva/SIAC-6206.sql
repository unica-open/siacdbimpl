/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_d_class_tipo (
			classif_tipo_code, 
            classif_tipo_desc,
            validita_inizio,
			ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
CROSS JOIN(VALUES ('CLASSIFICATORE_STIPENDI','STIPENDI')) as tmp(code, descr)
WHERE not exists (
 SELECT 1 FROM siac_d_class_tipo et
 WHERE et.classif_tipo_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.data_cancellazione is null);



 
 
 insert into siac_t_class (
			classif_code, 
            classif_desc,
            classif_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)
SELECT tmp.code, tmp.descr, dgt.classif_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_class_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('STI','Stipendi','CLASSIFICATORE_STIPENDI'), ('RT-STI','Ritenute stipendi','CLASSIFICATORE_STIPENDI')) as tmp(code, descr, tipo)
WHERE dgt.classif_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_t_class et
 WHERE et.classif_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.classif_tipo_id=dgt.classif_tipo_id
 and et.data_cancellazione is null); 
 
 
 
 
 
 
 
 
 INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-OIL-associaProvisoriCassa',
'Associa provvisori di cassa',
a.azione_tipo_id,
b.gruppo_azioni_id,
'/../siacboapp/azioneRichiesta.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=a.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='FUN_ACCESSORIE'
and not exists
(select 1 from siac_t_azione z
        where z.azione_code='OP-OIL-associaProvisoriCassa'
        and z.ente_proprietario_id=a.ente_proprietario_id
);
