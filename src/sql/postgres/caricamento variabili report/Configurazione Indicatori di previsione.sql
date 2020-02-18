/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
	Configurazione degli indicatori di PREVISIONE da effettuare ad inizio anno.

	Per dettagli vedere il file all.sql della incr28.
	
*/

select *
from siac_d_gestione_tipo a
where a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC'

select *
from siac_d_gestione_livello a
where a.gestione_livello_code like '%CONF_NUM_ANNI_BIL_PREV_INDIC_%'

-- Configurazione dei record per la gestione del parametro GESTIONE_NUM_ANNI_BIL_PREV_INDIC.
-- SOLO se nopn e' gia' stata effettuata una proma volta (ente nuovo).

INSERT INTO siac_d_gestione_tipo (
   gestione_tipo_code,
  gestione_tipo_desc,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
 SELECT 'GESTIONE_NUM_ANNI_BIL_PREV_INDIC', 'Gestione del numero di anni relativi al bilancio di gestione per i report degli indicatori',
	now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'admin'
 FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_d_gestione_tipo z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_tipo_code='GESTIONE_NUM_ANNI_BIL_PREV_INDIC');
              
-- valore 3 per tutti gli enti      
INSERT INTO siac_d_gestione_livello (
  gestione_livello_code,
  gestione_livello_desc,
  gestione_tipo_id,
  validita_inizio ,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT 
 'CONF_NUM_ANNI_BIL_PREV_INDIC_2019', '3', a.gestione_tipo_id, now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'admin'
 FROM siac_d_gestione_tipo a
 WHERE a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC' 
    and 
	 a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_d_gestione_livello z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_livello_code='CONF_NUM_ANNI_BIL_PREV_INDIC_2019');
      
      
INSERT INTO siac_r_gestione_ente (
 gestione_livello_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
 SELECT 
	gestione_livello_id, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin'
from siac_d_gestione_livello a
	where a.gestione_livello_code ='CONF_NUM_ANNI_BIL_PREV_INDIC_2019'
		and a.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_r_gestione_ente z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.gestione_livello_id=a.gestione_livello_id);      
      

-- Configurazione dei dati di rendiconto per gli indicatori di previsione

-- ENTRATA - modificare le annualita'
select * FROM "fnc_configura_indicatori_entrata"(0,'2019','2018',false, false);
select * FROM "fnc_configura_indicatori_entrata"(0,'2019','2017',false, false);
select * FROM "fnc_configura_indicatori_entrata"(0,'2019','2016',false, false);

-- SPESA - modificare le annualita'
select * FROM "fnc_configura_indicatori_spesa"(0,'2019','2018',false, false);
select * FROM "fnc_configura_indicatori_spesa"(0,'2019','2017',false, false);
select * FROM "fnc_configura_indicatori_spesa"(0,'2019','2016',false, false);

-- INDICATORI SINTETICI.
-- Inserire l'ente proprietario corretto.
select *
from siac_t_voce_conf_indicatori_sint a
where a.ente_proprietario_id=2    

INSERT INTO  siac_t_conf_indicatori_sint (
voce_conf_ind_id,
  bil_id,
  conf_ind_valore_anno,
  conf_ind_valore_anno_1,
  conf_ind_valore_anno_2,
  conf_ind_valore_tot_miss_13_anno,
  conf_ind_valore_tot_miss_13_anno_1 ,
  conf_ind_valore_tot_miss_13_anno_2 ,
  conf_ind_valore_tutte_spese_anno ,
  conf_ind_valore_tutte_spese_anno_1 ,
  conf_ind_valore_tutte_spese_anno_2 ,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione)
SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'admin'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
	and t_ente.ente_proprietario_id in (2)
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
	  
	  
	  