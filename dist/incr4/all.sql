/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--siac_t_xbrl_mapping_fatti_inser fine
--
-- record per la mappatura dei report xbrl
--

--
-- report BILR125 + BILR125 tagmap
--

INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.21','CE_OneriFinanziariInteressiAltriOneri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.21' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','Importo_codiceAnno-1','${cb_xbrl_tagname}','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='Importo_codiceAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','Importo_codice','${cb_xbrl_tagname}','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='Importo_codice' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp1920','CE_ProventiFinanziariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp1920' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp21','CE_OneriFinanziariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp21' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp24','CE_ProventiStraordinariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp24' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp25','CE_OneriStraordinariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp25' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp2425','CE_ProventiOneriStraordinariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp2425' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','Totale_Raggr','CE_RisultatoPrimaImposte','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='Totale_Raggr' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImpAnno','${cb_xbrl_abtot_tagname}','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpAnno' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotRaggrC','CE_ProventiOneriFinanziariTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotRaggrC' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotRaggrD','CE_RettificheValoreAttivitaFinanziarieTotale','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotRaggrD' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImpA-B','CE_DifferenzaComponentiGestione','','','d_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpA-B' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A','CE_ComponentiPositiviGestione','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.1','CE_CompPosProventiTributi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.1' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.2','CE_CompPosProventiFondiPerequativi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.2' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.3','CE_CompPosProventiTrasfContributi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.3' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.3.a','CE_CompPosProventiTrasfContributiTrasferimentiCorrenti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.3.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.3.b','CE_CompPosProventiTrasfContributiQuotaAnnualeContrInvest','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.3.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.3.c','CE_CompPosProventiTrasfContributiInvest','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.3.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.4','CE_CompPosVenditePrestazioniProventi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.4' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.4.a','CE_CompPosVenditePrestazioniProventiGestioneBeni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.4.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.4.b','CE_CompPosVenditePrestazioniProventiVenditaBeni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.4.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.4.c','CE_CompPosVenditePrestazioniProventiPrestazioneServizi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.4.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.5','CE_CompPosVariazioneRimanenze','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.5' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.6','CE_CompPosVariazioniLavoriInCorso','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.6' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.7','CE_CompPosIncrementiImmobLavoriInterni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.7' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A.8','CE_CompPosAltriRicaviProventi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.8' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B','CE_ComponentiNegativiGestione','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.09','CE_CompNegAcquistoMaterieBeni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.09' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.10','CE_CompNegPrestazioniServizi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.10' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.11','CE_CompNegUtilizzoBeniTerzi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.11' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.12','CE_CompNegTrasfContributi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.12' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.12.a','CE_CompNegTrasfContributiTrasferimentiCorrenti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.12.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.12.b','CE_CompNegTrasfContributiInvestimentiPA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.12.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.12.c','CE_CompNegTrasfContributiAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.12.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.14','CE_CompNegAmmortSvalut','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.14' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.13','CE_CompNegPersonale','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.13' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.14.a','CE_CompNegAmmortSvalutImmobImmateriali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.14.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.14.b','CE_CompNegAmmortSvalutImmobMateriali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.14.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.14.c','CE_CompNegAmmortSvalutAltreImmob','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.14.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.14.d','CE_CompNegAmmortSvalutCrediti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.14.d' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.15','CE_CompNegVariazRimanenzeMaterieBeni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.15' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.16','CE_CompNegAccantonamentiRischi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.16' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.17','CE_CompNegAltriAccantonamenti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.17' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','B.18','CE_CompNegOneriDiversiGestione','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.18' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C','CE_ProventiOneriFinanziari','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A_ProventiFinanziari','CE_ProventiFinanziari','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A_ProventiFinanziari' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.19','CE_ProventiFinanziariPartecipazioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.19' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.19.a','CE_ProventiFinanziariPartecipSocietaControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.19.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.19.b','CE_ProventiFinanziariPartecipSocietaPartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.19.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.19.c','CE_ProventiFinanziariPartecipAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.19.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.20','CE_ProventiFinanziariAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.20' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','A_OneriFinanziari','CE_OneriFinanziari','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A_OneriFinanziari' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.21.a','CE_OneriFinanziariInteressiPassivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.21.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','C.21.b','CE_OneriFinanziariAltriOneri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.21.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','D','CE_RettificheValoreAttivitaFinanziarie','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','D.22','CE_RettificheValoreAttivitaFinanziarieRivalutazioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.22' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','D.23','CE_RettificheValoreAttivitaFinanziarieSvalutazioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.23' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E','CE_ProventiOneriStraordinari','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24.a','CE_ProventiStraordinariPermessiCostruire','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24.b','CE_ProventiStraordinariTrasfContoCapitale','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24.c','CE_ProventiStraordinariSopravvAttiveInsussPassivo','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24.d','CE_ProventiStraordinariPlusvalenzePatrimoniali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24.d' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24.e','CE_ProventiStraordinariAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24.e' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.25.a','CE_OneriStraordinariTrasfContoCapitale','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.25.a' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.25.b','CE_OneriStraordinariSopravvPassiveInsussAttivo','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.25.b' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.25.c','CE_OneriStraordinariMinusvalenzePatrimoniali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.25.c' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.25.d','CE_OneriStraordinariAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.25.d' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.26','CE_Imposte','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.26' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.27','CE_RisultatoEsercizio','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.27' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.24','CE_ProventiStraordinari','','bad_abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.24' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125.tmap','E.25','CE_OneriStraordinari','','bad_abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.25' and z.xbrl_mapfat_rep_codice = 'BILR125.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp1920Anno-1','CE_ProventiFinanziariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp1920Anno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp21Anno-1','CE_OneriFinanziariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp21Anno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp24Anno-1','CE_ProventiStraordinariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp24Anno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp25Anno-1','CE_OneriStraordinariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp25Anno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImp2425Anno-1','CE_ProventiOneriStraordinariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImp2425Anno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','Totale_RaggrAnno-1','CE_RisultatoPrimaImposte','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='Totale_RaggrAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImpAnno-1','${cb_xbrl_abtot_tagname}','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotRaggrCAnno-1','CE_ProventiOneriFinanziariTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotRaggrCAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotRaggrDAnno-1','CE_RettificheValoreAttivitaFinanziarieTotale','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotRaggrDAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR125');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR125','TotImpA-BAnnoPrec','CE_DifferenzaComponentiGestione','','','d_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpA-BAnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR125');

--
-- report BILR128 + BILR128 tagmap
--
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','ImportoCodice','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='ImportoCodice' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','ImportoCodiceAnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='ImportoCodiceAnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv1','SP_AttivoTotale','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv1' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv1AnnoPrec','SP_AttivoTotale','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv1AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv2','${cb_totliv2_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv2' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv2AnnoPrec','${cb_totliv2_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv2AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv3Finale','${cb_totliv3_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv3Finale' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv3FinaleAnnoPrec','${cb_totliv3_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv3FinaleAnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv4','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv4' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv4AnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv4AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv5','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv5' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotImpLiv5AnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpLiv5AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotParzImpLiv2','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotParzImpLiv2' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotParzImpLiv2AnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotParzImpLiv2AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotParzImpLiv3','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotParzImpLiv3' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128','TotParzImpLiv3AnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotParzImpLiv3AnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR128');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','A','SP_AttivoCircCreditiVsPartecipanti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B','SP_FondiRischiOneri','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I','SP_ImmobImm','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.1','SP_ImmobImmCostiImpiantoAmpliamento','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.2','SP_ImmobImmCostiRicercaSviluppo','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.3','SP_ImmobImmDirittiBrevetto','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.4','SP_ImmobImmConcessioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.4' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.5','SP_ImmobImmAvviamento','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.5' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.6','SP_ImmobImmInCorsoAcconti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.6' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.I.9','SP_ImmobImmAltre','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.I.9' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II','SP_ImmobMat','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II.1','SP_ImmobMatBeniDemaniali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II.1.1','SP_ImmobMatBeniDemanialiTerreni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II.1.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II.1.2','SP_ImmobMatBeniDemanialiFabbricati','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II.1.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II.1.3','SP_ImmobMatBeniDemanialiInfrastutture','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II.1.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.II.1.9','SP_ImmobMatBeniDemanialiAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.II.1.9' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III','BADTAG_B.III','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2','SP_ImmobMatAltre','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.1','SP_ImmobMatAltreTerreni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.1.a','SP_ImmobMatAltreTerreniLeasing','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.1.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.2','SP_ImmobMatAltreFabbricati','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.2.a','SP_ImmobMatAltreFabbricatiLeasing','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.2.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.3','SP_ImmobMatAltreImpiantiMacchinari','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.3.a','SP_ImmobMatAltreImpiantiMacchinariLeasing','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.3.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.4','SP_ImmobMatAltreAttrezzIndustrialiCommerciali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.4' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.5','SP_ImmobMatAltreMezziTrasporto','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.5' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.6','SP_ImmobMatAltreMacchineUfficioHardware','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.6' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.7','SP_ImmobMatAltreMobiliArredi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.7' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.8','SP_ImmobMatAltreInfrastrutture','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.8' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.9','SP_ImmobMatAltreDirittiRealiGodimento','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.9' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.2.99','SP_ImmobMatAltreAltriBeniMateriali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.2.99' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.III.3','SP_ImmobMatInCorsoAcconti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.III.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV','SP_ImmobFin','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.1','SP_ImmobFinPartecipazioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.1.a','SP_ImmobFinPartecipazioniImpreseControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.1.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.1.b','SP_ImmobFinPartecipazioniImpresePartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.1.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.1.c','SP_ImmobFinPartecipazioniAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.1.c' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.2','SP_ImmobFinCrediti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.2.a','SP_ImmobFinCreditiVsAltrePA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.2.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.2.b','SP_ImmobFinCreditiVsImpreseControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.2.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.2.c','SP_ImmobFinCreditiVsImpresePartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.2.c' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.2.d','SP_ImmobFinCreditiVsAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.2.d' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','B.IV.3','SP_ImmobFinAltriTitoli','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.IV.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C','SP_AttivoCirc','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.I','SP_AttivoCircRimanenze','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.I' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II','SP_AttivoCircCrediti','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.1','SP_AttivoCircCreditiNaturaTributaria','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.1.a','SP_AttivoCircCreditiNaturaTributariaFinanzSanita','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.1.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.1.b','SP_AttivoCircCreditiNaturaTributariaAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.1.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.1.c','SP_AttivoCircCreditiNaturaTributariaFondiPerequativi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.1.c' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.2','SP_AttivoCircCreditiTrasfContr','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.2.a','SP_AttivoCircCreditiTrasfContrVsPA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.2.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.2.b','SP_AttivoCircCreditiTrasfContrImpreseControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.2.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.2.c','SP_AttivoCircCreditiTrasfContrImpresePartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.2.c' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.2.d','SP_AttivoCircCreditiTrasfContrAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.2.d' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.3','SP_AttivoCircCreditiVsClientiUtenti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.4','SP_AttivoCircCreditiAltriCrediti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.4' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.4.a','SP_AttivoCircCreditiAltriCreditiVsErario','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.4.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.4.b','SP_AttivoCircCreditiAltriCreditiAttivitaCTerzi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.4.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.II.4.c','SP_AttivoCircCreditiAltriCreditiAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.II.4.c' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.III','SP_AttivoCircNonImmobilizzi','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.III' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.III.1','SP_AttivoCircNonImmobilizziPartecipazioni','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.III.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.III.2','SP_AttivoCircNonImmobilizziAltriTitoli','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.III.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV','SP_AttivoCircDisponibilitaLiquide','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.1','SP_AttivoCircDisponibilitaLiquideContoTesoreria','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.1.a','SP_AttivoCircDisponibilitaLiquideContoTesoreriaIstTes','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.1.a' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.1.b','SP_AttivoCircDisponibilitaLiquideContoTesoreriaBI','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.1.b' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.2','SP_AttivoCircDisponibilitaLiquideAltriDepositi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.3','SP_AttivoCircDisponibilitaLiquideDenaroValoriCassa','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.3' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','C.IV.4','SP_AttivoCircDisponibilitaLiquideAltriConti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C.IV.4' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','D','SP_RateiRiscontiAttivo','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','D.1','SP_RateiRiscontiRateiAttivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR128.tmap','D.2','SP_RateiRiscontiRiscontiAttivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.2' and z.xbrl_mapfat_rep_codice = 'BILR128.tmap');



--
-- report BILR129 + BILR129 tagmap
--

INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','ImportoCodice','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='ImportoCodice' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','ImportoCodiceAnnoPrec','${cb_xbrl_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='ImportoCodiceAnnoPrec' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','TotImpABCDE','SP_Passivo','','','i_anno/anno_bilancio*0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpABCDE' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','TotImpABCDEAnno-1','SP_Passivo','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpABCDEAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','TotImpAnno','${cb_xbrl_totimp_tagname}','','','i_anno/anno_bilancio*-0/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpAnno' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129','TotImpAnno-1','${cb_xbrl_totimp_tagname}','','','i_anno/anno_bilancio*-1/','eur',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','instant' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotImpAnno-1' and z.xbrl_mapfat_rep_codice = 'BILR129');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','0','SP_ContiOrdine','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='0' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','1','SP_ContiOrdineImpegniEserciziFuturi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='1' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','2','SP_ContiOrdineBeniTerziInUso','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='2' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','3','SP_ContiOrdineBeniDatiUsoTerzi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='3' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','4','SP_ContiOrdineGaranziePrestatePA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='4' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','5','SP_ContiOrdineGaranziePrestateImpreseControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='5' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','6','SP_ContiOrdineGaranziePrestateImpresePartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='6' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','7','SP_ContiOrdineGaranziePrestateAltreImprese','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='7' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A','SP_PatrimonioNetto','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.I','SP_PatrimonioNettoFondoDotazione','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.I' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.II','SP_PatrimonioNettoRiserve','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.II' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.II.a','SP_PatrimonioNettoRiserveEserciziPrec','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.II.a' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.II.b','SP_PatrimonioNettoRiserveCapitale','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.II.b' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.II.c','SP_PatrimonioNettoRiservePermessiCostruire','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.II.c' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','A.III','SP_PatrimonioNettoRisultatoEconomicoEsercizio','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='A.III' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','B','SP_FondiRischiOneri','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','B.1','SP_FondiRischiOneriTrattamentoQuiescenza','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.1' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','B.2','SP_FondiRischiOneriImposte','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.2' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','B.3','SP_FondiRischiOneriAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='B.3' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','C','SP_TrattamentoFineRapporto','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='C' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D','SP_Debiti','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.1','SP_DebitiFinanz','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.1.a','SP_DebitiFinanzPrestitiObbligazionari','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1.a' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.1.b','SP_DebitiFinanzVsAltrePA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1.b' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.1.c','SP_DebitiFinanzVsBancheTesorerie','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1.c' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.1.d','SP_DebitiFinanzVsAltriFinanziatori','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.1.d' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.2','SP_DebitiVsFornitori','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.2' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.3','SP_DebitiAcconti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.3' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4','SP_DebitiTrafContr','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4.a','SP_DebitiTrafContrEntiSSN','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4.a' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4.b','SP_DebitiTrafContrAltrePA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4.b' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4.c','SP_DebitiTrafContrImpreseControllate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4.c' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4.d','SP_DebitiTrafContrImpresePartecipate','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4.d' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.4.e','SP_DebitiTrafContrAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.4.e' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.5','SP_DebitiAltriDebiti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.5' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.5.a','SP_DebitiAltriDebitiTributari','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.5.a' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.5.b','SP_DebitiAltriDebitiVsIstitutiPrevidenza','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.5.b' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.5.c','SP_DebitiAltriDebitiAttivitaCTerzi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.5.c' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','D.5.d','SP_DebitiAltriDebitiAltri','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='D.5.d' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E','SP_RateiRiscontiPassivo','','abstract','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.I','SP_RateiRiscontiRateiPassivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.I' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II','SP_RateiRiscontiRiscontiPassivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II.1','SP_RateiRiscontiContrInvest','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II.1' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II.1.a','SP_RateiRiscontiContrInvestAltrePA','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II.1.a' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II.1.b','SP_RateiRiscontiContrInvestAltriSoggetti','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II.1.b' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II.2','SP_RateiRiscontiConnessioniPluriennali','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II.2' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice   ,xbrl_mapfat_variabile   ,xbrl_mapfat_fatto   ,xbrl_mapfat_tupla_nome   ,xbrl_mapfat_tupla_group_key ,xbrl_mapfat_periodo_code  ,xbrl_mapfat_unit_code   ,xbrl_mapfat_decimali   ,validita_inizio     ,ente_proprietario_id   ,login_operazione    ,xbrl_mapfat_periodo_tipo) select 'BILR129.tmap','E.II.3','Altri risconti passivi','','','unused','',0,'2016-01-01'::timestamp,a.ente_proprietario_id,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='E.II.3' and z.xbrl_mapfat_rep_codice = 'BILR129.tmap');
--siac_t_xbrl_mapping_fatti_inser fine


