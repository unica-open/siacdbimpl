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
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (1,'flusso_ordinativi',NULL,true,NULL,NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (2,'testata',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT 1',false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (3,'codice_ABI_BT',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_abi_bt','05584',true,NULL,'2016-01-01',29,'admin',15,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (4,'identificativo_flusso',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_id_flusso_oil',NULL,true,NULL,'2016-01-01',29,'admin',20,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (5,'data_ora_creazione_flusso',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_data_creazione_flusso',NULL,true,NULL,'2016-01-01',29,'admin',21,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (6,'codice_ente',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_ente','95000120063',true,NULL,'2016-01-01',29,'admin',16,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (7,'descrizione_ente',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_desc_ente','Ente di Gestione delle Aree Protette del Po Vercellese-Alessandrino',true,NULL,'2016-01-01',29,'admin',17,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (8,'codice_ente_BT',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_codice_ente_bt','617708',true,NULL,'2016-01-01',29,'admin',18,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (9,'esercizio',NULL,true,'flusso_ordinativi.testata','mif_t_ordinativo_spesa','mif_ord_anno_esercizio',NULL,true,NULL,'2016-01-01',29,'admin',19,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (11,'mandati',NULL,true,'flusso_ordinativi',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi',false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (12,'mandato',NULL,true,'flusso_ordinativi.mandati',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (13,'tipo_operazione','codice_funzione',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_funzione',NULL,true,'4|I|INSERIMENTO|A|ANNULLO|N|ANNULLO|S|SOSTITUZIONE','2016-01-01',29,'admin',1,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (14,'numero_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero',NULL,true,NULL,'2016-01-01',29,'admin',2,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (15,'data_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_data',NULL,true,NULL,'2016-01-01',29,'admin',3,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (16,'importo_mandato',NULL,true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_importo',NULL,true,NULL,'2016-01-01',29,'admin',4,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (17,'flg_finanza_locale','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_flag_fin_loc',NULL,true,NULL,'2016-01-01',29,'admin',5,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (18,'numero_documento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_documento',NULL,true,NULL,'2016-01-01',29,'admin',6,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (19,'tipo_contabilita_ente_pagante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_tipo_ente_pag',NULL,true,NULL,'2016-01-01',29,'admin',7,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (20,'destinazione_ente_pagante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_dest_ente_pag',NULL,true,NULL,'2016-01-01',29,'admin',8,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (21,'conto_evidenza','conto_tesoreria',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_bci_conto_tes',NULL,true,NULL,'2016-01-01',29,'admin',9,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (22,'estremi_provvedimento_autorizzativo','estremi_provvedimento_autorizzativo',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_estremi_attoamm',NULL,true,'SPR|ALG','2016-01-01',29,'admin',10,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (23,'codice_ufficio_responsabile','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_uff_resp',NULL,true,NULL,'2016-01-01',29,'admin',11,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (24,'data_provvedimento_autorizzativo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_data_attoamm',NULL,true,NULL,'2016-01-01',29,'admin',12,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (25,'responsabile_provvedimento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_resp_attoamm',NULL,true,NULL,'2016-01-01',29,'admin',13,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (26,'ufficio_responsabile','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_uff_resp_attomm',NULL,true,NULL,'2016-01-01',29,'admin',14,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (27,'anno_flusso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_anno_flusso',NULL,true,NULL,'2016-01-01',29,'admin',22,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (28,'codice_struttura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_struttura',NULL,true,NULL,'2016-01-01',29,'admin',23,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (29,'progressivo_mandato_struttura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_struttura',NULL,true,NULL,'2016-01-01',29,'admin',24,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (30,'ente_localita','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_ente_localita',NULL,true,NULL,'2016-01-01',29,'admin',25,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (31,'ente_indirizzo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_ente_indirizzo',NULL,true,NULL,'2016-01-01',29,'admin',26,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (32,'codice_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_cge',NULL,true,NULL,'2016-01-01',29,'admin',27,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (33,'descr_cge','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descr_cge',NULL,true,NULL,'2016-01-01',29,'admin',28,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (34,'Tipo_Contabilita','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_tipo_contabilita',NULL,true,NULL,'2016-01-01',29,'admin',29,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (35,'codice_raggruppamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_codice_raggrup',NULL,true,NULL,'2016-01-01',29,'admin',30,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (36,'bilancio',NULL,true,'flusso_ordinativi.mandati.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (37,'codifica_bilancio','per coto  mif_ord_capitolo per esporre il numero del capitolo per gli altri mif_ord_codifica_bilancio per esporre il codice di bilancio

',true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_codifica_bilancio',NULL,true,NULL,'2016-01-01',29,'admin',42,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (38,'numero_articolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_articolo',NULL,true,NULL,'2016-01-01',29,'admin',43,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (39,'voce_economica','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_voce_eco',NULL,true,NULL,'2016-01-01',29,'admin',44,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (40,'descrizione_codifica','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_desc_codifica',NULL,true,NULL,'2016-01-01',29,'admin',45,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (41,'gestione',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_gestione','COMPETENZA|RESIDUO',true,NULL,'2016-01-01',29,'admin',46,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (42,'anno_residuo',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_anno_res',NULL,true,'X','2016-01-01',29,'admin',47,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (43,'importo_bilancio',NULL,true,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_importo_bil',NULL,true,NULL,'2016-01-01',29,'admin',48,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (44,'stanziamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_stanz',NULL,true,NULL,'2016-01-01',29,'admin',49,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (45,'mandati_stanziamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_stanz',NULL,true,NULL,'2016-01-01',29,'admin',50,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (46,'disponibilita_capitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_disponibilita',NULL,true,NULL,'2016-01-01',29,'admin',51,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (47,'previsione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_prev',NULL,true,'','2016-01-01',29,'admin',52,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (48,'mandati_previsione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_mandati_prev',NULL,true,NULL,'2016-01-01',29,'admin',53,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (49,'disponibilita_cassa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.bilancio','mif_t_ordinativo_spesa','mif_ord_disp_cassa',NULL,true,NULL,'2016-01-01',29,'admin',54,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (50,'informazioni_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (51,'progressivo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_benef','1',true,NULL,'2016-01-01',29,'admin',31,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (52,'importo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_importo',NULL,true,NULL,'2016-01-01',29,'admin',108,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (53,'tipo_pagamento',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_tipo',NULL,true,'IT|CB|CT|SEPA','2016-01-01',29,'admin',106,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (54,'frazionabile','',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_fraz','NO',true,'CLASSIFICATORE_21|01','2016-01-01',29,'admin',41,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (55,'gestione_provvisoria','',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_gest_prov','SI',true,'E','2016-01-01',29,'admin',40,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (56,'Impignorabili','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_impignor',NULL,true,NULL,'2016-01-01',29,'admin',32,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (57,'data_esecuzione_pagamento',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_esec',NULL,true,NULL,'2016-01-01',29,'admin',110,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (58,'destinazione','Destinazione',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_progr_dest','LIBERA',true,NULL,'2016-01-01',29,'admin',33,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (59,'numero_conto_banca_italia_ente_ricevente',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_conto',NULL,true,'CBI','2016-01-01',29,'admin',34,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (60,'tipo_contabilita_ente_ricevente',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_bci_tipo_contabil',NULL,true,NULL,'2016-01-01',29,'admin',35,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (61,'classificazione',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (62,'codice_cgu','codice_cge',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_codice_cge',NULL,true,'','2016-01-01',29,'admin',36,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (63,'importo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.classificazione','mif_t_ordinativo_spesa','mif_ord_class_importo',NULL,true,NULL,'2016-01-01',29,'admin',37,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (64,'Codice_cup','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_cup',NULL,true,NULL,'2016-01-01',29,'admin',38,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (65,'Codice_cpv','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_class_codice_cpv',NULL,true,NULL,'2016-01-01',29,'admin',39,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (68,'bollo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (69,'esenzione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_esenzione',NULL,true,NULL,'2016-01-01',29,'admin',98,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (70,'assoggettamento_bollo','carico_bollo',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico',NULL,true,'3|99|ESENTE BOLLO|AI|ESENTE BOLLO|SB|ASSOGGETTATO BOLLO A CARICO BENEFICIARIO','2016-01-01',29,'admin',99,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (71,'causale_esenzione_bollo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ordin_bollo_caus_esenzione',NULL,true,NULL,'2016-01-01',29,'admin',100,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (72,'Importo_bollo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo',NULL,true,NULL,'2016-01-01',29,'admin',101,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (73,'carico_spese','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_carico_spe',NULL,true,NULL,'2016-01-01',29,'admin',102,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (74,'importo_spese','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.bollo','mif_t_ordinativo_spesa','mif_ord_bollo_importo_spe',NULL,true,NULL,'2016-01-01',29,'admin',103,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (75,'spese','commissioni',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (76,'soggetto_destinatario_delle_spese','carico_commissioni',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_carico',NULL,true,'3|CE|A CARICO ENTE|BN|A CARICO BENEFICIARIO|ES|ESENTE','2016-01-01',29,'admin',104,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (77,'natura_pagamento',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_natura',NULL,true,'1|ES|ESENTE','2016-01-01',29,'admin',198,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (78,'causale_esenzione_spese','importo_commissioni',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.spese','mif_t_ordinativo_spesa','mif_ord_commissioni_importo',NULL,true,'1|ES|ESENTE','2016-01-01',29,'admin',105,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (79,'beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (80,'anagrafica_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_benef',NULL,true,'CBI','2016-01-01',29,'admin',55,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (81,'indirizzo_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_benef',NULL,true,NULL,'2016-01-01',29,'admin',56,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (82,'cap_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_benef',NULL,true,NULL,'2016-01-01',29,'admin',57,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (83,'localita_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_benef',NULL,true,NULL,'2016-01-01',29,'admin',58,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (84,'provincia_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_benef',NULL,true,NULL,'2016-01-01',29,'admin',59,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (85,'stato_beneficiario','vedasi piazzatura.codice_paese',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',NULL,true,NULL,'2016-01-01',29,'admin',185,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (86,'partita_iva_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_benef',NULL,true,NULL,'2016-01-01',29,'admin',60,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (87,'codice_fiscale_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_benef','95000120063',true,NULL,'2016-01-01',29,'admin',61,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (88,'beneficiario_quietanzante','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_benef_quiet',NULL,true,'CSI','2016-01-01',29,'admin',62,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (89,'anagrafica_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_anag_quiet',NULL,true,NULL,'2016-01-01',29,'admin',63,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (90,'indirizzo_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_indir_quiet',NULL,true,NULL,'2016-01-01',29,'admin',64,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (91,'cap_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_cap_quiet',NULL,true,NULL,'2016-01-01',29,'admin',65,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (92,'localita_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_localita_quiet',NULL,true,NULL,'2016-01-01',29,'admin',66,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (93,'provincia_ben_quiet',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_prov_quiet',NULL,true,NULL,'2016-01-01',29,'admin',67,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (94,'partita_iva_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_partiva_quiet',NULL,true,NULL,'2016-01-01',29,'admin',68,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (95,'codice_fiscale_ben_quiet','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_quiet','95000120063',true,NULL,'2016-01-01',29,'admin',69,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'delegati','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (97,'delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_delegato',NULL,true,'CO','2016-01-01',29,'admin',70,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (98,'anagrafica_delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_anag_del',NULL,true,NULL,'2016-01-01',29,'admin',71,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (99,'codice_fiscale_delegato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_codfisc_del',NULL,true,NULL,'2016-01-01',29,'admin',72,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (100,'cap_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_cap_del',NULL,true,NULL,'2016-01-01',29,'admin',73,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (101,'localita_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_localita_del',NULL,true,NULL,'2016-01-01',29,'admin',74,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (102,'provincia_delegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.delegato','mif_t_ordinativo_spesa','mif_ord_prov_del',NULL,true,NULL,'2016-01-01',29,'admin',75,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (103,'avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_avviso',NULL,true,NULL,'2016-01-01',29,'admin',76,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (104,'invio_avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_invio_avviso',NULL,true,NULL,'2016-01-01',29,'admin',77,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (105,'codice_fiscale_avviso','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_codfisc_avviso',NULL,true,NULL,'2016-01-01',29,'admin',78,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (106,'piazzatura',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_piazzatura',NULL,true,'2|CB|CCP|2|I|VB','2016-01-01',29,'admin',79,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (107,'abi_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_abi_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',80,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (108,'cab_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cab_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',81,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (109,'numero_conto_corrente_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',82,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (110,'caratteri_controllo',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_ctrl_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',83,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (111,'codice_cin',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cin_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',84,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (112,'codice_paese',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cod_paese_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',85,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (113,'denominazione_banca_destinataria',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_denom_banca_benef',NULL,true,'CB','2016-01-01',29,'admin',86,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (114,'conto_corrente_postale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_postale_benef',NULL,true,'CCP','2016-01-01',29,'admin',87,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (115,'conto_corrente_estero',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_cc_benef_estero',NULL,true,'CB','2016-01-01',29,'admin',88,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (116,'codice_swift',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_swift_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',89,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (117,'coordinate_iban',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.piazzatura','mif_t_ordinativo_spesa','mif_ord_iban_benef',NULL,true,'CB|IT','2016-01-01',29,'admin',90,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (118,'codice_ente_beneficiario','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_cod_ente_benef',NULL,true,NULL,'2016-01-01',29,'admin',91,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (119,'flag_pagamento_condizionato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_fl_pagam_cond_benef',NULL,true,NULL,'2016-01-01',29,'admin',92,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (120,'sepa_credit_transfer',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,'IT|CB|SEPA','2016-01-01',29,'admin',194,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (121,'iban',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',NULL,true,NULL,'2016-01-01',29,'admin',195,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (122,'bic',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',NULL,true,NULL,'2016-01-01',29,'admin',196,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (123,'identificativo_end_to_end',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sepa_credit_transfer','mif_t_ordinativo_spesa','mif_ord_sepa_id_end_tr',NULL,true,NULL,'2016-01-01',29,'admin',197,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (124,'codice_pagamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_code',NULL,true,NULL,'2016-01-01',29,'admin',107,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (125,'causale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_causale',NULL,true,NULL,'2016-01-01',29,'admin',109,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (126,'sospeso',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (127,'flag_copertura','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa','mif_ord_flag_copertura',NULL,true,NULL,'2016-01-01',29,'admin',122,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (128,'numero_provvisorio','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_numero',NULL,true,NULL,'2016-01-01',29,'admin',123,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (129,'importo_provvisorio','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.sospeso','mif_t_ordinativo_spesa_ricevute','mif_ord_ric_importo',NULL,true,NULL,'2016-01-01',29,'admin',124,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (130,'data_scadenza_pagamento','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_data_scad',NULL,true,NULL,'2016-01-01',29,'admin',111,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (131,'flag_valuta_antergata','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_val_ant',NULL,true,NULL,'2016-01-01',29,'admin',112,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (132,'divisa_estera_conversione','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_divisa_estera',NULL,true,NULL,'2016-01-01',29,'admin',113,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (133,'flag_assegno_circolare','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_ass_circ',NULL,true,NULL,'2016-01-01',29,'admin',114,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (134,'flag_vaglia_postale','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario','mif_t_ordinativo_spesa','mif_ord_pagam_flag_vaglia',NULL,true,NULL,'2016-01-01',29,'admin',115,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (135,'ritenute',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa_ritenute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (136,'ritenuta',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (137,'tipo_ritenuta',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_tipo','R|P',true,'RIT_ORD|SPR|SUB_ORD|IRPEF|INPS','2016-01-01',29,'admin',93,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (138,'importo_ritenute',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_importo',NULL,true,NULL,'2016-01-01',29,'admin',94,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (139,'numero_reversale',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_numero',NULL,true,NULL,'2016-01-01',29,'admin',95,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (140,'progressivo_versante','progressivo_reversale',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rev','1',true,NULL,'2016-01-01',29,'admin',96,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (141,'progressivo_ritenuta',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.ritenute','mif_t_ordinativo_spesa_ritenute','mif_ord_rit_progr_rit',NULL,true,NULL,'2016-01-01',29,'admin',97,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (142,'informazioni_aggiuntive',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (143,'lingua',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_lingua','ITALIANO',true,NULL,'2016-01-01',29,'admin',116,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (144,'riferimento_documento_esterno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_rif_doc_esterno',NULL,true,NULL,'2016-01-01',29,'admin',117,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (145,'note','informazioni_tesoriere',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_info_tesoriere',NULL,true,NULL,'2016-01-01',29,'admin',118,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (146,'tipo_utenza','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_tipo_utenza',NULL,true,NULL,'2016-01-01',29,'admin',119,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (147,'codifica_utenza','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_codice_ute',NULL,true,NULL,'2016-01-01',29,'admin',120,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (148,'codice_generico','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_cod_generico',NULL,true,NULL,'2016-01-01',29,'admin',121,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (149,'sostituzione_mandato',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive','mif_t_ordinativo_spesa','mif_ord_sost_mand',NULL,true,'SOS_ORD','2016-01-01',29,'admin',125,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (150,'numero_mandato_da_sostituire','numero_mandato_collegato',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_num_ord_colleg',NULL,true,NULL,'2016-01-01',29,'admin',126,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (151,'progressivo_mandato_collegato','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_progr_ord_colleg',NULL,true,NULL,'2016-01-01',29,'admin',127,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (152,'esercizio_mandato_da_sostituire','esercizio_mandato_collegato',true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.informazioni_aggiuntive.sostituzione_mandato','mif_t_ordinativo_spesa','mif_ord_anno_ord_colleg',NULL,true,NULL,'2016-01-01',29,'admin',128,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (153,'dati_a_disposizione_ente_mandato','dati_a_disposizione_ente',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (154,'elemento_progressivo','elemento_progressivo',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id order by mif_ord_id, mif_ord_dispe_ordine',false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (155,'elemento','elemento',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (156,'nome','nome',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo.elemento','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_nome',NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (157,'valore','valore',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo.elemento','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (158,'Capitolo origine',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',129,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (159,'Numero Capitolo','CMTO - Capitolo Peg - Altri - Numero Capitolo',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',141,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (160,'Numero articolo capitolo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',130,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (161,'Descrizione articolo capitolo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',131,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (162,'Somme non soggette','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',132,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (163,'Codice tributo','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',133,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (164,'Causale 770','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',134,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (165,'Data nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',135,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (166,'Luogo nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',136,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (167,'Prov nascita beneficiario','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',137,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (168,'Note',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',138,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (169,'Descrizione tipo pagamento',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',139,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (170,'Descrizione atto autorizzativo',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',140,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (171,'Vincoli di destinazione','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',142,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (172,'Vincolato','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',143,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (173,'Voce Economica','CMTO',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',144,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (174,'Numero distinta bilancio','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',145,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (175,'Data scadenza interna',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',146,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (176,'Numero reversale vincolata','REGP REGPENTI',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'SUB_ORD','2016-01-01',29,'admin',147,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (177,'Allegato Atto',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'ALG','2016-01-01',29,'admin',148,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (178,'Liquidazione','CMTO - Liquidazione',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',149,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (179,'Codice Missione',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',29,'admin',150,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (180,'Codice Programma',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA','2016-01-01',29,'admin',151,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (181,'Codice Economico',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'OP|PDC_V','2016-01-01',29,'admin',152,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (182,'Importo Codice Economico',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',153,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (183,'Codice Ue',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',29,'admin',154,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (184,'Codice Cofog',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'GRUPPO_COFOG','2016-01-01',29,'admin',155,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (185,'Importo Cofog',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',156,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (186,'Transazione Elementare','Indicazione della transazione elementare come stringa composita delle varie classificazioni',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,'PROGRAMMA|PDC_V|OP|GRUPPO_COFOG|TRANSAZIONE_UE_SPESA|SIOPE_SPESA_I|cup|RICORRENTE_SPESA|PERIMETRO_SANITARIO_SPESA|POLITICHE_REGIONALI_UNITARIE','2016-01-01',29,'admin',184,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (187,'Anagrafica Beneficiario','Indicazione del beneficiario in caso di pagamento per girofondo Banca Italia - Anagrafica Beneficiario',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',157,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (188,'Codice Soggetto','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',158,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (189,'Carte Corredo','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',159,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (190,'Descrizione ABI','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',160,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (191,'Descrizione CAB','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',161,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (192,'Tipo Finanziamento','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',162,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (193,'Descrizione tipo finanziamento','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',163,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (194,'Importo mandato lettere','COTO ',false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',164,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (195,'Numero quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',165,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (196,'Descrizione quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',166,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (197,'Data scadenza quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',167,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (198,'Importo quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',168,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (199,'Documento collegato quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',169,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (200,'Impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',170,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (201,'Descrizione impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',171,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (202,'Dati provvedimento impegno quota mandato',NULL,false,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato.elemento_progressivo','mif_t_ordinativo_spesa_disp_ente','mif_ord_dispe_valore',NULL,true,NULL,'2016-01-01',29,'admin',172,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (203,'InfSerMan_NumeroImpegno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero_imp',NULL,true,NULL,'2016-01-01',29,'admin',173,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (204,'InfSerMan_SubImpegno','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_numero_subimp',NULL,true,NULL,'2016-01-01',29,'admin',174,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (205,'InfSerMan_CodiceOperatore','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_code_operatore',NULL,true,NULL,'2016-01-01',29,'admin',175,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (206,'InfSerMan_NomeOperatore','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_nome_operatore',NULL,true,NULL,'2016-01-01',29,'admin',176,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (207,'InfSerMan_Fattura_Descr','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa_documenti','mif_ord_documento',NULL,true,NULL,'2016-01-01',29,'admin',177,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (208,'InfSerMan_DescrizioneEstesaCapitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descri_estesa_cap',NULL,true,NULL,'2016-01-01',29,'admin',178,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (209,'InfSerMan_DescrCapitolo','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_descri_cap',NULL,true,NULL,'2016-01-01',29,'admin',179,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (210,'InfSerMan_ProgSpesa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_prog_cap',NULL,true,NULL,'2016-01-01',29,'admin',180,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (211,'InfSerMan_TipoSpesa','necessario per flusso standard contabilia',false,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_tipo_cap',NULL,true,NULL,'2016-01-01',29,'admin',181,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (212,'codice_cge','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_siope_codice_cge',NULL,true,'SIOPE_SPESA_I|XXXX','2016-01-01',29,'admin',182,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (213,'descr_cge','necessario per flusso standard contabilia',true,'flusso_ordinativi.mandati.mandato','mif_t_ordinativo_spesa','mif_ord_siope_descri_cge',NULL,true,NULL,'2016-01-01',29,'admin',183,NULL,false,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (214,'dati_a_disposizione_ente_beneficiario',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario',NULL,NULL,NULL,true,NULL,'2016-01-01',29,'admin',186,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (215,'altri_codici_identificativi',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,'select * from mif_t_ordinativo_spesa_disp_ente_benef where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (216,'codice_missione',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_missione',NULL,true,'Spesa - MissioniProgrammi','2016-01-01',29,'admin',187,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (217,'codice_programma',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_programma',NULL,true,'PROGRAMMA','2016-01-01',29,'admin',188,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (218,'codice_economico',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico',NULL,true,'OP|PDC_V','2016-01-01',29,'admin',189,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (219,'importo_codice_economico',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico_imp',NULL,true,NULL,'2016-01-01',29,'admin',190,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (220,'codice_ue',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_ue',NULL,true,'TRANSAZIONE_UE_SPESA','2016-01-01',29,'admin',191,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (221,'cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',NULL,NULL,NULL,false,NULL,'2016-01-01',29,'admin',0,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (222,'codice_cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_codice',NULL,true,'GRUPPO_COFOG','2016-01-01',29,'admin',192,NULL,true,84);
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (223,'importo_cofog',NULL,true,'flusso_ordinativi.mandati.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog','mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_imp',NULL,true,NULL,'2016-01-01',29,'admin',193,NULL,true,84);
