/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 11.12.2018 Sofia INC000002911899_Aipo_conf_IndicatoriRep
-- HD-INC000002911899_Aipo_conf_IndicatoriRep_11122018.sql
/*Si rende necessario rendere operative le maschere di imputazione dei dati
per gli Indicatori di Previsione 2019 -2021.

Trattasi delle maschere nel Menù 6 - Funzioni Accessorie -

1 - Configura Indicatori (numero anno bilancio previsione)

2 - Configura Indicatori di Entrata

3 - Configura Indicatori di Spesa

4 - Configura Indicatori Sintetici

Per il Bilancio di Previsione 2019 - 2021 per l'Ente AIPO,
per le maschere di cui al punto 2 e al punto 3, occorrerà duplicare esattamente i dati 2015 - 2016
come quelli che si leggono posizionandosi con anno di Bilancio 2018.
In più occorrerà alimentare l'anno del 2017 con i dati che ci sono a sistema sul consuntivo 2017;

Per il Bilancio di Previsione 2019 - 2021 per l'Ente CMTO
occorrerà duplicare esattamente i dati 2015 - 2016 - 2017 come quelli che si leggono con anno di Bilancio 2018;

Verificare inoltre che le stampe si allineino con gli anni di bilancio in coerenza.

Si richiede tale attività con urgenza

Grazie

M. Giovanna Troiano*/

-- AIPO
-- popolamento parametro per attivazione su 2019
select liv.*
from siac_d_gestione_livello liv, siac_d_gestione_tipo a
where a.ente_proprietario_id=4
and   a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC'
and   liv.gestione_tipo_id=a.gestione_tipo_id
and   liv.data_cancellazione is null
and   liv.validita_fine is null
order by liv.ente_proprietario_id,liv.data_creazione

begin;
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
 'CONF_NUM_ANNI_BIL_PREV_INDIC_2019', '3', a.gestione_tipo_id, now(), NULL, a.ente_proprietario_id, now(), now(), NULL, 'INC000002911899'
 FROM siac_d_gestione_tipo a
 WHERE  a.ente_proprietario_id=4
    and a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC'
	and a.data_cancellazione IS NULL
    and not exists (select 1
      from siac_d_gestione_livello z
      where z.ente_proprietario_id=a.ente_proprietario_id
      and z.gestione_livello_code='CONF_NUM_ANNI_BIL_PREV_INDIC_2019');

--tabella di relazione
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
	gestione_livello_id, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'INC000002911899'
from siac_d_gestione_livello a
	where  a.ente_proprietario_id=4
        and a.gestione_livello_code ='CONF_NUM_ANNI_BIL_PREV_INDIC_2019'
		and a.data_cancellazione IS NULL
    and not exists (select 1
      from siac_r_gestione_ente z
      where z.ente_proprietario_id=a.ente_proprietario_id
      and z.gestione_livello_id=a.gestione_livello_id);



--    indicatori sintetici
select voce.voce_conf_ind_codice, voce.voce_conf_ind_desc,voce.voce_conf_ind_num_anni_input,voce.voce_conf_ind_tipo,
       conf.*
from siac_t_conf_indicatori_sint conf, siac_v_bko_anno_bilancio anno,siac_t_voce_conf_indicatori_sint  voce
where anno.ente_proprietario_id=4
and   anno.anno_bilancio=2018
and   conf.bil_id=anno.bil_id
and   voce.voce_conf_ind_id=conf.voce_conf_ind_id
--and   conf.data_cancellazione is null
--and   conf.validita_fine is null

select *
from siac_t_voce_conf_indicatori_sint voce
where voce.ente_proprietario_id=4


begin;
rollback;
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
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'INC000002911899'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id =4
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1
      from siac_t_conf_indicatori_sint z
      where z.bil_id=t_bil.bil_id
      and z.ente_proprietario_id=t_ente.ente_proprietario_id
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);



-- indicatori entrata
create table INC000002911899_siac_t_conf_indicatori_entrata
as select * from siac_t_conf_indicatori_entrata

-- 860
select * From INC000002911899_siac_t_conf_indicatori_entrata
-- popolamento con dati 2018/2017/2016

begin;
select * FROM "fnc_configura_indicatori_entrata"(4,'2019','2018',false, false);
select * FROM "fnc_configura_indicatori_entrata"(4,'2019','2017',false, false);
select * FROM "fnc_configura_indicatori_entrata"(4,'2019','2016',false, false);

SELECT a.*
FROM siac_t_conf_indicatori_entrata a,siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;



SELECT a.*
FROM siac_t_conf_indicatori_entrata a,siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;
---- 31

create table INC000002911899_siac_t_conf_indicatori_entrata_aipo
as select a.* FROM siac_t_conf_indicatori_entrata a,siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;

select *
from INC000002911899_siac_t_conf_indicatori_entrata_aipo

-- spostamento dati 2017 su anno_prec
rollback;
begin;
-- 2017
update siac_t_conf_indicatori_entrata a
set    conf_ind_importo_accert_anno_prec=coalesce(a.conf_ind_importo_accert_anno_prec_1,0),
	   conf_ind_importo_riscoss_anno_prec=coalesce(a.conf_ind_importo_riscoss_anno_prec_1,0)
FROM siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;