-----------------DA AGGIUNGERE (siac_t_xbrl_mapping_fatti_insert) NUOVO INIZIO 
update siac_t_xbrl_mapping_fatti set xbrl_mapfat_variabile = 'TotalePagamentiMiss' where xbrl_mapfat_rep_codice = 'BILR049' and xbrl_mapfat_variabile = 'TotTotalePagamentiMiss';
update siac_t_xbrl_mapping_fatti set xbrl_mapfat_variabile = 'TotResiduiPassEsePrecMiss' where xbrl_mapfat_rep_codice = 'BILR049' and xbrl_mapfat_variabile = 'TotResiduiPassEserPrecMiss';

-- patch per report BILR109 (richiede le modifiche coerenti sul report versione 3.3.0-00X) 
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno_programma+desc/programma_desc_macro+descr/macroag_code1','${cb_xbrl_tagname}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno_programma+desc/programma_desc_macro+descr/macroag_code1' and z.xbrl_mapfat_rep_codice = 'BILR109');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno_macro+descr/macroag_code1','${cb_xbrl_totmissione}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno_macro+descr/macroag_code1' and z.xbrl_mapfat_rep_codice = 'BILR109');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno_anno/bil_anno_macro+descr/macroag_code1','${cb_xbrl_totmacro}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno_anno/bil_anno_macro+descr/macroag_code1' and z.xbrl_mapfat_rep_codice = 'BILR109');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno_programma+desc/programma_desc','${cb_xbrl_macrow_tagname}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno_programma+desc/programma_desc' and z.xbrl_mapfat_rep_codice = 'BILR109');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno','${cb_xbrl_totmissrow_tagname}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno' and z.xbrl_mapfat_rep_codice = 'BILR109');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR109','spese_effettive_anno_anno/bil_anno','${cb_xbrl_totmacrow_tagname}','','','d_anno/anno_bilancio*0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='spese_effettive_anno_anno/bil_anno' and z.xbrl_mapfat_rep_codice = 'BILR109');

-- insert per patch report BILR1114
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR114','TotTitoloTipolAccert','ENT-CAT_E.<[=''${tipologia_code}''.replace(/(\d)(\d\d)(\d\d)(\d\d)/, ''$1.$2.$3.$4'') =]>.000_A','','','d_anno/anno_bilancio*-0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotTitoloTipolAccert' and z.xbrl_mapfat_rep_codice = 'BILR114');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR114','TotTitoloTipolAccertRicor','ENT-CAT_E.<[=''${tipologia_code}''.replace(/(\d)(\d\d)(\d\d)(\d\d)/, ''$1.$2.$3.$4'') =]>.000_ANR','','','d_anno/anno_bilancio*-0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotTitoloTipolAccertRicor' and z.xbrl_mapfat_rep_codice = 'BILR114');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR114','TotTitoloTipolRiscosComp','ENT-CAT_E.<[=''${tipologia_code}''.replace(/(\d)(\d\d)(\d\d)(\d\d)/, ''$1.$2.$3.$4'') =]>.000_RiscCC','','','d_anno/anno_bilancio*-0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotTitoloTipolRiscosComp' and z.xbrl_mapfat_rep_codice = 'BILR114');
INSERT INTO siac_t_xbrl_mapping_fatti  (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_nome, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) select 'BILR114','TotTitoloTipolRiscosResidui','ENT-CAT_E.<[=''${tipologia_code}''.replace(/(\d)(\d\d)(\d\d)(\d\d)/, ''$1.$2.$3.$4'') =]>.000_RiscCR','','','d_anno/anno_bilancio*-0/','eur','0','2016-01-01'::timestamp,  a.ente_proprietario_id ,'gt1307','duration' from siac_t_ente_proprietario a where not exists (select 1 from  siac_t_xbrl_mapping_fatti z where z.ente_proprietario_id = a.ente_proprietario_id and z.xbrl_mapfat_variabile='TotTitoloTipolRiscosResidui' and z.xbrl_mapfat_rep_codice = 'BILR114');


-----------------DA AGGIUNGERE (siac_t_xbrl_mapping_fatti_insert) NUOVO FINE

-- siac_t_xbrl_report_insert inizio
--128

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR128',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR128'  and 
        z.ente_proprietario_id=a.ente_proprietario_id)
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR128',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR128' and 
        z.ente_proprietario_id=a.ente_proprietario_id);       


--129

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR129',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR129' and 
        z.ente_proprietario_id=a.ente_proprietario_id)
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR129',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR129' and 
        z.ente_proprietario_id=a.ente_proprietario_id);  

--125      

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR125',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR125' and 
        z.ente_proprietario_id=a.ente_proprietario_id)
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR125',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR125' and 
        z.ente_proprietario_id=a.ente_proprietario_id);    
--siac_t_xbrl_report_insert fine

-- SIAC-5105 Maurizio - INIZIO

DROP FUNCTION IF EXISTS siac."BILR997_tipo_capitolo_dei_report_variaz"(integer, varchar, varchar);

CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_variaz" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;

--fase_bilancio varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

select fnc_siac_random_user()
into	user_table;

-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where-- ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and 
e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
--and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
--and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
--and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
--raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     --siac_d_class_tipo programma_tipo,
     --siac_t_class programma,
    -- siac_d_class_tipo macroaggr_tipo,
     --siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     --siac_r_bil_elem_class r_capitolo_programma,
     --siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	--programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    --programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
   -- programma.classif_id=r_capitolo_programma.classif_id					and
    --macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    --macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    --macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    --capitolo.elem_id=r_capitolo_programma.elem_id							and
    --capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	--and	programma_tipo.data_cancellazione 			is null
    --and	programma.data_cancellazione 				is null
    --and	macroaggr_tipo.data_cancellazione 			is null
    --and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    --and	r_capitolo_programma.data_cancellazione 	is null
   	--and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
--raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
        
        
end if;

    
-------------------------------------
/*
for tipo_capitolo in
        select t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod,
                sum (t1.variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum (t1.variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum (t1.variazione_aumento_cassa) variazione_aumento_cassa,
                sum (t1.variazione_diminuzione_cassa) variazione_diminuzione_cassa,
                sum (t1.variazione_aumento_residuo) variazione_aumento_residuo,
                sum (t1.variazione_diminuzione_residuo)   variazione_diminuzione_residuo                                                                                              
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0,
            	siac_rep_var_entrate_riga t1,
                siac_d_bil_elem_categoria cat_del_capitolo,
    			siac_r_bil_elem_categoria r_cat_capitolo
        	where r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	and r_cat_capitolo.elem_id=t1.elem_id
                and cat_del_capitolo.elem_cat_code=t0.codice_importo
                and t1.periodo_anno=t0.anno_competenza
                and t1.utente=user_table
            group by t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod
                */
