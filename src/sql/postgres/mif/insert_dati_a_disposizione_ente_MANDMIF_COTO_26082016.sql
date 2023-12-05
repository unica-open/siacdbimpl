/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 26.08.2016 Sofia - da aggiungere a tracciato copiato da AIPO fra i dati a dispsizione ente simil ABI36
INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (258,'codben',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codben',
          NULL,true,NULL,
          '2016-01-01',1,'admin',199,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (259,'numero_articolo',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_num_articolo',
          NULL,true,NULL,
          '2016-01-01',1,'admin',200,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (260,'descrizione_pagamento',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_pagamento',
          NULL,true,NULL,
          '2016-01-01',1,'admin',201,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (261,'st_intervento',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cod_bilancio',
          NULL,true,NULL,
          '2016-01-01',1,'admin',202,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (262,'st_carte_corredo',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_carte_corr',
          NULL,true,NULL,
          '2016-01-01',1,'admin',203,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (263,'st_descri_forma_pag',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_forma_pagam',
          NULL,true,NULL,
          '2016-01-01',1,'admin',204,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (264,'st_descri_abi',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_abi',
          NULL,true,NULL,
          '2016-01-01',1,'admin',205,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (265,'st_descri_cab',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_cab',
          NULL,true,NULL,
          '2016-01-01',1,'admin',206,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (265,'st_descri_cdc',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_cdc',
          NULL,true,NULL,
          '2016-01-01',1,'admin',206,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (266,'st_descri_intervento',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_cod_bilancio',
          NULL,true,NULL,
          '2016-01-01',1,'admin',207,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (267,'st_descri_tipofin',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_desc_tipofin',
          NULL,true,NULL,
          '2016-01-01',1,'admin',208,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (268,'st_tipofin',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_tipofin',
          NULL,true,NULL,
          '2016-01-01',1,'admin',209,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (269,'st_note_finanz_mutuo',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_finanz_mutuo',
          NULL,true,NULL,
          '2016-01-01',1,'admin',210,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (270,'st_ragsoc',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc',
          NULL,true,NULL,
          '2016-01-01',1,'admin',211,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (271,'st_via',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc_via',
          NULL,true,NULL,
          '2016-01-01',1,'admin',212,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (272,'st_cap',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc_cap',
          NULL,true,NULL,
          '2016-01-01',1,'admin',213,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (273,'st_comune',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc_comune',
          NULL,true,NULL,
          '2016-01-01',1,'admin',214,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (274,'st_prov',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc_prov',
          NULL,true,NULL,
          '2016-01-01',1,'admin',215,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (275,'st_partiva_codfisc',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_ragsoc_codfisc',
          NULL,true,NULL,
          '2016-01-01',1,'admin',216,NULL,true,124);

INSERT INTO mif_d_flusso_elaborato
(
  flusso_elab_mif_ordine,
  flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella, flusso_elab_mif_campo,
  flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
  validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
  flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id)
  values (276,'st_imp_ord_incasso',NULL,true,
          'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.dati_a_disposizione_ente',
          'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_imp_ord_inc',
          NULL,true,NULL,
          '2016-01-01',1,'admin',217,NULL,true,124);

--- aggiungere tag per le quote          