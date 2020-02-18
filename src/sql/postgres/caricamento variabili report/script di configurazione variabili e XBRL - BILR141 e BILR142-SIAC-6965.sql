/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- REPORT BILR141

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'rimb_pre_di_cui_ant_liquid',
        'Rimborso prestiti - di cui  Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
        0,
        'N',
        10,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where a2.ente_proprietario_id=z.ente_proprietario_id    
		and z.repimp_codice='rimb_pre_di_cui_ant_liquid'
		and z.bil_id=a.bil_id);

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR141'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'rimb_pre_di_cui_ant_liquid'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where a.ente_proprietario_id=z.ente_proprietario_id    
		and z.repimp_id=a.repimp_id
        and z.rep_id=rep_id);	

             
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,
	b.repimp_importo,b.repimp_modificabile,b.repimp_progr_riga
from siac_t_report a,
siac_t_report_importi b,
siac_r_report_importi c,
siac_t_bil d,
siac_t_periodo e
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
    and d.periodo_id=e.periodo_id
    and d.bil_id=b.bil_id    
    and a.rep_codice='BILR141'
    and e.anno='2019'
    and b.repimp_codice='rimb_pre_di_cui_ant_liquid'
	and not exists (select 1
    	from BKO_T_REPORT_IMPORTI z
        where z.rep_codice=a.rep_codice
        	and z.repimp_codice=b.repimp_codice); 

--CONFIGURAZIONE XBRL
--Equilibrio di parte corrente.
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'rimb_prest_di_cui_ant_liquid', 'EQREG-COR_RimborsoPrestitiEAL', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='rimb_prest_di_cui_ant_liquid');

--Saldo corrente ai fini della copertura degli investimenti pluriennali delle Regioni  a statuto ordinario		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Tot_sezione_A_2', 'EQREG-SAL_EquilibrioParteCorrente', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Tot_sezione_A_2');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Stanziamento_AAM_2', 'EQREG-SAL_UtilizzoRisultatoAmmFinanzSpeseCorrenti', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Stanziamento_AAM_2');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'ent_non_ricorr_no_coper_impegni', 'EQREG-SAL_EntrateNonRicorrentiNoCoperturaImpegni', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='ent_non_ricorr_no_coper_impegni');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'fpv_spese_corr', 'EQREG-SAL_FPVSpeseCorrentiIscrittoEntrata', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='fpv_spese_corr');		

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Entrate_titoli_1_2_3_non_sanit', 'EQREG-SAL_EntrateTitoli1-2-3NonSanitarie', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Entrate_titoli_1_2_3_non_sanit');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Entrate_titoli_1_2_3_sanit', 'EQREG-SAL_EntrateTitoli1-2-3FinanzSSN', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Entrate_titoli_1_2_3_sanit');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'spese_corr_non_sanit', 'EQREG-SAL_SpeseCorrentiNonSanitarieFinanzEntrateVincoloDest', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='spese_corr_non_sanit');
		
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'fpv_parte_corr', 'EQREG-SAL_FPVParteCorrenteNettoComponentiNonVincolate', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='fpv_parte_corr');
	
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'spese_corr_finanz_sanit', 'EQREG-SAL_SpeseCorrentiFinanzEntrateSSN', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='spese_corr_finanz_sanit');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'equil_parte_corr_invest_pluri', 'EQREG-SAL_EquilibrioParteCorrenteCoperturaInvestPluriennali', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='equil_parte_corr_invest_pluri');

--Saldo corrente ai fini della copertura degli investimenti pluriennali delle Autonomie speciali
/* QUESTA PARTE NON c'è nell'XML
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Tot_sezione_A_3', 'EQREG-AUTSPE_EquilibrioParteCorrente3', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Tot_sezione_A_3');

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'Stanziamento_AAM_3', 'EQREG-INVPLU_UtilizzoRisultatoAmmFinanzSpeseCorrenti3', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='Stanziamento_AAM_3');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'ent_non_ricorr_no_coper_impegni2', 'EQREG-AUTSPE_EntrNonricorr2', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='ent_non_ricorr_no_coper_impegni2');
		
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR141', 'equil_parte_corr_invest_pluri2', 'EQREG-AUTSPE_EquiParteCorrInvestPluri2', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR141'
		and xbrl_mapfat_variabile='equil_parte_corr_invest_pluri2');		
		*/

-- REPORT BILR142

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'f_di_cui_ant_liquid',
        'di cui  Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
        0,
        'N',
        12,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where a2.ente_proprietario_id=z.ente_proprietario_id    
		and z.repimp_codice='f_di_cui_ant_liquid'
		and z.bil_id=a.bil_id);

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR142'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'f_di_cui_ant_liquid'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where a.ente_proprietario_id=z.ente_proprietario_id    
		and z.repimp_id=a.repimp_id
        and z.rep_id=rep_id);	

             
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,
	b.repimp_importo,b.repimp_modificabile,b.repimp_progr_riga
from siac_t_report a,
siac_t_report_importi b,
siac_r_report_importi c,
siac_t_bil d,
siac_t_periodo e
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
    and d.periodo_id=e.periodo_id
    and d.bil_id=b.bil_id    
    and a.rep_codice='BILR142'
    and e.anno='2019'
    and b.repimp_codice='f_di_cui_ant_liquid'
	and not exists (select 1
    	from BKO_T_REPORT_IMPORTI z
        where z.rep_codice=a.rep_codice
        	and z.repimp_codice=b.repimp_codice); 

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,  xbrl_mapfat_tupla_nome,
  xbrl_mapfat_tupla_group_key,  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  validita_fine,  ente_proprietario_id,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR142', 'f_di_cui_ant_liquid', 'EQEL-COR_FondoAntLiq', NULL, 
   NULL, 'd_anno/anno_bilancio*0/', 'eur', 
   2, now(), NULL, ente_proprietario_id, now(), now(),
   NULL, 'SIAC-6965', 'duration', false
from siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_xbrl_mapping_fatti z 
      where t_ente.ente_proprietario_id=z.ente_proprietario_id
		and xbrl_mapfat_rep_codice='BILR142'
		and xbrl_mapfat_variabile='f_di_cui_ant_liquid');
		
		