-- INC000001599997 Inizio
/*for tipo_capitolo in
        select t0.*               
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0
            	ORDER BY t0.anno_competenza
loop*/
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'G') t0
            	ORDER BY t0.anno_competenza
loop
-- INC000001599997 Fine

importo = tipo_capitolo.importo;
elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod ='CAP-EG' THEN  
	--Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;

            importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE
                 -- raise notice 'elemCatCode=%', elemCatCode;
                
                  
                  /*IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                      elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc  THEN            
                          importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
                  ELSIF elemCatCode = tipoFCassaIni THEN
                      importo =importo+variazione_aumento_cassa+variazione_diminuzione_cassa;              	
                  END IF;    */ 
                  
                  IF elemCatCode = tipoFCassaIni THEN
                      importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            --raise notice 'elemCatCode=%', elemCatCode;
             /* IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                  elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc OR 
                  elemCatCode= tipoFpvcc OR elemCatCode =tipoFpvsc THEN            
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
              ELSIF elemCatCode = tipoFCassaIni THEN
                  importo = importo+variazione_aumento_cassa+variazione_diminuzione_cassa;
              END IF; */  
              importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5105 Maurizio - FINE

-- SIAC-5088 Claudio - INIZIO
ALTER TABLE siac_t_ordinativo
	ADD COLUMN caus_id INTEGER;

ALTER TABLE siac_t_ordinativo
	ADD CONSTRAINT siac_d_causale_siac_t_ordinativo
	FOREIGN KEY (caus_id) REFERENCES siac_d_causale (caus_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;
-- SIAC-5088 Claudio - FINE

-- SIAC 5024 Alessandro - INIZIO

DROP TABLE IF EXISTS siac.rep_bilr125_dati_stato_passivo; 

CREATE TABLE siac.rep_bilr125_dati_stato_passivo (
  anno VARCHAR(4),
  codice_codifica_albero_passivo VARCHAR(200),
  importo_dare NUMERIC,
  importo_avere NUMERIC,
  importo_passivo NUMERIC,
  utente VARCHAR
) 
WITH (oids = false);

DROP FUNCTION siac."BILR125_rendiconto_gestione"(p_ente_prop_id integer, p_anno varchar, p_classificatori varchar);

CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			VARCHAR;
v_imp_dare          NUMERIC :=0;
v_imp_avere         NUMERIC :=0;
v_imp_dare_prec     NUMERIC :=0;
v_imp_avere_prec    NUMERIC :=0;
v_importo 			NUMERIC :=0;
v_importo_prec 		NUMERIC :=0;
v_pdce_fam_code     VARCHAR;
v_classificatori    VARCHAR;
v_classificatori1   VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null)
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id 
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL    
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF pdce.movep_det_segno = 'Dare' THEN
       IF pdce.anno = p_anno THEN
          v_imp_dare := pdce.importo;
       ELSE
          v_imp_dare_prec := pdce.importo;
       END IF;   
    ELSIF pdce.movep_det_segno = 'Avere' THEN
       IF pdce.anno = p_anno THEN
          v_imp_avere := pdce.importo;
       ELSE
          v_imp_avere_prec := pdce.importo;
       END IF;                   
    END IF;               
    
    v_pdce_fam_code := pdce.pdce_fam_code;
                                                            
    END LOOP;

    IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
       v_importo := v_imp_avere - v_imp_dare;
       v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
    ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
       v_importo := v_imp_dare - v_imp_avere;
       v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
    END IF; 
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
	INSERIMENTO DEL CODICE:
		2.2.3.01.03.01.003	Fondo ammortamento mobili e arredi per laboratori
	CON I RELATIVI ATTRIBUTI e CLASSIFICATORI.
	*/
	
insert into siac_t_pdce_conto 
 (pdce_conto_code,  pdce_conto_desc,  
  pdce_conto_id_padre ,  pdce_conto_a_partita ,
  livello ,  ordine ,  pdce_fam_tree_id ,  pdce_ct_tipo_id ,
  cescat_id ,  validita_inizio ,  validita_fine ,  ente_proprietario_id ,
  data_creazione ,  data_modifica ,  data_cancellazione ,  login_operazione ,  
  login_creazione ,  login_modifica ,  login_cancellazione ,  ambito_id )
  SELECT 
  '2.2.3.01.03.01.003','Fondo ammortamento mobili e arredi per laboratori',
  pdce_conto_id_padre,pdce_conto_a_partita, livello,'2.2.3.01.03.01.003',pdce_fam_tree_id,
  pdce_ct_tipo_id, cescat_id, CURRENT_DATE,  NULL, ente_proprietario_id,
  now(), now(), NULL,'admin_20170714','admin_20170714', 'admin_20170714',NULL,ambito_id
  FROM siac_t_pdce_conto a
  where 
  a.pdce_conto_code='2.2.3.01.03.01.002' ---copio i dati di uno dei suoi fratelli.
  and a.data_cancellazione is null and a.validita_fine is null
  and not exists (select 1 
      from siac_t_pdce_conto z 
      where z.pdce_conto_code='2.2.3.01.03.01.003' 
      and z.pdce_conto_id_padre=a.pdce_conto_id_padre );  

insert into siac_r_pdce_conto_class
 (pdce_conto_id,classif_id,validita_inizio,validita_fine,ente_proprietario_id,
 data_creazione,data_modifica,data_cancellazione,login_operazione)
 select a.pdce_conto_id, b.classif_id,CURRENT_DATE,NULL,a.ente_proprietario_id,
 now(),now(),NULL,'admin_20170714'
 from siac_t_pdce_conto a, siac_t_class b, siac_d_class_tipo c
 where b.classif_tipo_id=c.classif_tipo_id
 	and a.ente_proprietario_id=b.ente_proprietario_id
    and b.classif_code='2.7'
    and c.classif_tipo_code='SPA_CODBIL'
    and a.pdce_conto_code='2.2.3.01.03.01.003'
    and a.data_cancellazione is null
 	and b.data_cancellazione is null
    and c.data_cancellazione is null
     and not exists (select 1 
      from siac_r_pdce_conto_class z 
      where z.pdce_conto_id=a.pdce_conto_id and z.classif_id=b.classif_id );
	
    INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'S',CURRENT_DATE,a.ente_proprietario_id,
 'admin_20170714' 
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_conto_attivo', 'pdce_conto_di_legge','pdce_conto_foglia')
 and b.pdce_conto_code='2.2.3.01.03.01.003'
 and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
 
     INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'N',CURRENT_DATE,a.ente_proprietario_id,
 'admin_20170714'  
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_ammortamento')
 and b.pdce_conto_code='2.2.3.01.03.01.003'
 and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
	
/*
 	INSERIMENTO DEL CODICE:
		2.2.3.01.07.01.005	Fondo ammortamento tablet e dispositvi di telefonia fissa e mobile
	CON I RELATIVI ATTRIBUTI e CLASSIFICATORI.
		
 */
 

insert into siac_t_pdce_conto
 (pdce_conto_code,  pdce_conto_desc,  
  pdce_conto_id_padre ,  pdce_conto_a_partita ,
  livello ,  ordine ,  pdce_fam_tree_id ,  pdce_ct_tipo_id ,
  cescat_id ,  validita_inizio ,  validita_fine ,  ente_proprietario_id ,
  data_creazione ,  data_modifica ,  data_cancellazione ,  login_operazione ,  
  login_creazione ,  login_modifica ,  login_cancellazione ,  ambito_id )
  SELECT 
  '2.2.3.01.07.01.005','Fondo ammortamento tablet e dispositvi di telefonia fissa e mobile',
  pdce_conto_id_padre,pdce_conto_a_partita, livello,'2.2.3.01.07.01.005',pdce_fam_tree_id,
  pdce_ct_tipo_id, cescat_id, CURRENT_DATE,  NULL, ente_proprietario_id,
  now(), now(), NULL,'admin_20170714','admin_20170714', 'admin_20170714',NULL,ambito_id
  FROM siac_t_pdce_conto a
  where 
  a.pdce_conto_code='2.2.3.01.07.01.004' ---copio i dati di uno dei suoi fratelli.
  and a.data_cancellazione is null and a.validita_fine is null
    and not exists (select 1 
      from siac_t_pdce_conto z 
      where z.pdce_conto_code='2.2.3.01.07.01.005' 
      and z.pdce_conto_id_padre=a.pdce_conto_id_padre );
  
  
insert into siac_r_pdce_conto_class
 (pdce_conto_id,classif_id,validita_inizio,validita_fine,ente_proprietario_id,
 data_creazione,data_modifica,data_cancellazione,login_operazione)
 select a.pdce_conto_id, b.classif_id,CURRENT_DATE, NULL,a.ente_proprietario_id,
 now(),now(),NULL,'admin_20170714'
 from siac_t_pdce_conto a, siac_t_class b, siac_d_class_tipo c
 where b.classif_tipo_id=c.classif_tipo_id
 	and a.ente_proprietario_id=b.ente_proprietario_id
    and b.classif_code='2.6'
    and c.classif_tipo_code='SPA_CODBIL'
    and a.pdce_conto_code='2.2.3.01.07.01.005'
    and a.data_cancellazione is null
 	and b.data_cancellazione is null
    and c.data_cancellazione is null
	and not exists (select 1 
      from siac_r_pdce_conto_class z 
      where z.pdce_conto_id=a.pdce_conto_id and z.classif_id=b.classif_id );
	
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'S', CURRENT_DATE, a.ente_proprietario_id,
 'admin_20170714' 
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_conto_attivo', 'pdce_conto_di_legge','pdce_conto_foglia')
 and b.pdce_conto_code='2.2.3.01.07.01.005'
  and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
 
 INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'N', CURRENT_DATE, a.ente_proprietario_id,
 'admin_20170714'  
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_ammortamento')
 and b.pdce_conto_code='2.2.3.01.07.01.005'
  and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
 


/*
 	INSERIMENTO DEL CODICE:
		 2.2.3.01.09.01.018	Fondi ammortamento fabbricati ad uso strumentale
	CON I RELATIVI ATTRIBUTI e CLASSIFICATORI.
	
	*/

insert into siac_t_pdce_conto
 (pdce_conto_code,  pdce_conto_desc,  
  pdce_conto_id_padre ,  pdce_conto_a_partita ,
  livello ,  ordine ,  pdce_fam_tree_id ,  pdce_ct_tipo_id ,
  cescat_id ,  validita_inizio ,  validita_fine ,  ente_proprietario_id ,
  data_creazione ,  data_modifica ,  data_cancellazione ,  login_operazione ,  
  login_creazione ,  login_modifica ,  login_cancellazione ,  ambito_id )
  SELECT 
  '2.2.3.01.09.01.018','Fondi ammortamento fabbricati ad uso strumentale',
  pdce_conto_id_padre,pdce_conto_a_partita, livello,'2.2.3.01.09.01.018',pdce_fam_tree_id,
  pdce_ct_tipo_id, cescat_id, CURRENT_DATE,  NULL, ente_proprietario_id,
  now(), now(), NULL,'admin_20170714','admin_20170714', 'admin_20170714',NULL,ambito_id
  FROM siac_t_pdce_conto a
  where --a.ente_proprietario_id=29 and 
  a.pdce_conto_code='2.2.3.01.09.01.017' ---copio i dati di uno dei suoi fratelli.
  and a.data_cancellazione is null and a.validita_fine is null
      and not exists (select 1 
      from siac_t_pdce_conto z 
      where z.pdce_conto_code='2.2.3.01.09.01.018' 
      and z.pdce_conto_id_padre=a.pdce_conto_id_padre );
  
