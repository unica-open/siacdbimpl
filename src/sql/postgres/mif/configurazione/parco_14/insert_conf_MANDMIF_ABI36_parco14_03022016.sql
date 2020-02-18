/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'flusso_ordinativi',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'testata',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT 1',false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'codice_ABI_BT',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_abi_bt','05584',true,NULL,'2016-01-01',14,'admin',15,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'identificativo_flusso',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_id_flusso_oil',NULL,true,NULL,'2016-01-01',14,'admin',20,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'data_ora_creazione_flusso',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_data_creazione_flusso',NULL,true,NULL,'2016-01-01',14,'admin',21,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'codice_ente',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_ente','95000120063',true,NULL,'2016-01-01',14,'admin',16,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'descrizione_ente',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_desc_ente','Ente di Gestione delle Aree Protette del Po Vercellese-Alessandrino',true,NULL,'2016-01-01',14,'admin',17,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'codice_ente_BT',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_ente_bt','617708',true,NULL,'2016-01-01',14,'admin',18,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'esercizio',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_anno_esercizio',NULL,true,NULL,'2016-01-01',14,'admin',19,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'mandati',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'mandato',NULL,true,'flusso_ordinativi.mandati',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'tipo_operazione','codice_funzione',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_funzione',NULL,true,'4|I|INSERIMENTO|A|ANNULLO|N|ANNULLO|S|SOSTITUZIONE','2016-01-01',14,'admin',1,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'numero_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero',NULL,true,NULL,'2016-01-01',14,'admin',2,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'data_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_data',NULL,true,NULL,'2016-01-01',14,'admin',3,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'importo_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_importo',NULL,true,NULL,'2016-01-01',14,'admin',4,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'flg_finanza_locale','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_flag_fin_loc',NULL,true,NULL,'2016-01-01',14,'admin',5,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'numero_documento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_documento',NULL,true,NULL,'2016-01-01',14,'admin',6,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'tipo_contabilita_ente_pagante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_tipo_ente_pag',NULL,true,NULL,'2016-01-01',14,'admin',7,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'destinazione_ente_pagante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_dest_ente_pag',NULL,true,NULL,'2016-01-01',14,'admin',8,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'conto_evidenza','conto_tesoreria',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_conto_tes',NULL,true,NULL,'2016-01-01',14,'admin',9,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'estremi_provvedimento_autorizzativo','estremi_provvedimento_autorizzativo',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_estremi_attoamm',NULL,true,'SPR|ALG','2016-01-01',14,'admin',10,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'codice_ufficio_responsabile','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_uff_resp',NULL,true,NULL,'2016-01-01',14,'admin',11,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'data_provvedimento_autorizzativo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_data_attoamm',NULL,true,NULL,'2016-01-01',14,'admin',12,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'responsabile_provvedimento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_resp_attoamm',NULL,true,NULL,'2016-01-01',14,'admin',13,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'ufficio_responsabile','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_uff_resp_attomm',NULL,true,NULL,'2016-01-01',14,'admin',14,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'anno_flusso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_anno_flusso',NULL,true,NULL,'2016-01-01',14,'admin',22,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'codice_struttura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_struttura',NULL,true,NULL,'2016-01-01',14,'admin',23,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'progressivo_mandato_struttura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_struttura',NULL,true,NULL,'2016-01-01',14,'admin',24,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'ente_localita','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_ente_localita',NULL,true,NULL,'2016-01-01',14,'admin',25,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'ente_indirizzo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_ente_indirizzo',NULL,true,NULL,'2016-01-01',14,'admin',26,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'codice_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_cge',NULL,true,NULL,'2016-01-01',14,'admin',27,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'descr_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descr_cge',NULL,true,NULL,'2016-01-01',14,'admin',28,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'Tipo_Contabilita','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_tipo_contabilita',NULL,true,NULL,'2016-01-01',14,'admin',29,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'codice_raggruppamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_raggrup',NULL,true,NULL,'2016-01-01',14,'admin',30,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'bilancio',NULL,true,'flusso_ordinativi.mandati.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'codifica_bilancio','per coto  mif_ord_capitolo per esporre il numero del capitolo per gli altri mif_ord_codifica_bilancio per esporre il codice di bilancio
',true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_codifica_bilancio',NULL,true,NULL,'2016-01-01',14,'admin',42,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'numero_articolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_articolo',NULL,true,NULL,'2016-01-01',14,'admin',43,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'voce_economica','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_voce_eco',NULL,true,NULL,'2016-01-01',14,'admin',44,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'descrizione_codifica','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_desc_codifica',NULL,true,NULL,'2016-01-01',14,'admin',45,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'gestione',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_gestione','COMPETENZA|RESIDUO',true,NULL,'2016-01-01',14,'admin',46,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'anno_residuo',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_anno_res',NULL,true,'S','2016-01-01',14,'admin',47,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'importo_bilancio',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_importo_bil',NULL,true,NULL,'2016-01-01',14,'admin',48,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'stanziamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_stanz',NULL,true,NULL,'2016-01-01',14,'admin',49,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'mandati_stanziamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_stanz',NULL,true,NULL,'2016-01-01',14,'admin',50,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'disponibilita_capitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_disponibilita',NULL,true,NULL,'2016-01-01',14,'admin',51,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'previsione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_prev',NULL,true,'','2016-01-01',14,'admin',52,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'mandati_previsione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_prev',NULL,true,NULL,'2016-01-01',14,'admin',53,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'disponibilita_cassa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_disp_cassa',NULL,true,NULL,'2016-01-01',14,'admin',54,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'informazioni_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'progressivo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_benef','1',true,NULL,'2016-01-01',14,'admin',31,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'importo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_importo',NULL,true,NULL,'2016-01-01',14,'admin',108,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'tipo_pagamento',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_tipo',NULL,true,'IT|CB|CT|SEPA','2016-01-01',14,'admin',106,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'Impignorabili','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_impignor',NULL,true,NULL,'2016-01-01',14,'admin',32,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'destinazione','Destinazione',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_dest','LIBERA',true,NULL,'2016-01-01',14,'admin',33,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'data_esecuzione_pagamento',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_esec',NULL,true,NULL,'2016-01-01',14,'admin',110,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'numero_conto_banca_italia_ente_ricevente',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_conto',NULL,true,'CBI','2016-01-01',14,'admin',34,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'tipo_contabilita_ente_ricevente',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_tipo_contabil',NULL,true,NULL,'2016-01-01',14,'admin',35,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'classificazione',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'codice_cgu','codice_cge',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cge',NULL,true,'','2016-01-01',14,'admin',36,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'importo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_importo',NULL,true,NULL,'2016-01-01',14,'admin',37,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'Codice_cup','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_cup',NULL,true,NULL,'2016-01-01',14,'admin',38,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'Codice_cpv','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_cpv',NULL,true,NULL,'2016-01-01',14,'admin',39,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'gestione_provvisoria','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_prov',NULL,true,NULL,'2016-01-01',14,'admin',40,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'frazionabile','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_fraz',NULL,true,NULL,'2016-01-01',14,'admin',41,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (66,'bollo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (67,'esenzione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_esenzione',NULL,true,NULL,'2016-01-01',14,'admin',98,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'assoggettamento_bollo','carico_bollo',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico',NULL,true,'3|99|ESENTE BOLLO|AI|ESENTE BOLLO|SB|ASSOGGETTATO BOLLO A CARICO BENEFICIARIO','2016-01-01',14,'admin',99,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'causale_esenzione_bollo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ordin_bollo_caus_esenzione',NULL,true,NULL,'2016-01-01',14,'admin',100,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'Importo_bollo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo',NULL,true,NULL,'2016-01-01',14,'admin',101,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'carico_spese','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico_spe',NULL,true,NULL,'2016-01-01',14,'admin',102,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'importo_spese','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo_spe',NULL,true,NULL,'2016-01-01',14,'admin',103,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'spese','commissioni',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'soggetto_destinatario_delle_spese','carico_commissioni',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_carico',NULL,true,'3|CE|A CARICO ENTE|BN|A CARICO BENEFICIARIO|ES|ESENTE','2016-01-01',14,'admin',104,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'importo_commissioni','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_importo',NULL,true,NULL,'2016-01-01',14,'admin',105,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'anagrafica_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_benef',NULL,true,'CBI','2016-01-01',14,'admin',55,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'indirizzo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_benef',NULL,true,NULL,'2016-01-01',14,'admin',56,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'cap_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_benef',NULL,true,NULL,'2016-01-01',14,'admin',57,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'localita_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_benef',NULL,true,NULL,'2016-01-01',14,'admin',58,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'provincia_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_benef',NULL,true,NULL,'2016-01-01',14,'admin',59,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'stato_beneficiario','vedasi piazzatura.codice_paese',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',NULL,true,NULL,'2016-01-01',14,'admin',185,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'partita_iva_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_benef',NULL,true,NULL,'2016-01-01',14,'admin',60,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'codice_fiscale_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_benef','9999999999999999',true,NULL,'2016-01-01',14,'admin',61,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'beneficiario_quietanzante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_benef_quiet',NULL,true,'CSI','2016-01-01',14,'admin',62,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'anagrafica_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_quiet',NULL,true,NULL,'2016-01-01',14,'admin',63,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (87,'indirizzo_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_quiet',NULL,true,NULL,'2016-01-01',14,'admin',64,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'cap_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_quiet',NULL,true,NULL,'2016-01-01',14,'admin',65,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'localita_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_quiet',NULL,true,NULL,'2016-01-01',14,'admin',66,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'provincia_ben_quiet',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_quiet',NULL,true,NULL,'2016-01-01',14,'admin',67,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'partita_iva_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_quiet',NULL,true,NULL,'2016-01-01',14,'admin',68,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'codice_fiscale_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_quiet','9999999999999999',true,NULL,'2016-01-01',14,'admin',69,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'delegati','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_delegato',NULL,true,'CO','2016-01-01',14,'admin',70,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'anagrafica_delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_anag_del',NULL,true,NULL,'2016-01-01',14,'admin',71,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'codice_fiscale_delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_codfisc_del',NULL,true,NULL,'2016-01-01',14,'admin',72,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (97,'cap_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_cap_del',NULL,true,NULL,'2016-01-01',14,'admin',73,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (98,'localita_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_localita_del',NULL,true,NULL,'2016-01-01',14,'admin',74,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (99,'provincia_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_prov_del',NULL,true,NULL,'2016-01-01',14,'admin',75,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (100,'avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_avviso',NULL,true,NULL,'2016-01-01',14,'admin',76,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (101,'invio_avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_invio_avviso',NULL,true,NULL,'2016-01-01',14,'admin',77,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (102,'codice_fiscale_avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_avviso',NULL,true,NULL,'2016-01-01',14,'admin',78,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (103,'piazzatura',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_piazzatura',NULL,true,'2|CB|CCP|2|I|VB','2016-01-01',14,'admin',79,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (104,'abi_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_abi_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',80,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (105,'cab_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cab_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',81,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (106,'numero_conto_corrente_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',82,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (107,'caratteri_controllo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_ctrl_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',83,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (108,'codice_cin',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cin_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',84,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (109,'codice_paese',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cod_paese_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',85,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (110,'denominazione_banca_destinataria',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_denom_banca_benef',NULL,true,'CB','2016-01-01',14,'admin',86,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (111,'conto_corrente_postale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_postale_benef',NULL,true,'CCP','2016-01-01',14,'admin',87,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (112,'conto_corrente_estero',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef_estero',NULL,true,'CB','2016-01-01',14,'admin',88,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (113,'codice_swift',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_swift_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',89,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (114,'coordinate_iban',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_iban_benef',NULL,true,'CB|IT','2016-01-01',14,'admin',90,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (115,'codice_ente_beneficiario','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_cod_ente_benef',NULL,true,NULL,'2016-01-01',14,'admin',91,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (116,'flag_pagamento_condizionato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_fl_pagam_cond_benef',NULL,true,NULL,'2016-01-01',14,'admin',92,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (117,'sepa_credit_transfer',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,'CB|SEPA','2016-01-01',14,'admin',194,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (118,'iban',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',NULL,true,NULL,'2016-01-01',14,'admin',195,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (119,'bic',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',NULL,true,NULL,'2016-01-01',14,'admin',196,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (120,'identificativo_end_to_end',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_id_end_tr',NULL,true,NULL,'2016-01-01',14,'admin',197,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (121,'codice_pagamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_code',NULL,true,NULL,'2016-01-01',14,'admin',107,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (122,'causale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_causale',NULL,true,NULL,'2016-01-01',14,'admin',109,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (123,'sospeso',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (124,'flag_copertura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa','mif_ord_flag_copertura',NULL,true,NULL,'2016-01-01',14,'admin',122,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (125,'numero_provvisorio','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2016-01-01',14,'admin',123,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (126,'importo_provvisorio','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2016-01-01',14,'admin',124,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (127,'data_scadenza_pagamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_scad',NULL,true,NULL,'2016-01-01',14,'admin',111,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (128,'flag_valuta_antergata','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_val_ant',NULL,true,NULL,'2016-01-01',14,'admin',112,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (129,'divisa_estera_conversione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_divisa_estera',NULL,true,NULL,'2016-01-01',14,'admin',113,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (130,'flag_assegno_circolare','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_ass_circ',NULL,true,NULL,'2016-01-01',14,'admin',114,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (131,'flag_vaglia_postale','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_vaglia',NULL,true,NULL,'2016-01-01',14,'admin',115,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (132,'ritenute',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa_ritenute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (133,'ritenuta',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (134,'tipo_ritenuta',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_tipo','R|P',true,'RIT_ORD|SPR|SUB_ORD|IRPEF|INPS','2016-01-01',14,'admin',93,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (135,'importo_ritenute',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_importo',NULL,true,NULL,'2016-01-01',14,'admin',94,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (136,'numero_reversale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_numero',NULL,true,NULL,'2016-01-01',14,'admin',95,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (137,'progressivo_reversale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rev','0000001',true,NULL,'2016-01-01',14,'admin',96,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (138,'progressivo_ritenuta',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rit',NULL,true,NULL,'2016-01-01',14,'admin',97,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (139,'informazioni_aggiuntive',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (140,'lingua',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_lingua','ITALIANO',true,NULL,'2016-01-01',14,'admin',116,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (141,'riferimento_documento_esterno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_rif_doc_esterno',NULL,true,NULL,'2016-01-01',14,'admin',117,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (142,'note','informazioni_tesoriere',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_info_tesoriere',NULL,true,NULL,'2016-01-01',14,'admin',118,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (143,'tipo_utenza','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_tipo_utenza',NULL,true,NULL,'2016-01-01',14,'admin',119,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (144,'codifica_utenza','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_codice_ute',NULL,true,NULL,'2016-01-01',14,'admin',120,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (145,'codice_generico','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_cod_generico',NULL,true,NULL,'2016-01-01',14,'admin',121,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (146,'sostituzione_mandato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_sost_mand',NULL,true,'SOS_ORD','2016-01-01',14,'admin',125,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (147,'numero_mandato_da_sostituire','numero_mandato_collegato',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_num_ord_colleg',NULL,true,NULL,'2016-01-01',14,'admin',126,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (148,'progressivo_mandato_collegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_colleg',NULL,true,NULL,'2016-01-01',14,'admin',127,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (149,'esercizio_mandato_da_sostituire','esercizio_mandato_collegato',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_anno_ord_colleg',NULL,true,NULL,'2016-01-01',14,'admin',128,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (150,'dati_a_disposizione_ente_mandato','dati_a_disposizione_ente',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (151,'elemento_progressivo','elemento_progressivo',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id order by mif_ord_id, mif_ord_dispe_ordine',false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (152,'elemento','elemento',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (153,'nome','nome',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo.elemento','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_nome',NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (154,'valore','valore',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo.elemento','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (155,'Capitolo origine',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',129,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (156,'Numero Capitolo','CMTO - Capitolo Peg - Altri - Numero Capitolo',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',141,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (157,'Numero articolo capitolo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',130,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (158,'Descrizione articolo capitolo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',131,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (159,'Somme non soggette','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',132,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (160,'Codice tributo','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',133,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (161,'Causale 770','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',134,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (162,'Data nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',135,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (163,'Luogo nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',136,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (164,'Prov nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',137,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (165,'Note',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',138,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (166,'Descrizione tipo pagamento',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',139,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (167,'Descrizione atto autorizzativo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',140,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (168,'Vincoli di destinazione','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',142,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (169,'Vincolato','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',143,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (170,'Voce Economica','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',144,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (171,'Numero distinta bilancio','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',145,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (172,'Data scadenza interna',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',146,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (173,'Numero reversale vincolata','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'SUB_ORD','2016-01-01',14,'admin',147,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (174,'Allegato Atto',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'ALG','2016-01-01',14,'admin',148,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (175,'Liquidazione','CMTO - Liquidazione',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',149,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (176,'Codice Missione',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',14,'admin',150,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (177,'Codice Programma',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA','2016-01-01',14,'admin',151,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (178,'Codice Economico',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'OP','2016-01-01',14,'admin',152,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (179,'Importo Codice Economico',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',153,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (180,'Codice Ue',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',14,'admin',154,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (181,'Codice Cofog',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'GRUPPO_COFOG','2016-01-01',14,'admin',155,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (182,'Importo Cofog',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',156,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (183,'Transazione Elementare','Indicazione della transazione elementare come stringa composita delle varie classificazioni',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA|PDC_V|OP|GRUPPO_COFOG|TRANSAZIONE_UE_SPESA|SIOPE_SPESA_I|cup|RICORRENTE_SPESA|PERIMETRO_SANITARIO_SPESA|POLITICHE_REGIONALI_UNITARIE','2016-01-01',14,'admin',184,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (184,'Anagrafica Beneficiario','Indicazione del beneficiario in caso di pagamento per girofondo Banca Italia - Anagrafica Beneficiario',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',157,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (185,'Codice Soggetto','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',158,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (186,'Carte Corredo','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',159,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (187,'Descrizione ABI','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',160,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (188,'Descrizione CAB','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',161,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (189,'Tipo Finanziamento','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',162,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (190,'Descrizione tipo finanziamento','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',163,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (191,'Importo mandato lettere','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',164,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (192,'Numero quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',165,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (193,'Descrizione quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',166,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (194,'Data scadenza quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',167,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (195,'Importo quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',168,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (196,'Documento collegato quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',169,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (197,'Impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',170,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (198,'Descrizione impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',171,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (199,'Dati provvedimento impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',14,'admin',172,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (200,'InfSerMan_NumeroImpegno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero_imp',NULL,true,NULL,'2016-01-01',14,'admin',173,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (201,'InfSerMan_SubImpegno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero_subimp',NULL,true,NULL,'2016-01-01',14,'admin',174,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (202,'InfSerMan_CodiceOperatore','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_code_operatore',NULL,true,NULL,'2016-01-01',14,'admin',175,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (203,'InfSerMan_NomeOperatore','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_nome_operatore',NULL,true,NULL,'2016-01-01',14,'admin',176,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (204,'InfSerMan_Fattura_Descr','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa_documenti','mif_ord_documento',NULL,true,NULL,'2016-01-01',14,'admin',177,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (205,'InfSerMan_DescrizioneEstesaCapitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descri_estesa_cap',NULL,true,NULL,'2016-01-01',14,'admin',178,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (206,'InfSerMan_DescrCapitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descri_cap',NULL,true,NULL,'2016-01-01',14,'admin',179,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (207,'InfSerMan_ProgSpesa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_prog_cap',NULL,true,NULL,'2016-01-01',14,'admin',180,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (208,'InfSerMan_TipoSpesa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_tipo_cap',NULL,true,NULL,'2016-01-01',14,'admin',181,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (209,'codice_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_siope_codice_cge',NULL,true,'SIOPE_SPESA_I|XXXX','2016-01-01',14,'admin',182,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (210,'descr_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_siope_descri_cge',NULL,true,NULL,'2016-01-01',14,'admin',183,NULL,false,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (211,'dati_a_disposizione_ente_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2016-01-01',14,'admin',186,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (212,'altri_codici_identificativi',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente_benef where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (213,'codice_missione',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_missione',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',14,'admin',187,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (214,'codice_programma',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_programma',NULL,true,'PROGRAMMA','2016-01-01',14,'admin',188,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (215,'codice_economico',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico',NULL,true,'OP','2016-01-01',14,'admin',189,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (216,'importo_codice_economico',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico_imp',NULL,true,NULL,'2016-01-01',14,'admin',190,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (217,'codice_ue',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_ue',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',14,'admin',191,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (218,'cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',NULL,NULL,NULL,false,NULL,'2016-01-01',14,'admin',0,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (219,'codice_cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_codice',NULL,true,'GRUPPO_COFOG','2016-01-01',14,'admin',192,NULL,true,54);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (220,'importo_cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_imp',NULL,true,NULL,'2016-01-01',14,'admin',193,NULL,true,54);
