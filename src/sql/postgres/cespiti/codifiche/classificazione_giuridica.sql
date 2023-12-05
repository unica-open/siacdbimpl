/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into	siac_d_cespiti_classificazione_giuridica
(ces_class_giu_code,  ces_class_giu_desc, validita_inizio, data_creazione, ente_proprietario_id,  login_operazione)
SELECT tmp.code, tmp.descr,to_timestamp('2016-01-01', 'YYYY-MM-DD'), now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep           
CROSS JOIN(VALUES ('1','BENE DISPONIBILE'), ('2','BENE INDISPONIBILE'), ('3','BENE DEMANIALE')) as tmp(code, descr)
WHERE not exists (
 SELECT 1 FROM siac_d_cespiti_classificazione_giuridica et
 WHERE et.ces_class_giu_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.data_cancellazione is null); 