insert into siac_r_pdce_conto_class
 (pdce_conto_id,classif_id,validita_inizio,validita_fine,ente_proprietario_id,
 data_creazione,data_modifica,data_cancellazione,login_operazione)
 select a.pdce_conto_id, b.classif_id, CURRENT_DATE, NULL, a.ente_proprietario_id,
 now(),now(),NULL,'admin_20170714'
 from siac_t_pdce_conto a, siac_t_class b, siac_d_class_tipo c
 where b.classif_tipo_id=c.classif_tipo_id
 	and a.ente_proprietario_id=b.ente_proprietario_id
    and b.classif_code='2.2'
    and c.classif_tipo_code='SPA_CODBIL'
    and a.pdce_conto_code='2.2.3.01.09.01.018'
    and a.data_cancellazione is null
 	and b.data_cancellazione is null
    and c.data_cancellazione is null
     and not exists (select 1 
      from siac_r_pdce_conto_class z 
      where z.pdce_conto_id=a.pdce_conto_id and z.classif_id=b.classif_id );

INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'S',CURRENT_DATE,a.ente_proprietario_id,
 'admin_20170714' 
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_conto_attivo', 'pdce_conto_di_legge','pdce_conto_foglia')
 and b.pdce_conto_code='2.2.3.01.09.01.018'
  and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
 
 INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) 
 select b.pdce_conto_id,a.attr_id, 'N',CURRENT_DATE,a.ente_proprietario_id,
 'admin_20170714'  
 From siac_t_attr a ,siac_t_pdce_conto b 
 where b.ente_proprietario_id=a.ente_proprietario_id 
 and a.attr_code in('pdce_ammortamento')
 and b.pdce_conto_code='2.2.3.01.09.01.018'
  and not exists (select 1 
	from siac_r_pdce_conto_attr z 
    where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
	  
	  
/* SCRIPT PRECEDENTE PER INSERIMENTO DEL NUOVO ATTRIBUTO E COLLEGAMENTO A TUTTI I PDCE */
INSERT INTO 
  siac.siac_t_attr
(
  attr_code,
  attr_desc,
  attr_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'pdce_conto_segno_negativo','pdce_conto_segno_negativo',a.attr_tipo_id,
to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'CR-930' from siac_d_attr_tipo a 
where a.attr_tipo_code='B'
and not exists (select 1 from siac_t_attr z where z.ente_proprietario_id=a.ente_proprietario_id
and z.attr_code='pdce_conto_segno_negativo')
;

INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.01.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.01.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.01.01.003'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.01.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.03.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.03.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.03.01.003'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.03.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.04.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.04.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.05.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.05.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.05.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.06.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.003'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.004'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.005'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.07.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.08.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.08.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.003'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.004'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.005'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.006'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.007'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.008'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.009'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.010'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.011'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.012'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.013'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.014'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.015'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.016'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.017'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.018'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.09.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.99.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.99.01.002'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.01.99.01.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.02.01.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.02.02.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.02.03.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.02.04.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.3.02.99.99.999'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );
INSERT INTO siac_r_pdce_conto_attr(pdce_conto_id,attr_id,"boolean",validita_inizio,ente_proprietario_id,login_operazione) select b.pdce_conto_id,a.attr_id, 'S',b.validita_inizio,a.ente_proprietario_id,'CR-930'  From siac_T_attr a ,siac_t_pdce_conto b where b.ente_proprietario_id=a.ente_proprietario_id and a.attr_code='pdce_conto_segno_negativo' and b.pdce_conto_code='2.2.4.01.01.01.001'  and not exists (select 1 from siac_r_pdce_conto_attr z where z.attr_id=a.attr_id and z.pdce_conto_id=b.pdce_conto_id );

-- SIAC 5024 Alessandro - FINE

-- SIAC 5107 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_tipo_ritenuta varchar,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_ritenuta_irpef varchar,
  codice_tributo_irpef varchar,
  importo_ritenuta_irpef numeric,
  importo_netto_irpef numeric,
  importo_imponibile_irpef numeric,
  codice_risc varchar,
  tipo_ritenuta_inps varchar,
  codice_tributo_inps varchar,
  importo_ritenuta_inps numeric,
  importo_netto_inps numeric,
  importo_imponibile_inps numeric,
  importo_ente_inps numeric,
  tipo_ritenuta_irap varchar,
  importo_ritenuta_irap numeric,
  importo_netto_irap numeric,
  importo_imponibile_irap numeric,
  codice_ritenuta_irap varchar,
  desc_ritenuta_irap varchar,
  importo_ente_irap numeric,
  display_error varchar,
  tipo_ritenuta_irpeg varchar,
  codice_tributo_irpeg varchar,
  importo_ritenuta_irpeg numeric,
  importo_netto_irpeg numeric,
  importo_imponibile_irpeg numeric,
  codice_ritenuta_irpeg varchar,
  desc_ritenuta_irpeg varchar,
  importo_ente_irpeg numeric,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
contaReversali INTEGER;
importoSubDoc NUMERIC;
imponibileInpsApp NUMERIC;
impostaInpsApp	NUMERIC;
enteInpsApp NUMERIC;
imponibileIrpefApp NUMERIC;
impostaIrpefApp	NUMERIC;
imponibileIrapApp NUMERIC;
impostaIrapApp	NUMERIC;
contaQuotaIrap integer;
importoParzIrapImpon NUMERIC;
importoParzIrapNetto NUMERIC;
importoParzIrapRiten NUMERIC;
importoParzIrapEnte NUMERIC;

contaQuotaIrpef integer;
importoParzIrpefImpon NUMERIC;
importoParzIrpefNetto NUMERIC;
importoParzIrpefRiten NUMERIC;
importoParzIrpefEnte NUMERIC;
importoTotDaDedurreFattura NUMERIC;

percQuota NUMERIC;
idFatturaOld INTEGER;
numeroQuoteFattura INTEGER;
numeroParametriData Integer;
docIdApp integer;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

codice_risc='';
importo_lordo_mandato=0;
importo_netto_irpef=0;
importo_imponibile_irpef=0;
importo_ritenuta_irpef=0;
importo_netto_inps=0;
importo_imponibile_inps=0;
importo_ritenuta_inps=0;
importo_netto_irap=0;
importo_imponibile_irap=0;
importo_ritenuta_irap=0;

tipo_ritenuta_inps='';
tipo_ritenuta_irpef='';
tipo_ritenuta_irap='';

codice_tributo_irpef='';
codice_tributo_inps='';

codice_ritenuta_irap='';
desc_ritenuta_irap='';
benef_codice='';
importo_ente_irap=0;
importo_ente_inps=0;
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';

tipo_ritenuta_irpeg='';
codice_tributo_irpeg='';
importo_ritenuta_irpeg=0;
importo_netto_irpeg=0;
importo_imponibile_irpeg=0;
codice_ritenuta_irpeg='';
desc_ritenuta_irpeg='';
importo_ente_irpeg=0;
numeroParametriData=0;


display_error='';
/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL AND p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;


if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;*/

if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

if numeroParametriData = 0 THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if numeroParametriData>=2 THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if (p_data_trasm_da IS NULL AND p_data_trasm_a IS NOT NULL) OR 
	(p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;

if (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL) OR 
	(p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA MANDATO DA/A".';
    return next;
    return;
end if;

if (p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NOT NULL) OR 
	(p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;

    	/* 11/10/2016: cerco i mandati di tutte le ritenute tranne l'IRAP che 
        	deve essere estratta in modo diverso */
/* 30/05/2017: L'IRPEF deve essere gestita in modo simile all'IRAP in quanto 
	e' necessario calcolare il dato della ritenuta proporzionandola con la
    percentuale calcolata delle relativie quote della fattura */
--if p_tipo_ritenuta <> 'IRAP' THEN
if p_tipo_ritenuta in ('INPS','IRPEG') THEN
  for elencoMandati in
  select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
          t_periodo.anno anno_eser, t_ordinativo.ord_anno,
           t_ordinativo.ord_desc, t_ordinativo.ord_id,
          t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
          t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
          t_soggetto.partita_iva,t_soggetto.codice_fiscale,
          t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
          t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
          SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
          t_movgest.movgest_anno anno_impegno
          FROM  	siac_t_ente_proprietario ep,
                  siac_t_bil t_bil,
                  siac_t_periodo t_periodo,
                  siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                  siac_t_bil_elem t_bil_elem,                  
                  siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                    	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                        	and r_ord_quietanza.data_cancellazione IS NULL), 
                  siac_t_ordinativo_ts t_ord_ts,
                  siac_r_liquidazione_ord r_liq_ord,
                  siac_r_liquidazione_movgest r_liq_movgest,
                  siac_t_movgest t_movgest,
                  siac_t_movgest_ts t_movgest_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det,
                  siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                  siac_r_ordinativo_stato r_ord_stato,  
                  siac_d_ordinativo_stato d_ord_stato ,
                   siac_d_ordinativo_tipo d_ord_tipo,
                   siac_r_ordinativo_soggetto r_ord_soggetto ,
                   siac_t_soggetto t_soggetto  		    	
          WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
              AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
              AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
             AND t_ordinativo.ord_id=r_ord_stato.ord_id
             AND t_bil.bil_id=t_ordinativo.bil_id
             AND t_periodo.periodo_id=t_bil.periodo_id
             AND t_ord_ts.ord_id=t_ordinativo.ord_id           
             AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
             AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
             AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
             AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
             AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
             AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
             AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
             AND r_liq_movgest.liq_id=r_liq_ord.liq_id
             AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
             AND t_movgest_ts.movgest_id=t_movgest.movgest_id            
              AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_mandato_da AND p_data_mandato_a))
                  OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
              AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_trasm_da AND p_data_trasm_a))
                  OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))    
                  --09/02/2017: aggiunto test sulla data quietanza
                  -- se specificata in input.
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))      
          --AND p_data_mandato_da =to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
              AND t_ordinativo.ente_proprietario_id = p_ente_prop_id
              AND t_periodo.anno=p_anno
                  /* Gli stati possibili sono:
                      I = INSERITO
                      T = TRASMESSO 
                      Q = QUIETANZIATO
                      F = FIRMATO
                      A = ANNULLATO 
                      Prendo tutti tranne gli annullati.
                     */
              AND d_ord_stato.ord_stato_code <> 'A'
              AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
              AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
                  /* devo testare la data di fine validita' perche'
                      quando un ordinativo e' annullato, lo trovo 2 volte,
                      uno con stato inserito e l'altro annullato */
              AND r_ord_stato.validita_fine IS NULL 
              AND ep.data_cancellazione IS NULL
              AND r_ord_stato.data_cancellazione IS NULL
              AND r_ordinativo_bil_elem.data_cancellazione IS NULL
              AND t_bil_elem.data_cancellazione IS NULL
              AND  t_bil.data_cancellazione IS NULL
              AND  t_periodo.data_cancellazione IS NULL
              AND  t_ordinativo.data_cancellazione IS NULL
              AND  t_ord_ts.data_cancellazione IS NULL
              AND  t_ord_ts_det.data_cancellazione IS NULL
              AND  d_ts_det_tipo.data_cancellazione IS NULL
              AND  r_ord_stato.data_cancellazione IS NULL
              AND  d_ord_stato.data_cancellazione IS NULL
              AND  d_ord_tipo.data_cancellazione IS NULL  
              AND r_ord_soggetto.data_cancellazione IS NULL
              AND t_soggetto.data_cancellazione IS NULL
              AND r_liq_ord.data_cancellazione IS NULL 
              AND r_liq_movgest.data_cancellazione IS NULL 
              AND t_movgest.data_cancellazione IS NULL
              AND t_movgest_ts.data_cancellazione IS NULL
              AND t_ord_ts.data_cancellazione IS NULL
              GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                t_periodo.anno , t_ordinativo.ord_anno,
                 t_ordinativo.ord_desc, t_ordinativo.ord_id,
                t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
              ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data            
  loop

  importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);


	/* cerco gli oneri: INPS, IRPEF ed IRAP */
    /* 11/03/2016: gli importi degli oneri sono salvati, ma l'importo vero e proprio
    	e' assegnato piu' avanti dopo aver estratto la reversale */
    /* 14/03/2016: gli importi degli oneri sono presi dalle reversali */
