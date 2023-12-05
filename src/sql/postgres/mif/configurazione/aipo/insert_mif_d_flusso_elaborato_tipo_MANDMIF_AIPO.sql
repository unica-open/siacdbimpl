/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=4
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'Flusso_Documenti',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'Testata',NULL,true,'Flusso_Documenti',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from siac_t_ente_oil where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'Test_AID',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_aid','001278',false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'Test_ABI',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_abi','02008',false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'Test_Tipologia',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,'MP',false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'Test_Progressivo',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_progressivo','0001',false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'Test_DataMessaggio',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select to_char(NOW(), ''YYYYMMDD'')',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'Test_OraMessaggio',NULL,true,'Flusso_Documenti.Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select to_char(NOW(), ''HH24MI'')',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'Test_IdTLQWeb',NULL,true,'Flusso_Documenti.Testata','siac_t_ente_oil','ente_oil_IdTLQWeb','001278',false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (10,'Pacchetto_Mandati_Ritenute_Reversali',NULL,true,'Flusso_Documenti',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'ordinativo_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'Testata_Mandati_InfoServ',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'estremi_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'codice_funzione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_codice_funzione',NULL,true,NULL,'2016-01-01',4,'admin',1,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'numero_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_numero',NULL,true,NULL,'2016-01-01',4,'admin',2,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'data_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_data',NULL,true,NULL,'2016-01-01',4,'admin',3,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'importo_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_importo',NULL,true,NULL,'2016-01-01',4,'admin',4,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'flg_finanza_locale',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_flag_fin_loc',NULL,true,NULL,'2016-01-01',4,'admin',5,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'numero_documento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_mandato','mif_t_ordinativo_spesa','mif_ord_documento',NULL,true,NULL,'2016-01-01',4,'admin',6,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'banca_italia_testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'tipo_contabilita_ente_pagante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.banca_italia_testata','mif_t_ordinativo_spesa','mif_ord_bci_tipo_ente_pag','O',true,NULL,'2016-01-01',4,'admin',7,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'destinazione_ente_pagante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.banca_italia_testata','mif_t_ordinativo_spesa','mif_ord_bci_dest_ente_pag','F',true,NULL,'2016-01-01',4,'admin',8,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'conto_tesoreria',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata','mif_t_ordinativo_spesa','mif_ord_bci_conto_tes',NULL,true,NULL,'2016-01-01',4,'admin',9,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'estremi_atto',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'estremi_provvedimento_autorizzativo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_atto','mif_t_ordinativo_spesa','mif_ord_estremi_attoamm','',true,'SPR|ALG','2016-01-01',4,'admin',10,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'codice_ufficio_responsabile',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_atto','mif_t_ordinativo_spesa','mif_ord_codice_uff_resp',NULL,true,NULL,'2016-01-01',4,'admin',11,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'data_provvedimento_autorizzativo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_atto','mif_t_ordinativo_spesa','mif_ord_data_attoamm',NULL,true,NULL,'2016-01-01',4,'admin',12,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'responsabile_provvedimento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_atto','mif_t_ordinativo_spesa','mif_ord_resp_attoamm',NULL,true,NULL,'2016-01-01',4,'admin',13,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'ufficio_responsabile',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.testata.estremi_atto','mif_t_ordinativo_spesa','mif_ord_uff_resp_attomm',NULL,true,NULL,'2016-01-01',4,'admin',14,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'InfoServizio_Testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'estremi_flusso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'codice_ABI_BT',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_codice_abi_bt','02008',true,NULL,'2016-01-01',4,'admin',15,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'codice_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente','92116650349',true,NULL,'2016-01-01',4,'admin',16,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'descrizione_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_desc_ente','AGENZIA INTERREG. FIUME PO',true,NULL,'2016-01-01',4,'admin',17,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'codice_ente_BT',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_codice_ente_bt','9032006',true,NULL,'2016-01-01',4,'admin',18,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'esercizio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_anno_esercizio',NULL,true,NULL,'2016-01-01',4,'admin',19,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'identificativo_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_id_flusso_oil',NULL,true,NULL,'2016-01-01',4,'admin',20,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'data_ora_creazione_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_data_creazione_flusso',NULL,true,NULL,'2016-01-01',4,'admin',21,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'anno_flusso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.estremi_flusso','mif_t_ordinativo_spesa','mif_ord_anno_flusso',NULL,true,NULL,'2016-01-01',4,'admin',22,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'codice_struttura',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_codice_struttura',NULL,true,NULL,'2016-01-01',4,'admin',23,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'progressivo_mandato_struttura',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_progr_ord_struttura',NULL,true,NULL,'2016-01-01',4,'admin',24,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'ente_localita',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_ente_localita','PARMA',true,NULL,'2016-01-01',4,'admin',25,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'ente_indirizzo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_ente_indirizzo','VIA GARIBALDI,75',true,NULL,'2016-01-01',4,'admin',26,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'codice_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_codice_cge',NULL,true,'','2016-01-01',4,'admin',27,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'descr_cge',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_descr_cge',NULL,true,NULL,'2016-01-01',4,'admin',28,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'Tipo_Contabilita',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata','mif_t_ordinativo_spesa','mif_ord_tipo_contabilita',NULL,true,NULL,'2016-01-01',4,'admin',29,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'AltriDati_Enti_Testata',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'codice_raggruppamento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Testata_Mandati_InfoServ.InfoServizio_Testata.AltriDati_Enti_Testata','mif_t_ordinativo_spesa','mif_ord_codice_raggrup',NULL,true,'ALG|CDR','2016-01-01',4,'admin',30,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'Mandati_Ritenute_InfoServ',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'progressivo_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_progr_benef','0000001',true,NULL,'2016-01-01',4,'admin',31,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'Impignorabili',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_progr_impignor',NULL,true,NULL,'2016-01-01',4,'admin',32,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'Destinazione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_progr_dest',NULL,true,NULL,'2016-01-01',4,'admin',33,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'banca_italia_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'numero_conto_banca_italia_ente_ricevente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.banca_italia_mandato','mif_t_ordinativo_spesa','mif_ord_bci_conto',NULL,true,'CBI','2016-01-01',4,'admin',34,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'tipo_contabilita_ente_ricevente',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.banca_italia_mandato','mif_t_ordinativo_spesa','mif_ord_bci_tipo_contabil',NULL,true,NULL,'2016-01-01',4,'admin',35,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'classificazioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'classificazione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'codice_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cge',NULL,true,'','2016-01-01',4,'admin',36,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'importo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_importo',NULL,true,NULL,'2016-01-01',4,'admin',37,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'Codice_cup',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cup',NULL,true,NULL,'2016-01-01',4,'admin',38,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'Codice_cpv',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cpv',NULL,true,NULL,'2016-01-01',4,'admin',39,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'gestione_provvisoria',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_prov',NULL,true,NULL,'2016-01-01',4,'admin',40,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'frazionabile',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.classificazioni.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_fraz',NULL,true,NULL,'2016-01-01',4,'admin',41,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (66,'bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (67,'estremi_bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'codifica_bilancio','per coto  mif_ord_capitolo per esporre il numero del capitolo per gli altri mif_ord_codifica_bilancio per esporre il codice di bilancio
',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_codifica_bilancio',NULL,true,NULL,'2016-01-01',4,'admin',42,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'numero_articolo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_articolo',NULL,true,NULL,'2016-01-01',4,'admin',43,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'voce_economica',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_voce_eco',NULL,true,NULL,'2016-01-01',4,'admin',44,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'descrizione_codifica','mif_ord_desc_codifica per esporre la descri del capitolo
mif_ord_desc_codifica_bil per esporre descri del programma',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_desc_codifica_bil',NULL,true,NULL,'2016-01-01',4,'admin',45,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'gestione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_gestione','Competenza|Residuo',true,'','2016-01-01',4,'admin',46,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'anno_residuo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_anno_res',NULL,true,'N','2016-01-01',4,'admin',47,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'importo_bilancio',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_importo_bil',NULL,true,NULL,'2016-01-01',4,'admin',48,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'stanziamento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_stanz',NULL,true,NULL,'2016-01-01',4,'admin',49,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'mandati_stanziamento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_stanz',NULL,true,NULL,'2016-01-01',4,'admin',50,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'disponibilita_capitolo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_disponibilita',NULL,true,NULL,'2016-01-01',4,'admin',51,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'previsione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_prev',NULL,true,'E','2016-01-01',4,'admin',52,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'mandati_previsione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_prev',NULL,true,NULL,'2016-01-01',4,'admin',53,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'disponibilita_cassa',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bilancio.estremi_bilancio','mif_t_ordinativo_spesa','mif_ord_disp_cassa',NULL,true,NULL,'2016-01-01',4,'admin',54,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa',NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'anagrafica_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_benef',NULL,true,'CBI','2016-01-01',4,'admin',55,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'indirizzo_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_benef',NULL,true,NULL,'2016-01-01',4,'admin',56,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'cap_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_benef',NULL,true,NULL,'2016-01-01',4,'admin',57,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'localita_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_benef',NULL,true,NULL,'2016-01-01',4,'admin',58,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'provincia_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_benef',NULL,true,NULL,'2016-01-01',4,'admin',59,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (87,'stato_beneficiario','per conformita ABI36',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',NULL,true,NULL,'2016-01-01',4,'admin',185,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'partita_iva_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_benef',NULL,true,NULL,'2016-01-01',4,'admin',60,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'codice_fiscale_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_benef','9999999999999999',true,NULL,'2016-01-01',4,'admin',61,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'beneficiario_quietanzante',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_benef_quiet',NULL,true,'CSI','2016-01-01',4,'admin',62,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'anagrafica_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_anag_quiet',NULL,true,NULL,'2016-01-01',4,'admin',63,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'indirizzo_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_indir_quiet',NULL,true,NULL,'2016-01-01',4,'admin',64,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'cap_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_cap_quiet',NULL,true,NULL,'2016-01-01',4,'admin',65,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'localita_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_localita_quiet',NULL,true,NULL,'2016-01-01',4,'admin',66,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'provincia_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_prov_quiet',NULL,true,NULL,'2016-01-01',4,'admin',67,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'partita_iva_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_partiva_quiet',NULL,true,NULL,'2016-01-01',4,'admin',68,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (97,'codice_fiscale_ben_quiet',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario_quietanzante','mif_t_ordinativo_spesa','mif_ord_codfisc_quiet','9999999999999999',true,NULL,'2016-01-01',4,'admin',69,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (98,'delegati',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (99,'delegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati','mif_t_ordinativo_spesa','mif_ord_delegato',NULL,true,'CO','2016-01-01',4,'admin',70,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (100,'anagrafica_delegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati.delegato','mif_t_ordinativo_spesa','mif_ord_anag_del',NULL,true,NULL,'2016-01-01',4,'admin',71,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (101,'codice_fiscale_delegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati.delegato','mif_t_ordinativo_spesa','mif_ord_codfisc_del','9999999999999999',true,NULL,'2016-01-01',4,'admin',72,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (102,'cap_delegato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati.delegato','mif_t_ordinativo_spesa','mif_ord_cap_del',NULL,true,NULL,'2016-01-01',4,'admin',73,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (103,'localita_delegato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati.delegato','mif_t_ordinativo_spesa','mif_ord_localita_del',NULL,true,NULL,'2016-01-01',4,'admin',74,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (104,'provincia_delegato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.delegati.delegato','mif_t_ordinativo_spesa','mif_ord_prov_del',NULL,true,NULL,'2016-01-01',4,'admin',75,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (105,'avviso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_avviso',NULL,true,'CO|TIPO_AVVISO','2016-01-01',4,'admin',76,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (106,'invio_avviso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.avviso','mif_t_ordinativo_spesa','mif_ord_invio_avviso','B',true,NULL,'2016-01-01',4,'admin',77,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (107,'codice_fiscale_avviso',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.avviso','mif_t_ordinativo_spesa','mif_ord_codfisc_avviso',NULL,true,NULL,'2016-01-01',4,'admin',78,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (108,'piazzatura',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_piazzatura',NULL,true,'2|CB|CCP|2|I|VB','2016-01-01',4,'admin',79,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (109,'abi_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_abi_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',80,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (110,'cab_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cab_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',81,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (111,'numero_conto_corrente_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',82,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (112,'caratteri_controllo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_ctrl_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',83,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (113,'codice_cin',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cin_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',84,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (114,'codice_paese',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cod_paese_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',85,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (115,'denominazione_banca_destinataria',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_denom_banca_benef',NULL,true,'CB','2016-01-01',4,'admin',86,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (116,'conto_corrente_postale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_postale_benef',NULL,true,'CCP','2016-01-01',4,'admin',87,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (117,'conto_corrente_estero',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef_estero',NULL,true,'CB','2016-01-01',4,'admin',88,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (118,'codice_swift',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_swift_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',89,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (119,'coordinate_iban',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_iban_benef',NULL,true,'CB|IT','2016-01-01',4,'admin',90,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (120,'codice_ente_beneficiario',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_cod_ente_benef',NULL,true,NULL,'2016-01-01',4,'admin',91,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (121,'flag_pagamento_condizionato',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.piazzatura','mif_t_ordinativo_spesa','mif_ord_fl_pagam_cond_benef',NULL,true,NULL,'2016-01-01',4,'admin',92,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (122,'sepa_credit_transfer',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,'1|CB|SEPA','2016-01-01',4,'admin',194,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (123,'iban',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',NULL,true,NULL,'2016-01-01',4,'admin',195,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (124,'bic',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',NULL,true,NULL,'2016-01-01',4,'admin',196,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (125,'identificativo_end_to_end',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_id_end_tr',NULL,true,NULL,'2016-01-01',4,'admin',197,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (126,'ritenute',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa_ritenute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (127,'ritenuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (128,'tipo_ritenuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute.ritenuta','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_tipo','R|P',true,'RIT_ORD|SPR|SUB_ORD|IRPEF|INPS','2016-01-01',4,'admin',93,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (129,'importo_ritenuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute.ritenuta','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_importo',NULL,true,NULL,'2016-01-01',4,'admin',94,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (130,'numero_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute.ritenuta','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_numero',NULL,true,NULL,'2016-01-01',4,'admin',95,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (131,'progressivo_reversale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute.ritenuta','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rev','0000001',true,NULL,'2016-01-01',4,'admin',96,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (132,'progressivo_ritenuta',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.ritenute.ritenuta','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rit',NULL,true,NULL,'2016-01-01',4,'admin',97,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (133,'bollo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (134,'esenzione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_esenzione','S|N',true,'2|ES|99','2016-01-01',4,'admin',98,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (135,'carico_bollo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico',NULL,true,'2|SB|B|SI|I','2016-01-01',4,'admin',99,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (136,'causale_esenzione_bollo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ordin_bollo_caus_esenzione',NULL,true,NULL,'2016-01-01',4,'admin',100,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (137,'Importo_bollo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo',NULL,true,NULL,'2016-01-01',4,'admin',101,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (138,'carico_spese',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico_spe',NULL,true,NULL,'2016-01-01',4,'admin',102,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (139,'importo_spese',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo_spe',NULL,true,NULL,'2016-01-01',4,'admin',103,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (140,'commissioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (141,'carico_commissioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.commissioni','mif_t_ordinativo_spesa','mif_ord_commissioni_carico',NULL,true,'3|CE|C|BN|B|ES|E','2016-01-01',4,'admin',104,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (142,'importo_commissioni',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.commissioni','mif_t_ordinativo_spesa','mif_ord_commissioni_importo',NULL,true,NULL,'2016-01-01',4,'admin',105,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (143,'pagamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (144,'tipo_pagamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_tipo',NULL,true,'IT|CB|CON|SEPA','2016-01-01',4,'admin',106,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (145,'codice_pagamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_code',NULL,true,NULL,'2016-01-01',4,'admin',107,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (146,'importo_beneficiario',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_importo',NULL,true,NULL,'2016-01-01',4,'admin',108,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (147,'causale',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_causale',NULL,true,NULL,'2016-01-01',4,'admin',109,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (148,'data_esecuzione_pagamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_data_esec',NULL,true,NULL,'2016-01-01',4,'admin',110,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (149,'data_scadenza_pagamento',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_data_scad',NULL,true,NULL,'2016-01-01',4,'admin',111,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (150,'flag_valuta_antergata',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_flag_val_ant',NULL,true,NULL,'2016-01-01',4,'admin',112,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (151,'divisa_estera_conversione',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_divisa_estera',NULL,true,NULL,'2016-01-01',4,'admin',113,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (152,'flag_assegno_circolare',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_flag_ass_circ',NULL,true,NULL,'2016-01-01',4,'admin',114,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (153,'flag_vaglia_postale',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.pagamento','mif_t_ordinativo_spesa','mif_ord_pagam_flag_vaglia',NULL,true,NULL,'2016-01-01',4,'admin',115,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (154,'informazioni_aggiuntive',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (155,'lingua',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_lingua','I',true,NULL,'2016-01-01',4,'admin',116,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (156,'riferimento_documento_esterno',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_rif_doc_esterno','8',true,NULL,'2016-01-01',4,'admin',117,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (157,'informazioni_tesoriere',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_info_tesoriere',NULL,true,NULL,'2016-01-01',4,'admin',118,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (158,'tipo_utenza',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_tipo_utenza',NULL,true,NULL,'2016-01-01',4,'admin',119,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (159,'codifica_utenza',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_codice_ute',NULL,true,NULL,'2016-01-01',4,'admin',120,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (160,'codice_generico',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_cod_generico',NULL,true,NULL,'2016-01-01',4,'admin',121,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (161,'sospeso',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (162,'flag_copertura',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sospeso','mif_t_ordinativo_spesa','mif_ord_flag_copertura','S',true,'5|MF|AP|AV|TE|DP','2016-01-01',4,'admin',122,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (163,'ricevute',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sospeso',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (164,'ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sospeso.ricevute',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (165,'numero_ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sospeso.ricevute.ricevuta','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2016-01-01',4,'admin',123,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (166,'importo_ricevuta',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sospeso.ricevute.ricevuta','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2016-01-01',4,'admin',124,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (167,'sostituzione_mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato','mif_t_ordinativo_spesa','mif_ord_sost_mand',NULL,true,'SOS_ORD','2016-01-01',4,'admin',125,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (168,'numero_mandato_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_num_ord_colleg',NULL,true,NULL,'2016-01-01',4,'admin',126,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (169,'progressivo_mandato_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_colleg','0000001',true,NULL,'2016-01-01',4,'admin',127,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (170,'esercizio_mandato_collegato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_anno_ord_colleg',NULL,true,NULL,'2016-01-01',4,'admin',128,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (171,'dati_a_disposizione_ente',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (172,'elementi_progressivo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id order by mif_ord_id, mif_ord_dispe_ordine',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (173,'elemento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (174,'nome',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo.elemento',NULL,'mif_ord_dispe_nome',NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (175,'valore',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo.elemento',NULL,'mif_ord_dispe_valore',NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (176,'Capitolo origine',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',129,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (177,'Numero articolo capitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',130,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (178,'Descrizione articolo capitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',131,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (179,'Somme non soggette','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'ES','2016-01-01',4,'admin',132,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (180,'Codice tributo','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'IRPEF','2016-01-01',4,'admin',133,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (181,'Causale 770','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',134,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (182,'Data nascita beneficiario','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',135,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (183,'Luogo nascita beneficiario','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',136,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (184,'Prov nascita beneficiario','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',137,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (185,'Note',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',138,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (186,'Descrizione tipo pagamento',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',139,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (187,'Descrizione atto autorizzativo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',140,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (188,'Capitolo Peg','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',141,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (189,'Vincoli di destinazione','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',142,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (190,'Vincolato','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',143,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (191,'Voce Economica','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',144,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (192,'Numero distinta bilancio','REGP REGPENTI',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',145,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (193,'Data scadenza interna',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',146,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (194,'Numero reversale vincolata','REGP REGPENTI',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'SUB_ORD','2016-01-01',4,'admin',147,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (195,'Atto Contabile',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'ALG','2016-01-01',4,'admin',148,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (196,'Liquidazione','CMTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',149,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (197,'Codice Missione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',4,'admin',150,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (198,'Codice Programma',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA','2016-01-01',4,'admin',151,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (199,'Codice Economico',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'OP','2016-01-01',4,'admin',152,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (200,'Importo Codice Economico',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',153,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (201,'Codice Ue',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',4,'admin',154,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (202,'Codice Cofog',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'GRUPPO_COFOG','2016-01-01',4,'admin',155,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (203,'Importo Cofog',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',156,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (204,'Transazione Elementare','Indicazione della transazione elementare come stringa composita delle varie classificazioni',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA|PDC_V|OP|GRUPPO_COFOG|TRANSAZIONE_UE_SPESA|SIOPE_SPESA_I|cup|RICORRENTE_SPESA|PERIMETRO_SANITARIO_SPESA|POLITICHE_REGIONALI_UNITARIE','2016-01-01',4,'admin',184,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (205,'Anagrafica Beneficiario','Indicazione del beneficiario in caso di pagamento per girofondo Banca Italia',true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',157,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (206,'Codice Soggetto','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',158,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (207,'Carte Corredo','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',159,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (208,'Descrizione ABI','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',160,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (209,'Descrizione CAB','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',161,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (210,'Tipo Finanziamento','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'TIPO_FINANZIAMENTO','2016-01-01',4,'admin',162,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (211,'Descrizione tipo finanziamento','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',163,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (212,'Importo mandato lettere','COTO',false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',164,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (213,'Numero quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',165,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (214,'Descrizione quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',166,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (215,'Data scadenza quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',167,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (216,'Importo quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',168,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (217,'Documento collegato quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',169,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (218,'Impegno quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',170,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (219,'Descrizione impegno quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',171,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (220,'Dati provvedimento impegno quota mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente.elementi_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',4,'admin',172,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (221,'InfoServizio_Mandato',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (222,'InfSerMan_Impegno',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (223,'InfSerMan_NumeroImpegno',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_Impegno','mif_t_ordinativo_spesa','mif_ord_numero_imp',NULL,true,NULL,'2016-01-01',4,'admin',173,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (224,'InfSerMan_SubImpegno',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_Impegno','mif_t_ordinativo_spesa','mif_ord_numero_subimp',NULL,true,NULL,'2016-01-01',4,'admin',174,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (225,'InfSerMan_CodiceOperatore',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato','mif_t_ordinativo_spesa','mif_ord_code_operatore',NULL,true,NULL,'2016-01-01',4,'admin',175,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (226,'InfSerMan_NomeOperatore',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato','mif_t_ordinativo_spesa','mif_ord_nome_operatore',NULL,true,NULL,'2016-01-01',4,'admin',176,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (227,'InfSerMan_Fatture',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa_documenti where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (228,'InfSerMan_Fattura_Descr',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_Fatture','mif_t_ordinativo_spesa_documenti','mif_ord_documento',NULL,true,'30|FAT|FPR','2016-01-01',4,'admin',177,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (229,'InfSerMan_DescrizioniEsteseCapitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (230,'InfSerMan_DescrizioneEstesaCapitolo',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_DescrizioniEsteseCapitolo','mif_t_ordinativo_spesa','mif_ord_descri_estesa_cap',NULL,true,NULL,'2016-01-01',4,'admin',178,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (231,'InfSerMan_DescrCapitolo',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_DescrizioniEsteseCapitolo.InfSerMan_DescrizioneEstesaCapitolo','mif_t_ordinativo_spesa','mif_ord_descri_cap',NULL,true,NULL,'2016-01-01',4,'admin',179,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (232,'InfSerMan_ProgSpesa',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_DescrizioniEsteseCapitolo','mif_t_ordinativo_spesa','mif_ord_prog_cap',NULL,true,NULL,'2016-01-01',4,'admin',180,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (233,'InfSerMan_TipoSpesa',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.InfSerMan_DescrizioniEsteseCapitolo','mif_t_ordinativo_spesa','mif_ord_tipo_cap',NULL,true,NULL,'2016-01-01',4,'admin',181,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (234,'DescrizioneClassificazioni',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (235,'DescrizioneClassificazione',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.DescrizioneClassificazioni',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (236,'codice_cge',NULL,true,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.DescrizioneClassificazioni.DescrizioneClassificazione','mif_t_ordinativo_spesa','mif_ord_siope_codice_cge',NULL,true,'SIOPE_SPESA_I|XXXX','2016-01-01',4,'admin',182,NULL,true,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (237,'descr_cge',NULL,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.InfoServizio_Mandato.DescrizioneClassificazioni.DescrizioneClassificazione','mif_t_ordinativo_spesa','mif_ord_siope_descri_cge',NULL,true,NULL,'2016-01-01',4,'admin',183,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (238,'dati_a_disposizione_ente_beneficiario',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2016-01-01',4,'admin',186,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (239,'altri_codici_identificativi',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente_benef where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (240,'codice_missione',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_missione',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',4,'admin',187,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (241,'codice_programma',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_programma',NULL,true,'PROGRAMMA','2016-01-01',4,'admin',188,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (242,'codice_economico',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico',NULL,true,'OP','2016-01-01',4,'admin',189,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (243,'importo_codice_economico',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico_imp',NULL,true,NULL,'2016-01-01',4,'admin',190,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (244,'codice_ue',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_ue',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',4,'admin',191,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (254,'cofog',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',NULL,NULL,NULL,false,NULL,'2016-01-01',4,'admin',0,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (255,'codice_cofog',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_codice',NULL,true,'GRUPPO_COFOG','2016-01-01',4,'admin',192,NULL,false,31);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (256,'importo_cofog',NULL,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_imp',NULL,true,NULL,'2016-01-01',4,'admin',193,NULL,false,31);
