 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
 
update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FTV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD01') and ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id)),
	doc_tipo_s_id = (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCD' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD04') and ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FAT' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  (
'TD01',
'TD02',
'TD22',
'TD23',
'TD24',
'TD25',
'TD26'
)
and  ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD03')
and  ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NTE' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD05')
and  ente_proprietario_id in (2,15);

update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD06')
and  ente_proprietario_id in (2,15);