/*for elencoOneri IN
        SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
          d_onere.onere_desc,        
          sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
          sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
          sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
        from siac_t_ordinativo_ts t_ordinativo_ts,
            siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
            siac_t_doc t_doc, 
            siac_t_subdoc t_subdoc,
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere,
            siac_d_onere_tipo d_onere_tipo
        WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
            AND t_ordinativo_ts.ord_id=elencoMandati.ord_id
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            GROUP BY d_onere_tipo.onere_tipo_code,d_onere.onere_code, d_onere.onere_desc
    loop       
          IF upper(elencoOneri.onere_tipo_code) = 'IRPEF' THEN
              tipo_ritenuta_irpef=upper(elencoOneri.onere_tipo_code);                                            
              codice_tributo=elencoOneri.onere_code;
              --importo_imponibile_irpef = elencoOneri.IMPORTO_IMPONIBILE;              
              --importo_ritenuta_irpef = elencoOneri.IMPOSTA;                             
              --importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;   
              imponibileIrpefApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaIrpefApp= elencoOneri.IMPOSTA;                                     
          ELSIF  upper(elencoOneri.onere_tipo_code) = 'INPS' THEN
              tipo_ritenuta_inps=upper(elencoOneri.onere_tipo_code);
              --importo_imponibile_inps = elencoOneri.IMPORTO_IMPONIBILE;
              --importo_ritenuta_inps = elencoOneri.IMPOSTA;                
              --importo_ente_inps=elencoOneri.IMPORTO_CARICO_ENTE;
              --importo_netto_inps=importo_lordo_mandato-importo_ritenuta_inps; 
              imponibileInpsApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaInpsApp= elencoOneri.IMPOSTA;         
              enteInpsApp=elencoOneri.IMPORTO_CARICO_ENTE;
          ELSIF  upper(elencoOneri.onere_tipo_code) = '3' THEN
              tipo_ritenuta_irap=upper(elencoOneri.onere_tipo_code);
              desc_ritenuta_irap=elencoOneri.onere_desc;
              codice_ritenuta_irap=elencoOneri.onere_code;
              --importo_imponibile_irap = elencoOneri.IMPORTO_IMPONIBILE;
              --importo_ritenuta_irap = elencoOneri.IMPOSTA;                
			  --importo_ente_irap=elencoOneri.IMPORTO_CARICO_ENTE;
              --importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap; 
              imponibileIrapApp=elencoOneri.IMPORTO_IMPONIBILE;   
			  impostaIrapApp= elencoOneri.IMPOSTA;                                  
          END IF;
    end loop;      */


	/* sono inviati al report solo i mandati che hanno una ritenuta IRPEF o INPS */
--if tipo_ritenuta_irpef <> '' OR  tipo_ritenuta_inps <> '' OR
--	tipo_ritenuta_irap <> '' THEN
    
/* 11/03/2016: cerco il subdoc per ricavarne l'importo */
         importoSubDoc=0;
      
 /*     SELECT t_subdoc.doc_id, COALESCE(t_subdoc.subdoc_importo,0)
          INTO docIdApp, importoSubDoc
      FROM siac_t_ordinativo_ts t_ordinativo_ts
          LEFT JOIN  siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts   
              ON  (r_subdoc_ordinativo_ts.ord_ts_id =t_ordinativo_ts.ord_ts_id 
                      AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL) 
          LEFT JOIN  siac_t_subdoc t_subdoc
              ON  (t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                  AND t_subdoc.data_cancellazione IS NULL)       
      WHERE  t_ordinativo_ts.ord_id=elencoMandati.ord_id;
      --GROUP BY t_subdoc.doc_id;
          IF NOT FOUND THEN
              importoSubDoc=0;
          END IF;  */
       
  --raise notice 'Num mandato =%, importo subdoc=%',elencoMandati.ord_numero,importoSubDoc;
  --raise notice 'ordinativo id =%', elencoMandati.ord_id;    	
          /* cerco le reversali siac_r_doc_onere_ordinativo_ts */
      /* 14/03/2016: attraverso la tabella siac_r_doc_onere_ordinativo_ts si puo'
          recuperare il dato dell'importo della reversale a livello di quota documento.
          Quindi non e' piu' necessario cercare gli oneri */
      /* 07/04/2016: aggiunto d_onere.onere_code che e' il codice_tributo */
      
      contaReversali=0;

      for elencoReversali in    
          select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord, 
                r_doc_onere.importo_carico_ente, r_doc_onere.importo_imponibile,
                d_onere_tipo.onere_tipo_code, d_onere.onere_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,'') somma_non_soggetta_tipo_code,
                COALESCE(d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,'') somma_non_soggetta_tipo_desc,
                caus_770.caus_code_770,
                caus_770.caus_desc_770,
                r_doc_onere.attivita_inizio,
                r_doc_onere.attivita_fine,
                d_onere_attivita.onere_att_code,
                d_onere_attivita.onere_att_desc
          from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,
                siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
                siac_r_doc_onere r_doc_onere
                LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_d_onere_attivita d_onere_attivita	
                		ON (d_onere_attivita.onere_att_id=
                        	  r_doc_onere.onere_att_id
                            AND d_onere_attivita.data_cancellazione IS NULL)
                /* 01/06/2017: aggiunta gestione delle causali 770 */                    
               LEFT JOIN (SELECT distinct r_onere_caus.onere_id,
               				r_doc_onere.doc_id,t_subdoc.subdoc_id,
               				COALESCE(d_causale.caus_code,'') caus_code_770,
                            COALESCE(d_causale.caus_desc,'') caus_desc_770
               			FROM siac_r_doc_onere r_doc_onere,
                        	siac_t_subdoc t_subdoc,
                        	siac_r_onere_causale r_onere_caus,
							siac_d_causale d_causale ,
							siac_d_modello d_modello                                                       
                    WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                    	AND r_doc_onere.onere_id=r_onere_caus.onere_id
                        AND d_causale.caus_id=r_doc_onere.caus_id
                    	AND d_causale.caus_id=r_onere_caus.caus_id   
                    	AND d_modello.model_id=d_causale.model_id                                                      
                        AND d_modello.model_code='01' --Causale 770
                        AND r_doc_onere.ente_proprietario_id =p_ente_prop_id                      AND r_doc_onere.onere_id=5
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) caus_770
                    ON (caus_770.onere_id=r_doc_onere.onere_id
                    	AND caus_770.doc_id=r_doc_onere.doc_id),
                        --AND caus_770.subdoc_id=irpef.subdoc_id),
                siac_d_onere d_onere,
                siac_d_onere_tipo  d_onere_tipo
                where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                    AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                    AND d_onere.onere_id=r_doc_onere.onere_id
                      AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
               -- AND d_relaz_tipo.relaz_tipo_code='RIT_ORD'
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
                AND r_doc_onere_ord_ts.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                     
          /*  select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord
            from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                  siac_d_ordinativo_tipo d_ordinativo_tipo,
                  siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
                  where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                      AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                      AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                      AND t_ord_ts.ord_id=t_ordinativo.ord_id
                      AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                      AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
               -- AND d_relaz_tipo.relaz_tipo_code='RIT_ORD'
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL*/
          loop
            contaReversali =contaReversali+1;
      --raise notice 'Onere=%, Imp=%, caricoEnte=%, Imponibile=%',elencoReversali.onere_tipo_code,elencoReversali.importo_ord, elencoReversali.importo_carico_ente, elencoReversali.importo_imponibile;
             /* anche split/reverse e' una reversale, quindi qualunque tipo
                tipo di relazione concateno i risultati ottenuti (possono essere piu' di 1) */
              if codice_risc = '' THEN
                  codice_risc = elencoReversali.ord_numero ::VARCHAR;
              else
                  codice_risc = codice_risc||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;
              /* 30/05/2017: l'IRAP collegata tramite reversale non e' presentata.
                      Viene fatta esplicita ricerca dell'onere collegato al
                      mandato.           
              if upper(elencoReversali.onere_tipo_code) = 'IRPEF' THEN
                  codice_tributo_irpef=COALESCE(elencoReversali.onere_code,'');
                  tipo_ritenuta_irpef=upper(elencoReversali.onere_tipo_code);
                  --importo_imponibile_irpef = elencoReversali.importo_ord*(importoSubDoc/importo_lordo_mandato);                       
                  importo_imponibile_irpef = elencoReversali.importo_imponibile;
                  importo_ritenuta_irpef = elencoReversali.importo_ord;    
                                      
                  importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
              elsif upper(elencoReversali.onere_tipo_code) = 'INPS' THEN */
              if upper(elencoReversali.onere_tipo_code) = 'INPS' THEN
                  codice_tributo_inps=COALESCE(elencoReversali.onere_code,'');
                  tipo_ritenuta_inps=upper(elencoReversali.onere_tipo_code);
                  --importo_imponibile_inps = elencoReversali.importo_ord*(importoSubDoc/importo_lordo_mandato);    
                  importo_imponibile_inps = elencoReversali.importo_imponibile;
                  importo_ente_inps=elencoReversali.importo_carico_ente;                   
                  importo_ritenuta_inps = elencoReversali.importo_ord;    
                  importo_netto_inps=importo_lordo_mandato-importo_ritenuta_inps;
                  attivita_inizio:=elencoReversali.attivita_inizio;
				  attivita_fine:=elencoReversali.attivita_fine;
                  attivita_code:=elencoReversali.onere_att_code;
                  attivita_desc:=elencoReversali.onere_att_desc;
                  
                  /* 07/04/2016: l'IRAP collegata tramite reversale non e' presentata.
                      Viene fatta esplicita ricerca dell'onere collegato al
                      mandato.           
              elsif upper(elencoReversali.onere_tipo_code) = 'IRAP' THEN
                  codice_tributo=COALESCE(elencoReversali.onere_code,'');
                  tipo_ritenuta_irap=upper(elencoReversali.onere_tipo_code);
                  importo_imponibile_irap = elencoReversali.importo_ord*(importoSubDoc/importo_lordo_mandato);    
                  importo_ritenuta_irap = elencoReversali.importo_ord*(importoSubDoc/importo_lordo_mandato); 
                  importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap; */   
              /* 07/04/2016: aggiunto l'IRPEG */
              elsif upper(elencoReversali.onere_tipo_code) = 'IRPEG' THEN

                  codice_tributo_irpeg=COALESCE(elencoReversali.onere_code,'');
                  tipo_ritenuta_irpeg=upper(elencoReversali.onere_tipo_code);    		
                  importo_imponibile_irpeg = elencoReversali.importo_imponibile;
                  importo_ritenuta_irpeg = elencoReversali.importo_ord;    
                                      
                  importo_netto_irpeg=importo_lordo_mandato-importo_ritenuta_irpeg;  
                  code_caus_770:=COALESCE(elencoReversali.caus_code_770,'');
				  desc_caus_770:=COALESCE(elencoReversali.caus_desc_770,'');
                  code_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_code,'');
                  desc_caus_esenz:=COALESCE(elencoReversali.somma_non_soggetta_tipo_desc,'');
        
              end if;
          end loop; 
          
          -- 30/05/2017: l'irpef non e' piu' gestita in questo ramo del codice
          --if tipo_ritenuta_irpef <> '' OR  tipo_ritenuta_inps <> '' OR
          if tipo_ritenuta_inps <> '' OR
               tipo_ritenuta_irpeg <> '' THEN
            stato_mandato= elencoMandati.ord_stato_code;

            nome_ente=elencoMandati.ente_denominazione;
            partita_iva_ente=elencoMandati.cod_fisc_ente;
            anno_ese_finanz=elencoMandati.anno_eser;
            desc_mandato=COALESCE(elencoMandati.ord_desc,'');

            anno_mandato=elencoMandati.ord_anno;
            numero_mandato=elencoMandati.ord_numero;
            data_mandato=elencoMandati.ord_emissione_data;
            benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
            benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
            benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
            benef_codice=COALESCE(elencoMandati.soggetto_code,'');
            
            return next;
          end if;
    

	--raise notice 'Id ordinativo: %',elencoMandati.ord_id;
    /* 11/03/2016: per avere l'importo dell'imposta IRPEF/INPS devo distinguere 2 casi:          
          - se c'e' una sola reversale, l'importo dell'imposta e' quello della
              reversale.
          - se ci sono piu' reversali devo calcolare l'imposta con la formula:
              ImportoImposta * (ImportoSubDocumento/ImportoMandato);
                        
          L'imponibile e' sempre calcolato con la formula:
              ImportoOnere * (ImportoSubDocumento/ImportoMandato); 
          Per IRAP invece gli importi sono sempre calcolati */
   
		/* 07/04/2016: cerco l'IRAP collegata al mandato */      
                   
   
    /*if tipo_ritenuta_irpef <> '' OR  tipo_ritenuta_inps <> '' OR
		tipo_ritenuta_irap <> '' OR tipo_ritenuta_irpeg <> '' THEN
          stato_mandato= elencoMandati.ord_stato_code;

          nome_ente=elencoMandati.ente_denominazione;
          partita_iva_ente=elencoMandati.cod_fisc_ente;
          anno_ese_finanz=elencoMandati.anno_eser;
          desc_mandato=COALESCE(elencoMandati.ord_desc,'');

          anno_mandato=elencoMandati.ord_anno;
          numero_mandato=elencoMandati.ord_numero;
          data_mandato=elencoMandati.ord_emissione_data;
          benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
          benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
          benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
          benef_codice=COALESCE(elencoMandati.soggetto_code,'');
          
          return next;
   end if;*/
