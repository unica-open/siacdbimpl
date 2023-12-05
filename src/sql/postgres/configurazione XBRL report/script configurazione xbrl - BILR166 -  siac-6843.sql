/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into siac_t_xbrl_report (
  xbrl_rep_codice,  xbrl_rep_fase_code ,  xbrl_rep_tipologia_code ,  xbrl_rep_xsd_tassonomia,
  validita_inizio ,  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione)
select 'BILR166', 'REND' , 'SDB', 'bdap-sdb-rend-regioni_2019-01-07.xsd', 
	now(), NULL, ente_proprietario_id, now(),
	now(), NULL, 'SIAC-6843'
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_report z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_rep_codice='BILR166');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'acq_mat_prime_consumo_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AcquistoMateriePrime', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='acq_mat_prime_consumo_miss');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'variaz_rimanenz_materie_miss', 'COSTIMIS_Missione${missione_code_xbrl}_VarRimanenze', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='variaz_rimanenz_materie_miss');		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'prest_servizi_miss', 'COSTIMIS_Missione${missione_code_xbrl}_PrestServizi', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='prest_servizi_miss');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'trasf_correnti_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TrasfCorrenti', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='trasf_correnti_miss');		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'quota_ann_contr_pubb_invest_miss', 'COSTIMIS_Missione${missione_code_xbrl}_QuotaContrInvestPA', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='quota_ann_contr_pubb_invest_miss');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'contr_invest_altri_sogg_miss', 'COSTIMIS_Missione${missione_code_xbrl}_ContrInvestAltriSogg', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='contr_invest_altri_sogg_miss');
		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'utilizzo_beni_terzi_miss', 'COSTIMIS_Missione${missione_code_xbrl}_UtilizzoBeniTerzi', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='utilizzo_beni_terzi_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'personale_miss', 'COSTIMIS_Missione${missione_code_xbrl}_Personale', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='personale_miss');	


insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'ammort_immob_immateriali_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AmmortImmobImm', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='ammort_immob_immateriali_miss');		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'ammort_immob_materiali_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AmmortImmobMat', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='ammort_immob_materiali_miss');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'altre_svalut_immobiliz_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AltreSvalImmob', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='altre_svalut_immobiliz_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'svalut_crediti_miss', 'COSTIMIS_Missione${missione_code_xbrl}_SvalCrediti', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='svalut_crediti_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'accanton_rischi_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AccantRischi', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='accanton_rischi_miss');		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'altri_accanton_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AltriAccant', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='altri_accanton_miss');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'oneri_diversi_gest_miss', 'COSTIMIS_Missione${missione_code_xbrl}_OneriDiversiGest', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='oneri_diversi_gest_miss');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_comp_negativi_gest_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotCompNegGestione', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_comp_negativi_gest_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'interessi_altri_oneri_fin_miss', 'COSTIMIS_Missione${missione_code_xbrl}_InteressiAltriOneriFinanz', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='interessi_altri_oneri_fin_miss');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_oneri_finanziari_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotOneriFinanz', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_oneri_finanziari_miss');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'svalutazioni_miss', 'COSTIMIS_Missione${missione_code_xbrl}_Svalutazioni', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='svalutazioni_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_oneri_finanziari_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotRettValoreAttFinanz', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_oneri_finanziari_miss');	
		
		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'sopravv_passive_insuss_attive', 'COSTIMIS_Missione${missione_code_xbrl}_SopravvPassiveInsussAttivo', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='sopravv_passive_insuss_attive');		

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'minusvalenze_patrim_miss', 'COSTIMIS_Missione${missione_code_xbrl}_MinusvalPatr', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='minusvalenze_patrim_miss');	
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'trasferimenti_conto_cap_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TrasfCCapitale', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='trasferimenti_conto_cap_miss');			
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'altri_oneri_straord_miss', 'COSTIMIS_Missione${missione_code_xbrl}_AltriOneriStr', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='altri_oneri_straord_miss');	

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_oneri_straord_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotOneriStr', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_oneri_straord_miss');			
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'imposte_miss', 'COSTIMIS_Missione${missione_code_xbrl}_Imposte', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='imposte_miss');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_imposte_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotImposte', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_imposte_miss');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR166', 'tot_finale_costi_miss', 'COSTIMIS_Missione${missione_code_xbrl}_TotCosti', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6843', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR166'
		and xbrl_mapfat_variabile='tot_finale_costi_miss');		
		