-- spostamento dati 2016,2015 da anno_prec_1, anno_prec_2 2018
rollback;
begin;
update siac_t_conf_indicatori_entrata a
set    conf_ind_importo_accert_anno_prec_1=coalesce(aprec.conf_ind_importo_accert_anno_prec_1,0),  -- 2016
	   conf_ind_importo_riscoss_anno_prec_1=coalesce(aprec.conf_ind_importo_riscoss_anno_prec_1,0),-- 2016
       conf_ind_importo_accert_anno_prec_2=coalesce(aprec.conf_ind_importo_accert_anno_prec_2,0),  -- 2015
	   conf_ind_importo_riscoss_anno_prec_2=coalesce(aprec.conf_ind_importo_riscoss_anno_prec_2,0) -- 2015
FROM siac_v_bko_anno_bilancio anno,
     siac_t_conf_indicatori_entrata aprec,  siac_v_bko_anno_bilancio anno_prec
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4
and   anno_prec.ente_proprietario_id=4
and   anno_prec.anno_bilancio=2018
and   aprec.bil_id=anno_prec.bil_id
and   aprec.classif_id_titolo=a.classif_id_titolo
and   aprec.classif_id_tipologia=a.classif_id_tipologia;


-- spesa
create table INC000002911899_siac_t_conf_indicatori_spesa
as select * from siac_t_conf_indicatori_spesa
-- 2513
-- 2612
select * From INC000002911899_siac_t_conf_indicatori_spesa

SELECT  a.classif_id_missione, a.*
FROM siac_t_conf_indicatori_spesa a,siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;

-- 99
-- popolamento con dati 2018/2017/2016
begin;
select * FROM "fnc_configura_indicatori_spesa"(4,'2019','2018',false, false);
select * FROM "fnc_configura_indicatori_spesa"(4,'2019','2017',false, false);
select * FROM "fnc_configura_indicatori_spesa"(4,'2019','2016',false, false);


create table INC000002911899_siac_t_conf_indicatori_spesa_aipo
as select a.* FROM siac_t_conf_indicatori_spesa a,siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;

select *
from INC000002911899_siac_t_conf_indicatori_spesa_aipo
-- spostamento dati 2017 da anno_prec_1
-- spostamento dati 2016,2015 da anno_prec_1, anno_prec_2 2018
begin;
-- 2017
update siac_t_conf_indicatori_spesa a
set    conf_ind_importo_fpv_anno_prec=coalesce(a.conf_ind_importo_fpv_anno_prec_1,0),
	   conf_ind_importo_impegni_anno_prec=coalesce(a.conf_ind_importo_impegni_anno_prec_1,0),
	   conf_ind_importo_pag_comp_anno_prec=coalesce(a.conf_ind_importo_pag_comp_anno_prec_1,0),
       conf_ind_importo_pag_res_anno_prec=coalesce(a.conf_ind_importo_pag_res_anno_prec_1,0),
       conf_ind_importo_res_def_anno_prec=coalesce(a.conf_ind_importo_res_def_anno_prec_1,0)
FROM siac_v_bko_anno_bilancio anno
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4;
rollback;
begin;
update siac_t_conf_indicatori_spesa a
set    conf_ind_importo_fpv_anno_prec_1=coalesce(aprec.conf_ind_importo_fpv_anno_prec_1,0), -- 2016
	   conf_ind_importo_impegni_anno_prec_1=coalesce(aprec.conf_ind_importo_impegni_anno_prec_1,0),
	   conf_ind_importo_pag_comp_anno_prec_1=coalesce(aprec.conf_ind_importo_pag_comp_anno_prec_1,0),
       conf_ind_importo_pag_res_anno_prec_1=coalesce(aprec.conf_ind_importo_pag_res_anno_prec_1,0),
       conf_ind_importo_res_def_anno_prec_1=coalesce(aprec.conf_ind_importo_res_def_anno_prec_1,0), -- 2016
       conf_ind_importo_fpv_anno_prec_2=coalesce(aprec.conf_ind_importo_fpv_anno_prec_2,0), -- 2015
	   conf_ind_importo_impegni_anno_prec_2=coalesce(aprec.conf_ind_importo_impegni_anno_prec_2,0),
	   conf_ind_importo_pag_comp_anno_prec_2=coalesce(aprec.conf_ind_importo_pag_comp_anno_prec_2,0),
       conf_ind_importo_pag_res_anno_prec_2=coalesce(aprec.conf_ind_importo_pag_res_anno_prec_2,0),
       conf_ind_importo_res_def_anno_prec_2=coalesce(aprec.conf_ind_importo_res_def_anno_prec_2,0) -- 2015
FROM siac_v_bko_anno_bilancio anno,
     siac_t_conf_indicatori_spesa aprec,  siac_v_bko_anno_bilancio anno_prec
WHERE anno.ente_proprietario_id=4
and   anno.anno_bilancio=2019
and   a.bil_id = anno.bil_id
AND   a.ente_proprietario_id=4
and   anno_prec.ente_proprietario_id=4
and   anno_prec.anno_bilancio=2018
and   aprec.bil_id=anno_prec.bil_id
and   aprec.classif_id_missione=a.classif_id_missione
and   aprec.classif_id_programma=a.classif_id_programma;