--end if;

   
  nome_ente='';
  partita_iva_ente='';
  anno_ese_finanz=0;
  anno_mandato=0;
  numero_mandato=0;
  data_mandato=NULL;
  desc_mandato='';
  benef_cod_fiscale='';
  benef_partita_iva='';
  benef_nome='';
  stato_mandato='';
  codice_tributo_irpef='';
  codice_tributo_inps='';
  codice_risc='';
  importo_lordo_mandato=0;
  importo_netto_irpef=0;
  importo_imponibile_irpef=0;
  importo_ritenuta_irpef=0;
  importo_netto_inps=0;
  importo_imponibile_inps=0;
  importo_ritenuta_inps=0;
  importo_netto_irap=0;
  importo_imponibile_irap=0;
  importo_ritenuta_irap=0;
  tipo_ritenuta_inps='';
  tipo_ritenuta_irpef='';
  tipo_ritenuta_irap='';
  codice_ritenuta_irap='';
  desc_ritenuta_irap='';
  benef_codice='';
  importo_ente_irap=0;
  importo_ente_inps=0;

  tipo_ritenuta_irpeg='';
  codice_tributo_irpeg='';
  importo_ritenuta_irpeg=0;
  importo_netto_irpeg=0;
  importo_imponibile_irpeg=0;
  codice_ritenuta_irpeg='';
  desc_ritenuta_irpeg='';
  importo_ente_irpeg=0;
  code_caus_770:='';
  desc_caus_770:='';
  code_caus_esenz:='';
  desc_caus_esenz:='';
  attivita_inizio:=NULL;
  attivita_fine:=NULL;
  attivita_code:='';
  attivita_desc:='';
  
end loop;

	/* 11/10/2016: e' stata richiesta IRAP, estraggo solo i dati relativi */
elsif p_tipo_ritenuta = 'IRAP' THEN
	idFatturaOld=0;
	contaQuotaIrap=0;
    importoParzIrapImpon =0;
    importoParzIrapNetto =0;
    importoParzIrapRiten =0;
    importoParzIrapEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRAP e
        	ordinare i dati per id fattura (doc_id) perche' ci sono
            fatture che sono legate a differenti mandati.
            In questo caso e' necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */        
	FOR elencoMandati IN
    select * from 
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere,
                siac_d_onere d_onere,
                siac_d_onere_tipo d_onere_tipo
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id         
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND upper(d_onere_tipo.onere_tipo_code) in('IRAP')
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    t_doc.doc_id,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo , 
                     t_subdoc.subdoc_importo_da_dedurre) irap,
        (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL),  
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id  
               -- inizio INC000001342288      
                             AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_mandato_da AND p_data_mandato_a))
                  OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
              AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_trasm_da AND p_data_trasm_a))
                  OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))           
    		--- fine INC000001342288	       
            --09/02/2017: aggiunto test sulla data quietanza
                  -- se specificata in input.
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))      
            --AND p_data_mandato_da =to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                AND t_ordinativo.ente_proprietario_id = p_ente_prop_id
                AND t_periodo.anno=p_anno
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> 'A'
                AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
                    /* devo testare la data di fine validita' perche'
                        quando un ordinativo e' annullato, lo trovo 2 volte,
                        uno con stato inserito e l'altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   ) mandati   
                where mandati.ord_id =     irap.ord_id    
                ORDER BY irap.doc_id, irap.subdoc_id                  
   loop           
        percQuota=0;    	          
       
   			/* verifico quante quote ci sono relative alla fattura */
		numeroQuoteFattura=0;
        SELECT count(*)
        INTO numeroQuoteFattura
        from siac_t_subdoc s
        where s.doc_id= elencoMandati.doc_id
        		--19/07/2017: prendo solo le quote NON STORNATE completamente.
            and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
        IF NOT FOUND THEN
        	numeroQuoteFattura=0;
        END IF;
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
        END IF;
        
        raise notice 'contaQuotaIrapXXX= %', contaQuotaIrap;
        
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irap=upper(elencoMandati.onere_tipo_code);
                				
        codice_ritenuta_irap=elencoMandati.onere_code;
        desc_ritenuta_irap=elencoMandati.onere_desc;
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);         
        raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'Importo da Dedurre= %', elencoMandati.IMP_DEDURRE;
        raise notice 'Perc quota = %', percQuota;
        
        	-- la fattura e' la stessa della quota precedente. 
		IF  idFatturaOld = elencoMandati.doc_id THEN
        	contaQuotaIrap=contaQuotaIrap+1;
        	raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
            	-- E' l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrap= numeroQuoteFattura THEN
            	raise notice 'ULTIMA QUOTA';
            	importo_imponibile_irap=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrapImpon;
                importo_ritenuta_irap=elencoMandati.IMPOSTA-importoParzIrapRiten;
                importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrapEnte;
                
                	-- azzero gli importi parziali per fattura
                importoParzIrapImpon=0;
        		importoParzIrapRiten=0;
        		importoParzIrapEnte=0;
        		importoParzIrapNetto=0;
                contaQuotaIrap=0;
            ELSE
            	raise notice 'ALTRA QUOTA';
            	importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        		importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        		importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
                importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;
                
                	-- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrapImpon=importoParzIrapImpon+importo_imponibile_irap;
                importoParzIrapRiten=importoParzIrapRiten+ importo_ritenuta_irap;
                importoParzIrapEnte=importoParzIrapEnte+importo_ente_irap;
                importoParzIrapNetto=importoParzIrapNetto+importo_netto_irap;
                --contaQuotaIrap=contaQuotaIrap+1;
                
            END IF;
        ELSE -- fattura diversa dalla precedente
        	raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irap = elencoMandati.IMPORTO_IMPONIBILE*percQuota/100;
        	importo_ritenuta_irap = elencoMandati.IMPOSTA*percQuota/100; 
        	importo_ente_irap=elencoMandati.IMPORTO_CARICO_ENTE*percQuota/100;
            importo_netto_irap=importo_lordo_mandato-importo_ritenuta_irap;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrapImpon=importo_imponibile_irap;
        	importoParzIrapRiten= importo_ritenuta_irap;
        	importoParzIrapEnte=importo_ente_irap;
       		importoParzIrapNetto=importo_netto_irap;
            contaQuotaIrap=1;            
        END IF;
        
                
      raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
      raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
      idFatturaOld=elencoMandati.doc_id;
            
      return next;
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
      desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
    end loop;        
      --end if;
