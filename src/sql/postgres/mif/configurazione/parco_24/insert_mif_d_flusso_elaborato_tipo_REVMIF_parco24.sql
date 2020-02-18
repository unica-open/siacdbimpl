/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=24
and d.flusso_elab_mif_tipo_id in 
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='REVMIF')
order by d.flusso_elab_mif_ordine;

INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'Flusso_Documenti',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'Testata',NULL,true,'Flusso_Documenti',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select * from siac_t_ente_oil where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'Test_AID',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_aid','000000',false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'Test_ABI',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_abi','00000',false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'Test_Tipologia',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,'RV',false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'Test_Progressivo',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_progressivo','0001',false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'Test_DataMessaggio',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select to_char(NOW(), ''YYYYMMDD'')',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'Test_OraMessaggio',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select to_char(NOW(), ''HH24MI'')',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'Test_IdTLQWeb',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_IdTLQWeb','000000',false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (10,'Pacchetto_Mandati_Ritenute_Reversali',NULL,true,'Flusso_Documenti',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select * from mif_t_ordinativo_entrata where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'ordinativo_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'Testata_Reversali_InfoServ',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'estremi_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'codice_funzione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.estremi_reversale','siac_t_ordinativo_entrata','mif_ord_codice_funzione',NULL,true,NULL,'2016-01-01',24,'admin',1,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'numero_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.estremi_reversale','siac_t_ordinativo_entrata','mif_ord_numero',NULL,true,NULL,'2016-01-01',24,'admin',2,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'data_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.estremi_reversale','siac_t_ordinativo_entrata','mif_ord_data',NULL,true,NULL,'2016-01-01',24,'admin',3,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'importo_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.estremi_reversale','siac_t_ordinativo_entrata','mif_ord_importo',NULL,true,NULL,'2016-01-01',24,'admin',4,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'banca_italia_testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'tipo_contabilita',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.banca_italia_testata','siac_t_ordinativo_entrata','mif_ord_bci_tipo_contabil','O',true,NULL,'2016-01-01',24,'admin',5,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'tipo_entrata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.banca_italia_testata','siac_t_ordinativo_entrata','mif_ord_bci_tipo_entrata','F',true,NULL,'2016-01-01',24,'admin',6,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'numero_documento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata.banca_italia_testata','siac_t_ordinativo_entrata','mif_ord_bci_numero_doc',NULL,true,NULL,'2016-01-01',24,'admin',7,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'destinazione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.testata','siac_t_ordinativo_entrata','mif_ord_destinazione',NULL,true,NULL,'2016-01-01',24,'admin',8,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'InfoServizio_Testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'estremi_flusso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'codice_ABI_BT',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_codice_abi_bt','00000',true,NULL,'2016-01-01',24,'admin',9,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'codice_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente','06398410016',true,NULL,'2016-01-01',24,'admin',10,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'descrizione_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_desc_ente','Ente di Gestione Aree Protette del Po Torinese',true,NULL,'2016-01-01',24,'admin',11,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'codice_ente_BT',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_codice_ente_bt','0000000',true,NULL,'2016-01-01',24,'admin',12,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'esercizio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_anno_esercizio',NULL,true,NULL,'2016-01-01',24,'admin',13,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'identificativo_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_id_flusso_oil',NULL,true,NULL,'2016-01-01',24,'admin',14,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'data_ora_creazione_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_data_creazione_flusso',NULL,true,NULL,'2016-01-01',24,'admin',15,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'anno_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_entrata','mif_ord_anno_flusso',NULL,true,NULL,'2016-01-01',24,'admin',16,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'codice_struttura',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata','mif_t_ordinativo_entrata','mif_ord_codice_struttura',NULL,true,NULL,'2016-01-01',24,'admin',17,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'ente_localita',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata','mif_t_ordinativo_entrata','mif_ord_ente_localita','Moncalieri',true,NULL,'2016-01-01',24,'admin',18,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'ente_indirizzo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Testata_Reversali_InfoServ.InfoServizio_Testata','mif_t_ordinativo_entrata','mif_ord_ente_indirizzo','Corso Trieste 98',true,NULL,'2016-01-01',24,'admin',19,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'Reversali_InfoServ',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'progressivo_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale','mif_t_ordinativo_entrata','mif_ord_progr_vers','0000001',true,NULL,'2016-01-01',24,'admin',20,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'classificazioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'classificazione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.classificazioni',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'codice_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.classificazioni.classificazione','mif_t_ordinativo_entrata','mif_ord_class_codice_cge',NULL,true,'SIOPE_ENTRATA_I|XXXX','2016-01-01',24,'admin',21,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'importo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.classificazioni.classificazione','mif_t_ordinativo_entrata','mif_ord_class_importo',NULL,true,NULL,'2016-01-01',24,'admin',22,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'estremi_bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'codifica_bilancio','per coto  mif_ord_capitolo per esporre il numero del capitolo per gli altri mif_ord_codifica_bilancio per esporre il codice di bilancio
',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_codifica_bilancio',NULL,true,NULL,'2016-01-01',24,'admin',23,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'numero_articolo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_articolo',NULL,true,NULL,'2016-01-01',24,'admin',24,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'descrizione_codifica','mif_ord_desc_codifica per esporre la descri del capitolo
mif_ord_desc_codifica_bil per esporre descri della tipologia',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_desc_codifica_bil',NULL,true,NULL,'2016-01-01',24,'admin',25,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'gestione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_gestione','Competenza|Residuo',true,NULL,'2016-01-01',24,'admin',26,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'anno_residuo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_anno_res',NULL,true,NULL,'2016-01-01',24,'admin',27,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'importo_bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bilancio.estremi_bilancio','mif_t_ordinativo_entrata','mif_ord_importo_bil',NULL,true,NULL,'2016-01-01',24,'admin',28,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'anagrafica_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_anag_versante',NULL,true,NULL,'2016-01-01',24,'admin',29,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'indirizzo_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_indir_versante',NULL,true,NULL,'2016-01-01',24,'admin',30,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'cap_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_cap_versante',NULL,true,NULL,'2016-01-01',24,'admin',31,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'localita_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_localita_versante',NULL,true,NULL,'2016-01-01',24,'admin',32,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'provincia_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_prov_versante',NULL,true,NULL,'2016-01-01',24,'admin',33,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'partita_iva_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_partiva_versante',NULL,true,NULL,'2016-01-01',24,'admin',34,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'codice_fiscale_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versante','mif_t_ordinativo_entrata','mif_ord_codfisc_versante','9999999999999999',true,NULL,'2016-01-01',24,'admin',35,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'bollo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'esenzione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.bollo','mif_t_ordinativo_entrata','mif_ord_bollo_esenzione','S',true,NULL,'2016-01-01',24,'admin',36,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'versamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'tipo_riscossione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versamento','mif_t_ordinativo_entrata','mif_ord_vers_tipo_riscos','INCASSO PER CASSA',true,NULL,'2016-01-01',24,'admin',37,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'codice_riscossione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versamento','mif_t_ordinativo_entrata','mif_ord_vers_cod_riscos','51',true,NULL,'2016-01-01',24,'admin',38,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'importo_versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versamento','mif_t_ordinativo_entrata','mif_ord_vers_importo',NULL,true,NULL,'2016-01-01',24,'admin',39,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (66,'causale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.versamento','mif_t_ordinativo_entrata','mif_ord_vers_causale',NULL,true,NULL,'2016-01-01',24,'admin',40,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (67,'informazioni_aggiuntive',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'lingua',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.informazioni_aggiuntive','mif_t_ordinativo_entrata','mif_ord_lingua','I',true,NULL,'2016-01-01',24,'admin',41,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'riferimento_documento_esterno',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.informazioni_aggiuntive','mif_t_ordinativo_entrata','mif_ord_rif_doc_esterno','8',true,NULL,'2016-01-01',24,'admin',42,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'informazioni_tesoriere',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.informazioni_aggiuntive','mif_t_ordinativo_entrata','mif_ord_info_tesoriere',NULL,true,NULL,'2016-01-01',24,'admin',43,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'sospeso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'flag_copertura',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sospeso','mif_t_ordinativo_entrata','mif_ord_flag_copertura','S',true,NULL,'2016-01-01',24,'admin',44,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'ricevute',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sospeso',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select * from mif_t_ordinativo_entrata_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sospeso.ricevute',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'numero_ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sospeso.ricevute.ricevuta','mif_t_ordinativo_entrata_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2016-01-01',24,'admin',45,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'importo_ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sospeso.ricevute.ricevuta','mif_t_ordinativo_entrata_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2016-01-01',24,'admin',46,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'sostituzione_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale','mif_t_ordinativo_entrata','mif_ord_sost_rev',NULL,true,'SOS_ORD','2016-01-01',24,'admin',47,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'numero_reversale_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_num_ord_colleg',NULL,true,NULL,'2016-01-01',24,'admin',48,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'progressivo_reversale_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_progr_ord_colleg','0000001',true,NULL,'2016-01-01',24,'admin',49,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'esercizio_reversale_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.sostituzione_reversale','mif_t_ordinativo_entrata','mif_ord_anno_ord_colleg',NULL,true,NULL,'2016-01-01',24,'admin',50,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'dati_a_disposizione_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'elementi_progressivo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select * from mif_t_ordinativo_entrata_disp_ente where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id order by mif_ord_id, mif_ord_dispe_ordine',true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'elemento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'nome',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo.elemento','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_nome',NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'valore',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo.elemento','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'Capitolo origine',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',51,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (87,'Stanziamento Cassa','Residui Attivi per CMTO',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',52,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'Reversali Emesse','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',53,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'Disponibilita','CMTO/COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',54,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'Capitolo Peg','CMTO - Numero Capitolo  per COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',55,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'Numero Articolo','COTO/REGP',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',56,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'Vincoli di destinazione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',57,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'Vincolato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',58,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'Atto di riscossione','per COTO Determina di incasso',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,'CDR|CDC','2016-01-01',24,'admin',59,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'Numero mandato vincolato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',60,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'Data nascita versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',61,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (97,'Luogo nascita versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',62,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (98,'Prov nascita versante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',63,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (99,'Note',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',64,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (100,'mandati_associati','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo.mandati_associati',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (101,'mandato_associato','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (102,'numero_mandato','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.mandati_associati.mandato_associato','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',65,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (103,'progressivo_mandato','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.mandati_associati.mandato_associato','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore','0000001',true,NULL,'2016-01-01',24,'admin',66,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (104,'esercizio_mandato','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.mandati_associati.mandato_associato','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',67,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (105,'importo_mandato','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.mandati_associati.mandato_associato','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',68,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (106,'Mandati Stanziamento Rev','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',69,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (107,'Stanziamento Rev','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',70,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (108,'Codice Soggetto','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',71,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (109,'Carte corredo','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',72,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (110,'Tipo Finanziamento','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,'TIPO_FINANZIAMENTO','2016-01-01',24,'admin',73,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (111,'Descrizione tipo finanziamento','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',74,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (112,'Anagrafica versante','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',75,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (113,'Importo reversale lettere','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',76,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (114,'Numero quota reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',77,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (115,'Descrizione quota reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',78,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (116,'Data scadenza quota reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',79,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (117,'Importo quota reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',80,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (118,'Accertamento quota reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',81,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (119,'Descrizione accertamento quota reversale','REGP',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',82,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (120,'Determina accertamento quota reversale','Estremi provvedimento autorizzativo accertamento quota reversale per CMTO
Dati provvedimento accertamento quota reversale per REGP',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',83,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (121,'Codice Economico',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,'OI','2016-01-01',24,'admin',84,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (122,'Importo Codice Economico',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',85,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (123,'Codice Ue',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,'TRANSAZIONE_UE_ENTRATA','2016-01-01',24,'admin',86,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (124,'Codice Entrata',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',24,'admin',87,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (125,'Transazione Elementare','Indicazione della transazione elementare come stringa composita delle varie classificazioni',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.reversale.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_entrata_disp_ente','mif_ord_dispe_valore',NULL,true,'PDC_V|OI|TRANSAZIONE_UE_ENTRATA|SIOPE_ENTRATA_I|RICORRENTE_ENTRATA|PERIMETRO_SANITARIO_ENTRATA','2016-01-01',24,'admin',94,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (126,'InfoServizio_Reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',88,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (127,'InfSerRev_Accertamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale','mif_t_ordinativo_entrata','mif_ord_numero_acc',NULL,true,NULL,'2016-01-01',24,'admin',89,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (128,'InfSerRev_CodiceOperatore',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale','mif_t_ordinativo_entrata','mif_ord_code_operatore',NULL,true,NULL,'2016-01-01',24,'admin',90,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (129,'DescrizioneClassificazioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (130,'DescrizioneClassificazione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale.DescrizioneClassificazioni',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (131,'codice_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale.DescrizioneClassificazioni.DescrizioneClassificazione','mif_t_ordinativo_entrata','mif_ord_siope_codice_cge',NULL,true,'SIOPE_ENTRATA_I|XXXX','2016-01-01',24,'admin',91,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (132,'descr_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale.DescrizioneClassificazioni.DescrizioneClassificazione','mif_t_ordinativo_entrata','mif_ord_siope_descri_cge',NULL,true,NULL,'2016-01-01',24,'admin',92,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (133,'InfSerRev_DescrizioniEsteseCapitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (134,'InfSerRev_DescrizioneEstesaCapitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_reversale.Reversali_InfoServ.InfoServizio_Reversale.InfSerRev_DescrizioniEsteseCapitolo','mif_t_ordinativo_entrata','mif_ord_descri_estesa_cap',NULL,true,NULL,'2016-01-01',24,'admin',93,NULL,true,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (135,'dati_a_disposizione_ente_versante',NULL,false,'flusso_ordinativi.reversale.informazioni_versante',NULL,NULL,NULL,true,NULL,'2016-01-01',24,'admin',95,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (136,'altri_codici_identificativi',NULL,false,'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante',NULL,NULL,NULL,false,NULL,'2016-01-01',24,'admin',0,'select * from mif_t_ordinativo_entrata_disp_ente_vers where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (137,'codice_economico',NULL,false,'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi','mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico',NULL,true,'OI','2016-01-01',24,'admin',96,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (138,'importo_codice_economico',NULL,false,'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi','mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico_imp',NULL,true,NULL,'2016-01-01',24,'admin',97,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (139,'codice_ue',NULL,false,'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi','mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ue',NULL,true,'TRANSAZIONE_UE_ENTRATA','2016-01-01',24,'admin',98,NULL,false,51);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (140,'codice_entrata',NULL,false,'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi','mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_entrata',NULL,true,'RICORRENTE_ENTRATA','2016-01-01',24,'admin',99,NULL,false,51);
