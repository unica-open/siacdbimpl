/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.03.2019 Sofia HD-INC000003076928_p102
-- HD-INC000003076928_p102_ins_indicatoriSintetici_rendiconto_07032019.sql
/*
. From: eugenio.timo@parcodelpo-vcal.it
To: hd_contabilia@csi.it
Subject: Parco 102 - Menu 6 configura indicatori sentetici
---
Si prega aggiornare il Menu 6 per  i campi relativi ai valori per gli
indicatori rendiconto 2018. Grazie Eugenio Timo*/


--    indicatori sintetici
select voce.voce_conf_ind_codice, voce.voce_conf_ind_desc,voce.voce_conf_ind_num_anni_input,voce.voce_conf_ind_tipo,
       conf.*
from siac_t_conf_indicatori_sint conf, siac_v_bko_anno_bilancio anno,siac_t_voce_conf_indicatori_sint  voce
where anno.ente_proprietario_id=14
and   anno.anno_bilancio=2018
and   conf.bil_id=anno.bil_id
and   voce.voce_conf_ind_id=conf.voce_conf_ind_id
and   conf.data_cancellazione is null
and   conf.validita_fine is null


-- ha caricato i mancanti che per il 2018 erano quelli di tipo R ( rendiconto )
-- meglio caricarli sempre tutti a inizio anno
-- nella videata sono tutti insieme ( quelli di rendiconto sono etichettati come (rendicono))
rollback;
begin;
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
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'INC000003076928'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2018'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1
      from siac_t_conf_indicatori_sint z
      where z.bil_id=t_bil.bil_id
      and z.ente_proprietario_id=t_ente.ente_proprietario_id
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);


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
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'INC000003076928'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2018'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1
      from siac_t_conf_indicatori_sint z
      where z.bil_id=t_bil.bil_id
      and z.ente_proprietario_id=t_ente.ente_proprietario_id
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);