elsif p_tipo_ritenuta = 'IRPEF' THEN
	idFatturaOld=0;
	contaQuotaIrpef=0;
    importoParzIrpefImpon =0;
    importoParzIrpefNetto =0;
    importoParzIrpefRiten =0;
    --importoParzIrpefEnte =0;
    
    	/* 11/10/2016: la query deve estrarre insieme mandati e dati IRPEF e
        	ordinare i dati per id fattura (doc_id) perche' ci sono
            fatture che sono legate a differenti mandati.
            In questo caso e' necessario riproporzionare l'importo
            dell'aliquota a seconda della percentuale della quota fattura
            relativa al mandato rispetto al totale fattura */        
	FOR elencoMandati IN
    select * from 
		(SELECT d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
            d_onere.onere_code, d_onere.onere_desc, t_ordinativo_ts.ord_id,
            t_subdoc.subdoc_id,t_doc.doc_id,d_onere.onere_id ,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
              t_doc.doc_importo IMPORTO_FATTURA,
              t_subdoc.subdoc_importo IMPORTO_QUOTA,
              t_subdoc.subdoc_importo_da_dedurre IMP_DEDURRE,
              sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
              sum(r_doc_onere.importo_carico_soggetto) IMPOSTA,
              sum(r_doc_onere.importo_carico_ente) IMPORTO_CARICO_ENTE
            from siac_t_ordinativo_ts t_ordinativo_ts,
                siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
                siac_t_doc t_doc, 
                siac_t_subdoc t_subdoc,
                siac_r_doc_onere r_doc_onere
                	LEFT JOIN siac_d_somma_non_soggetta_tipo d_dom_non_sogg_tipo
                    	ON (d_dom_non_sogg_tipo.somma_non_soggetta_tipo_id=
                        	  r_doc_onere.somma_non_soggetta_tipo_id
                            AND d_dom_non_sogg_tipo.data_cancellazione IS NULL),
                siac_d_onere d_onere,                	
                siac_d_onere_tipo d_onere_tipo               
            WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
                AND t_doc.doc_id=t_subdoc.doc_id
                and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
                AND r_doc_onere.doc_id=t_doc.doc_id
                AND d_onere.onere_id=r_doc_onere.onere_id
                AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id                                      
               -- AND t_ordinativo_ts.ord_id=mandati.ord_id
                AND upper(d_onere_tipo.onere_tipo_code) in('IRPEF')
                AND t_doc.data_cancellazione IS NULL
                AND t_subdoc.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
                AND t_ordinativo_ts.data_cancellazione IS NULL
                AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL                                
                GROUP BY d_onere_tipo.onere_tipo_code, d_onere_tipo.onere_tipo_desc,
                	t_ordinativo_ts.ord_id, t_subdoc.subdoc_id,
                    d_dom_non_sogg_tipo.somma_non_soggetta_tipo_code,
            		d_dom_non_sogg_tipo.somma_non_soggetta_tipo_desc,
                    t_doc.doc_id,d_onere.onere_id ,
                    d_onere.onere_code, d_onere.onere_desc,
                     t_doc.doc_importo, t_subdoc.subdoc_importo,
                     t_subdoc.subdoc_importo_da_dedurre  ) irpef
				/* 01/06/2017: aggiunta gestione delle causali 770 */                    
               LEFT JOIN (SELECT distinct r_onere_caus.onere_id,
               				r_doc_onere.doc_id,t_subdoc.subdoc_id,
               				COALESCE(d_causale.caus_code,'') caus_code_770,
                            COALESCE(d_causale.caus_desc,'') caus_desc_770
               			FROM siac_r_doc_onere r_doc_onere,
                        	siac_t_subdoc t_subdoc,
                        	siac_r_onere_causale r_onere_caus,
							siac_d_causale d_causale ,
							siac_d_modello d_modello                                                       
                    WHERE   t_subdoc.doc_id=r_doc_onere.doc_id                    	
                    	AND r_doc_onere.onere_id=r_onere_caus.onere_id
                        AND d_causale.caus_id=r_doc_onere.caus_id
                    	AND d_causale.caus_id=r_onere_caus.caus_id   
                    	AND d_modello.model_id=d_causale.model_id                                                      
                        AND d_modello.model_code='01' --Causale 770
                        AND r_doc_onere.ente_proprietario_id =p_ente_prop_id                      AND r_doc_onere.onere_id=5
                        AND r_onere_caus.validita_fine IS NULL                        
                        AND r_doc_onere.data_cancellazione IS NULL 
                        AND d_modello.data_cancellazione IS NULL 
                        AND d_causale.data_cancellazione IS NULL
                        AND t_subdoc.data_cancellazione IS NULL) caus_770
                    ON caus_770.onere_id=irpef.onere_id
                    	AND caus_770.doc_id=irpef.doc_id
                        AND caus_770.subdoc_id=irpef.subdoc_id,
        (select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
            t_periodo.anno anno_eser, t_ordinativo.ord_anno,
             t_ordinativo.ord_desc, t_ordinativo.ord_id,
            t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,     
            t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
            t_soggetto.partita_iva,t_soggetto.codice_fiscale,
            t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
            t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
            SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
            t_movgest.movgest_anno anno_impegno
            FROM  	siac_t_ente_proprietario ep,
                    siac_t_bil t_bil,
                    siac_t_periodo t_periodo,
                    siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
                    siac_t_bil_elem t_bil_elem,                  
                    siac_t_ordinativo t_ordinativo
                  --09/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                  	LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                   	on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                       	and r_ord_quietanza.data_cancellazione IS NULL),  
                    siac_t_ordinativo_ts t_ord_ts,
                    siac_r_liquidazione_ord r_liq_ord,
                    siac_r_liquidazione_movgest r_liq_movgest,
                    siac_t_movgest t_movgest,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_ordinativo_ts_det t_ord_ts_det,
                    siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                    siac_r_ordinativo_stato r_ord_stato,  
                    siac_d_ordinativo_stato d_ord_stato ,
                     siac_d_ordinativo_tipo d_ord_tipo,
                     siac_r_ordinativo_soggetto r_ord_soggetto ,
                     siac_t_soggetto t_soggetto  		    	
            WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	
                AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
                AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
               AND t_ordinativo.ord_id=r_ord_stato.ord_id
               AND t_bil.bil_id=t_ordinativo.bil_id
               AND t_periodo.periodo_id=t_bil.periodo_id
               AND t_ord_ts.ord_id=t_ordinativo.ord_id           
               AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
               AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
               AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
               AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
               AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
               AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
               AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
               AND r_liq_movgest.liq_id=r_liq_ord.liq_id
               AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
               AND t_movgest_ts.movgest_id=t_movgest.movgest_id    
                             AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_mandato_da AND p_data_mandato_a))
                  OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
              AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
                  AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_trasm_da AND p_data_trasm_a))
                  OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))           
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))                 
                AND t_ordinativo.ente_proprietario_id = p_ente_prop_id
                --and t_ordinativo.ord_numero in (6744,6745,6746)
                --and t_ordinativo.ord_numero in (7578,7579,7580)                
                AND t_periodo.anno=p_anno
                    /* Gli stati possibili sono:
                        I = INSERITO
                        T = TRASMESSO 
                        Q = QUIETANZIATO
                        F = FIRMATO
                        A = ANNULLATO 
                        Prendo tutti tranne gli annullati.
                       */
                AND d_ord_stato.ord_stato_code <> 'A'
                AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
                AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
                    /* devo testare la data di fine validita' perche'
                        quando un ordinativo e' annullato, lo trovo 2 volte,
                        uno con stato inserito e l'altro annullato */
                AND r_ord_stato.validita_fine IS NULL 
                AND ep.data_cancellazione IS NULL
                AND r_ord_stato.data_cancellazione IS NULL
                AND r_ordinativo_bil_elem.data_cancellazione IS NULL
                AND t_bil_elem.data_cancellazione IS NULL
                AND  t_bil.data_cancellazione IS NULL
                AND  t_periodo.data_cancellazione IS NULL
                AND  t_ordinativo.data_cancellazione IS NULL
                AND  t_ord_ts.data_cancellazione IS NULL
                AND  t_ord_ts_det.data_cancellazione IS NULL
                AND  d_ts_det_tipo.data_cancellazione IS NULL
                AND  r_ord_stato.data_cancellazione IS NULL
                AND  d_ord_stato.data_cancellazione IS NULL
                AND  d_ord_tipo.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL
                AND t_soggetto.data_cancellazione IS NULL
                AND r_liq_ord.data_cancellazione IS NULL 
                AND r_liq_movgest.data_cancellazione IS NULL 
                AND t_movgest.data_cancellazione IS NULL
                AND t_movgest_ts.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
                  t_periodo.anno , t_ordinativo.ord_anno,
                   t_ordinativo.ord_desc, t_ordinativo.ord_id,
                  t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,   
                  t_soggetto.soggetto_code, t_soggetto.soggetto_desc,  
                  t_soggetto.partita_iva,t_soggetto.codice_fiscale,                  
                  t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
                  t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno
                   ) mandati 
                where mandati.ord_id =     irpef.ord_id    
                ORDER BY irpef.doc_id, irpef.subdoc_id                  
   loop           
        percQuota=0;    	          
       
   			/* se la fattura e' nuova verifico quante quote ci sono 
            	relative alla fattura */
        IF  idFatturaOld <> elencoMandati.doc_id THEN
          numeroQuoteFattura=0;
          SELECT count(*)
          INTO numeroQuoteFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id
          	--19/07/2017: prendo solo le quote NON STORNATE completamente.
          	and s.subdoc_importo-s.subdoc_importo_da_dedurre>0;
          IF NOT FOUND THEN
              numeroQuoteFattura=0;
          END IF;
       
        --19/07/2017: devo calcolare il totale da dedurre su tutta la fattura
        --	per calcolare correttamente la percentuale della quota.
        importoTotDaDedurreFattura:=0;
        SELECT sum(s.subdoc_importo_da_dedurre)
          INTO importoTotDaDedurreFattura
          from siac_t_subdoc s
          where s.doc_id= elencoMandati.doc_id;
          IF NOT FOUND THEN
              importoTotDaDedurreFattura:=0;
          END IF;
        END IF;
        
        raise notice 'contaQuotaIrpefXXX= %', contaQuotaIrpef;
        stato_mandato= elencoMandati.ord_stato_code;

        nome_ente=elencoMandati.ente_denominazione;
        partita_iva_ente=elencoMandati.cod_fisc_ente;
        anno_ese_finanz=elencoMandati.anno_eser;
        desc_mandato=COALESCE(elencoMandati.ord_desc,'');

        anno_mandato=elencoMandati.ord_anno;
        numero_mandato=elencoMandati.ord_numero;
        data_mandato=elencoMandati.ord_emissione_data;
        benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
        benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
        benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
        benef_codice=COALESCE(elencoMandati.soggetto_code,'');
                
        tipo_ritenuta_irpef=upper(elencoMandati.onere_tipo_code);
                				
        codice_tributo_irpef=elencoMandati.onere_code;
        --desc_ritenuta_irpef=elencoMandati.onere_desc;
        code_caus_770:=COALESCE(elencoMandati.caus_code_770,'');
		desc_caus_770:=COALESCE(elencoMandati.caus_desc_770,'');
        code_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_code,'');
		desc_caus_esenz:=COALESCE(elencoMandati.somma_non_soggetta_tipo_desc,'');
        
        	-- calcolo la percentuale della quota corrente rispetto
            -- al totale fattura.
        --19/07/2017: La percentuale della quota deve essere calcolata tenendo conto
        --	della quota da dedurre.
        --percQuota = elencoMandati.IMPORTO_QUOTA*100/ elencoMandati.IMPORTO_FATTURA;  
        percQuota = (elencoMandati.IMPORTO_QUOTA-elencoMandati.IMP_DEDURRE)*100/ 
        	(elencoMandati.IMPORTO_FATTURA-importoTotDaDedurreFattura);               
        
        importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0); 
          
        raise notice 'irpef ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
        raise notice 'ESTRATTO: IMPON =%, RITEN = %, LORDO MANDATO = %', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,importo_lordo_mandato;          
        raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
        raise notice 'importo da dedurre quota: %; Importo da dedurre TOTALE = % ', 
        	elencoMandati.IMP_DEDURRE, importoTotDaDedurreFattura;
        raise notice 'Perc quota = %', percQuota;
        
        	-- la fattura e' la stessa della quota precedente. 
		IF  idFatturaOld = elencoMandati.doc_id THEN
        	contaQuotaIrpef=contaQuotaIrpef+1;
        	raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrpef;
            	
                -- E' l'ultima quota della fattura:
                -- gli importi sono quelli totali meno quelli delle quote
                -- precedenti, per evitare problemi di arrotondamento.            
            if contaQuotaIrpef= numeroQuoteFattura THEN
            	raise notice 'ULTIMA QUOTA';
            	importo_imponibile_irpef=elencoMandati.IMPORTO_IMPONIBILE-importoParzIrpefImpon;
                importo_ritenuta_irpef=round(elencoMandati.IMPOSTA-importoParzIrpefRiten,2);
                --importo_ente_irpef=elencoMandati.IMPORTO_CARICO_ENTE-importoParzIrpefEnte;
        raise notice 'importo_lordo_mandato = %, importo_ritenuta_irpef = %,
                		importoParzIrpefRiten = %',
                	 importo_lordo_mandato, importo_ritenuta_irpef, importoParzIrpefRiten;
				importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                
                raise notice 'Dopo ultima rata - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
                	-- azzero gli importi parziali per fattura
                importoParzIrpefImpon=0;
        		importoParzIrpefRiten=0;
        		importoParzIrpefNetto=0;
                contaQuotaIrpef=0;
            ELSE
            	raise notice 'ALTRA QUOTA';
            	importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
        		importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);         		
                importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;
                
                	-- sommo l'importo della quota corrente
                    -- al parziale per fattura.
                importoParzIrpefImpon=round(importoParzIrpefImpon+importo_imponibile_irpef,2);
                importoParzIrpefRiten=round(importoParzIrpefRiten+ importo_ritenuta_irpef,2);                
                importoParzIrpefNetto=round(importoParzIrpefNetto+importo_netto_irpef,2);
                raise notice 'Dopo altra quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            END IF;
        ELSE -- fattura diversa dalla precedente
        	raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            importo_imponibile_irpef = round(elencoMandati.IMPORTO_IMPONIBILE*percQuota/100,2);
        	importo_ritenuta_irpef = round(elencoMandati.IMPOSTA*percQuota/100,2);    
            importo_netto_irpef=importo_lordo_mandato-importo_ritenuta_irpef;

                -- imposto l'importo della quota corrente
                -- al parziale per fattura.            
            importoParzIrpefImpon=round(importo_imponibile_irpef,2);
        	importoParzIrpefRiten= round(importo_ritenuta_irpef,2);
       		importoParzIrpefNetto=round(importo_netto_irpef,2);
            
            raise notice 'Dopo prima quota - ParzImpon = %, ParzRiten = %, ParzNetto = %', importoParzIrpefImpon,importoParzIrpefRiten,importoParzIrpefNetto;    
            contaQuotaIrpef=1;            
        END IF;
                        
      raise notice 'IMPON =%, RITEN = %,  NETTO= %', importo_imponibile_irpef, importo_ritenuta_irpef,importo_netto_irpef; 
      idFatturaOld=elencoMandati.doc_id;
      
      -- Cerco le reversali del mandato per valorizzare il campo cod_risc
      -- non i numeri di reversali collegate.
      for elencoReversali in    
          select t_ordinativo.ord_numero
          from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,
                siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo,
                siac_r_doc_onere_ordinativo_ts r_doc_onere_ord_ts,
                siac_r_doc_onere r_doc_onere, siac_d_onere d_onere,
                siac_d_onere_tipo  d_onere_tipo
                where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                    AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                    AND t_ord_ts.ord_id=t_ordinativo.ord_id
                    AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                    AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                    AND r_doc_onere_ord_ts.ord_ts_id=t_ord_ts_det.ord_ts_id
                    AND r_doc_onere.doc_onere_id=r_doc_onere_ord_ts.doc_onere_id
                    AND d_onere.onere_id=r_doc_onere.onere_id
                      AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* cerco tutte le tipologie di relazione,
                            non solo RIT_ORD */
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
                AND r_doc_onere_ord_ts.data_cancellazione IS NULL
                AND r_doc_onere.data_cancellazione IS NULL
                AND d_onere.data_cancellazione IS NULL
                AND d_onere_tipo.data_cancellazione IS NULL
          loop
          	if codice_risc = '' THEN
                codice_risc = elencoReversali.ord_numero ::VARCHAR;
            else
                codice_risc = codice_risc||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;
          end loop;
      return next;
      
      raise notice '';
      
      nome_ente='';
      partita_iva_ente='';
      anno_ese_finanz=0;
      anno_mandato=0;
      numero_mandato=0;
      data_mandato=NULL;
      desc_mandato='';
      benef_cod_fiscale='';
      benef_partita_iva='';
      benef_nome='';
      stato_mandato='';
      codice_tributo_irpef='';
      codice_tributo_inps='';
      codice_risc='';
      importo_lordo_mandato=0;
      importo_netto_irpef=0;
      importo_imponibile_irpef=0;
      importo_ritenuta_irpef=0;
      importo_netto_inps=0;
      importo_imponibile_inps=0;
      importo_ritenuta_inps=0;
      importo_netto_irap=0;
      importo_imponibile_irap=0;
      importo_ritenuta_irap=0;
      tipo_ritenuta_inps='';
      tipo_ritenuta_irpef='';
      tipo_ritenuta_irap='';
      codice_ritenuta_irap='';
      desc_ritenuta_irap='';
      benef_codice='';
      importo_ente_irap=0;
      importo_ente_inps=0;

      tipo_ritenuta_irpeg='';
      codice_tributo_irpeg='';
      importo_ritenuta_irpeg=0;
      importo_netto_irpeg=0;
      importo_imponibile_irpeg=0;
      codice_ritenuta_irpeg='';
      desc_ritenuta_irpeg='';
      importo_ente_irpeg=0;
      code_caus_770:='';
      desc_caus_770:='';
      code_caus_esenz:='';
	  desc_caus_esenz:='';
      attivita_inizio:=NULL;
      attivita_fine:=NULL;
      attivita_code:='';
      attivita_desc:='';
      
   end loop;   
   
