/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿create table dba_table_in_copiaente_da_modello
(tablename varchar, copied boolean default false);

insert into
dba_table_in_copiaente_da_modello
select
a.tablename, true
 from pg_tables a
 where a.tablename in ('siac_t_ente_proprietario',
'siac_t_attr',
'siac_t_class_fam_tree',
'siac_t_azione',
'siac_t_class',
'siac_t_soggetto',
'siac_t_account',
'siac_t_gruppo',
'siac_t_bil',
'siac_t_report',
'siac_t_report_importi',
'siac_t_forma_giuridica',
'siac_t_nazione',
'siac_t_provincia',
'siac_t_comune',
'siac_t_cassa_econ',
'siac_t_cassa_econ_stanz',
'siac_t_repj_template',
'siac_t_pdce_fam_tree',
'siac_t_pdce_conto',
'siac_t_iva_aliquota',
'siac_t_iva_prorata',
'siac_t_iva_attivita',
'siac_t_iva_gruppo',
'siac_t_sepa',
'siac_t_abi',
'siac_t_cab',
'siac_t_causale_ep',
'siac_r_ente_proprietario_tipo',
'siac_r_causale_ep_tipo_evento_tipo',
'siac_r_doc_tipo_attr',
'siac_r_class_fam_tree',
'siac_r_class',
'siac_r_ruolo_op_azione',
'siac_r_attr_bil_elem_tipo',
'siac_r_attr_class_tipo',
'siac_r_bil_elem_tipo_class_tip',
'siac_r_bil_elem_tipo_class_tip_elem_code',
'siac_r_bil_elem_tipo_attr_id_elem_code',
'siac_r_attr_entita',
'siac_r_bil_tipo_stato_op',
'siac_r_movgest_tipo_class_tip',
'siac_r_ordinativo_tipo_class_tip',
'siac_r_soggetto_ruolo',
'siac_r_gruppo_account',
'siac_r_gruppo_ruolo_op',
'siac_r_account_ruolo_op',
'siac_t_periodo',
'siac_r_bil_fase_operativa',
'siac_r_gestione_ente',
'siac_r_report_importi',
'siac_r_comune_provincia',
'siac_r_comune_regione',
'siac_r_provincia_regione',
'siac_r_account_ruolo_op_cassa_econ',
'siac_r_account_cassa_econ',
'siac_r_cassa_econ_tipo_modpag_tipo',
'siac_r_accredito_tipo_cassa_econ',
'siac_r_pdce_fam_class_tipo',
'siac_r_pdce_fam_class_fam',
'siac_r_pdce_conto',
'siac_r_iva_gruppo_attivita',
'siac_r_iva_gruppo_chiusura',
'siac_r_iva_gruppo_prorata',
'siac_r_causale_ep_pdce_conto',
'siac_r_causale_ep_pdce_conto_oper',
'siac_r_evento_causale',
'siac_r_causale_ep_stato',
'siac_r_causale_ep_class');

insert into
dba_table_in_copiaente_da_modello
select a.tablename, true
 from pg_tables a
 where a.tablename like 'siac_d_%'
 and a.tablename not like 'siac_dw%'
 and a.tablename not in ('siac_d_ente_proprietario_tipo','siac_d_flusso_elaborato_mif');



insert into
dba_table_in_copiaente_da_modello
select a.tablename, false
 from pg_tables a
 where
 a.tablename like 'siac_%'
 and a.tablename not like 'siac_dw%'
 and a.tablename not in
 (select tablename from dba_table_in_copiaente_da_modello where copied = true);