end if; -- FINE IF p_tipo_ritenuta

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- SIAC 5107 Maurizio - FINE

-- SIAC-5016 INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_capitoli_from_variazioni(INTEGER);
CREATE OR REPLACE FUNCTION fnc_siac_capitoli_from_variazioni(p_uid_variazione INTEGER)
	RETURNS TABLE(
		stato_variazione     VARCHAR,
		anno_capitolo        VARCHAR,
		numero_capitolo      VARCHAR,
		numero_articolo      VARCHAR,
		numero_ueb           VARCHAR,
		tipo_capitolo        VARCHAR,
		descrizione_capitolo VARCHAR,
		descrizione_articolo VARCHAR,
		-- Dati uscita
		missione       VARCHAR,
		programma      VARCHAR,
		titolo_uscita  VARCHAR,
		macroaggregato VARCHAR,
		-- Dati entrata
		titolo_entrata VARCHAR,
		tipologia      VARCHAR,
		categoria      VARCHAR,
		-- Importi
		var_competenza  VARCHAR,
		var_residuo     VARCHAR,
		var_cassa       VARCHAR,
		var_competenza1 VARCHAR,
		var_residuo1    VARCHAR,
		var_cassa1      VARCHAR,
		var_competenza2 VARCHAR,
		var_residuo2    VARCHAR,
		var_cassa2      VARCHAR,
		cap_competenza  VARCHAR,
		cap_residuo     VARCHAR,
		cap_cassa       VARCHAR,
		cap_competenza1 VARCHAR,
		cap_residuo1    VARCHAR,
		cap_cassa1      VARCHAR,
		cap_competenza2 VARCHAR,
		cap_residuo2    VARCHAR,
		cap_cassa2      VARCHAR
	) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
	v_separatore VARCHAR := ' : ';
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;

	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id_padre                      AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre is not null
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine,to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det_var.elem_det_importo)::VARCHAR impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det_var.elem_det_importo)::varchar impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det_var.elem_det_importo)::VARCHAR impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id
				,(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det.elem_det_importo)::VARCHAR impSta
				,siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id
				,(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det.elem_det_importo)::VARCHAR impRes
				,siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id
				,(siac_t_periodo.anno ||v_separatore|| siac_t_bil_elem_det.elem_det_importo)::VARCHAR impSca
				,siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = periodo_variazione.anno::INTEGER)
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = periodo_variazione.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5016 FINE

-- SIAC-5128 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
display_error='';

-- se ? presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
  strApp=REPLACE(ele_variazioni,',','');
  --raise notice 'VAR: %', strApp;
  intApp = strApp::INTEGER;
END IF;

select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
-------siac_v_mis_pro_tit_macr_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
insert into siac_rep_cap_up
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	-----cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
    cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')														
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
   


insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo           
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= p_anno 													
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- ? stata tolta) e FPVC        		
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')								
        and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
	siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	and	tb1.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	and	tb2.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	and	tb3.tipo_capitolo 	in ('STD','FSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpRes	and	tb4.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		in ('STD','FSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
                                    
  
  insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND  -- 06/09/2016: aggiunto FPVC
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	IN ('FPV','FPVC')
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		IN ('FPV','FPVC')
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		IN ('FPV','FPVC')
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		IN ('FPV','FPVC')
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
                 
                                       
                    


/*
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb6,siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where	
        tb6.elem_id	=	tb7.elem_id
        and 	
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
        tb6.periodo_anno = annoCapImp	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		= 'FPV'
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV'
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        
*/

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno, 
        v1.ente_proprietario_id,
        user_table utente,
        0,
        '',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2 
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_up tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente) 	
            -----------left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;           

 -------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  
    where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and 	testata_variazione.variazione_num in ('||ele_variazioni||') 
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------

 	for classifBilRec in
select 	t1.missione_tipo_desc	missione_tipo_desc,
		t1.missione_code		missione_code,
		t1.missione_desc		missione_desc,
		t1.programma_tipo_desc	programma_tipo_desc,
		t1.programma_code		programma_code,
		t1.programma_desc		programma_desc,
		t1.titusc_tipo_desc		titusc_tipo_desc,
		t1.titusc_code			titusc_code,
		t1.titusc_desc			titusc_desc,
		t1.macroag_tipo_desc	macroag_tipo_desc,
		t1.macroag_code			macroag_code,
		t1.macroag_desc			macroag_desc,
    	t1.bil_anno   			BIL_ANNO,
        t1.elem_code     		BIL_ELE_CODE,
        t1.elem_code2     		BIL_ELE_CODE2,
        t1.elem_code3			BIL_ELE_CODE3,
		t1.elem_desc     		BIL_ELE_DESC,
        t1.elem_desc2     		BIL_ELE_DESC2,
        t1.elem_id      		BIL_ELE_ID,
       	t1.elem_id_padre    	BIL_ELE_ID_PADRE,
    	COALESCE (t1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
    	COALESCE (t1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (t1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (t1.stanziamento_prev_res_anno,0)		stanziamento_prev_res_anno,
    	COALESCE (t1.stanziamento_anno_prec,0)			stanziamento_anno_prec,
    	COALESCE (t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2 ,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2                    
from siac_rep_mptm_up_cap_importi t1
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)   
        order by missione_code,programma_code,titusc_code,macroag_code
          loop
          missione_tipo_desc:= classifBilRec.missione_tipo_desc;
          missione_code:= classifBilRec.missione_code;
          missione_desc:= classifBilRec.missione_desc;
          programma_tipo_desc:= classifBilRec.programma_tipo_desc;
          programma_code:= classifBilRec.programma_code;
          programma_desc:= classifBilRec.programma_desc;
          titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
          titusc_code:= classifBilRec.titusc_code;
          titusc_desc:= classifBilRec.titusc_desc;
          macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
          macroag_code:= classifBilRec.macroag_code;
          macroag_desc:= classifBilRec.macroag_desc;
          bil_anno:=classifBilRec.bil_anno;
          bil_ele_code:=classifBilRec.bil_ele_code;
          bil_ele_desc:=classifBilRec.bil_ele_desc;
          bil_ele_code2:=classifBilRec.bil_ele_code2;
          bil_ele_desc2:=classifBilRec.bil_ele_desc2;
          bil_ele_id:=classifBilRec.bil_ele_id;
          bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
          bil_anno:=p_anno;
          stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
          stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
          stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
          stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
          stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
          stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
          stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
          stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
          stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
          stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
          impegnato_anno:=0;
          impegnato_anno1:=0;
          impegnato_anno2=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
---            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;
stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;


select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;


/*          
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;            */

-- restituisco il record complessivo
/*raise notice 'record %', classifBilRec.bil_ele_id;
 h_count:=h_count+1;
 raise notice 'n. record %', h_count;*/
return next;
bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;                    
    when others  THEN
      RTN_MESSAGGIO:='struttura bilancio altro errore';
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5128 Maurizio - FINE

-- SIAC-5134 INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_capitoli_from_variazioni(INTEGER);
CREATE OR REPLACE FUNCTION fnc_siac_capitoli_from_variazioni(p_uid_variazione INTEGER)
	RETURNS TABLE(
		stato_variazione     VARCHAR,
		anno_capitolo        VARCHAR,
		numero_capitolo      VARCHAR,
		numero_articolo      VARCHAR,
		numero_ueb           VARCHAR,
		tipo_capitolo        VARCHAR,
		descrizione_capitolo VARCHAR,
		descrizione_articolo VARCHAR,
		-- Dati uscita
		missione       VARCHAR,
		programma      VARCHAR,
		titolo_uscita  VARCHAR,
		macroaggregato VARCHAR,
		-- Dati entrata
		titolo_entrata VARCHAR,
		tipologia      VARCHAR,
		categoria      VARCHAR,
		-- Importi
		var_competenza  NUMERIC,
		var_residuo     NUMERIC,
		var_cassa       NUMERIC,
		var_competenza1 NUMERIC,
		var_residuo1    NUMERIC,
		var_cassa1      NUMERIC,
		var_competenza2 NUMERIC,
		var_residuo2    NUMERIC,
		var_cassa2      NUMERIC,
		cap_competenza  NUMERIC,
		cap_residuo     NUMERIC,
		cap_cassa       NUMERIC,
		cap_competenza1 NUMERIC,
		cap_residuo1    NUMERIC,
		cap_cassa1      NUMERIC,
		cap_competenza2 NUMERIC,
		cap_residuo2    NUMERIC,
		cap_cassa2      NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;

	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id_padre                      AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre is not null
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine,to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                         AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = periodo_variazione.anno::INTEGER)
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = periodo_variazione.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5134 FINE


-- SIAC-5150 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null)
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id 
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL    
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF pdce.movep_det_segno = 'Dare' THEN
       IF pdce.anno = p_anno THEN
          v_imp_dare := pdce.importo;
       ELSE
          v_imp_dare_prec := pdce.importo;
       END IF;   
    ELSIF pdce.movep_det_segno = 'Avere' THEN
       IF pdce.anno = p_anno THEN
          v_imp_avere := pdce.importo;
       ELSE
          v_imp_avere_prec := pdce.importo;
       END IF;                   
    END IF;               
    
    IF pdce.anno = p_anno THEN
       v_pdce_fam_code := pdce.pdce_fam_code;
    ELSE
       v_pdce_fam_code_prec := pdce.pdce_fam_code;
    END IF;
                                                                    
    END LOOP;

    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    --raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    --raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
    
    END IF;
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5150 FINE

-- SIAC-5151- CORRIGE -FINE
CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null)
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id 
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL    
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec := pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;

    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
    
    END IF;
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
--SIAC-5150 CORRIGE FINE

