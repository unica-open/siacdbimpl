/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6257

INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2016',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2016'
and z.ente_proprietario_id=a.ente_proprietario_id);


INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2017',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2017'
and z.ente_proprietario_id=a.ente_proprietario_id);


INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2018',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2018'
and z.ente_proprietario_id=a.ente_proprietario_id);



INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2019',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2019'
and z.ente_proprietario_id=a.ente_proprietario_id);



insert into siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_cancellazione,
  login_operazione
)
select 
rop.ruolo_op_id,
a0.azione_id,
now(),
null,
a0.ente_proprietario_id,
null,
'admin' 
from siac_t_azione a0,
(select ra.ruolo_op_id from siac_t_azione a, 
siac_r_ruolo_op_azione ra
where ra.azione_id=a.azione_id
and a.azione_code='OP-GESC004-ricVar'
and ra.data_cancellazione is NULL
and ra.validita_fine IS NULL
) rop
where a0.azione_code like 'OP-REP-ReportVariazioniBilancio-____'
and not exists (
select 1 from siac_r_ruolo_op_azione ra0
where ra0.azione_id=a0.azione_id
and ra0.ruolo_op_id=rop.ruolo_op_id);

-- SIAC-6257

--SIAC-6586 INIZIO
INSERT INTO 
  siac.siac_d_modifica_tipo(
  mod_tipo_code,
  mod_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'RORM','ROR - Da mantenere',
to_timestamp('01/01/2017','dd/mm/yyyy'),a.ente_proprietario_id,
'admin'
from siac.siac_t_ente_proprietario a 
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.mod_tipo_code = 'RORM'
	AND ta.data_cancellazione IS NULL
);
--SIAC-6586 FINE
-- SIAC-6640 Maurizio - INIZIO

  -- PREVISIONE 
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'utilizzo_fondo_anticip','Utilizzo Fondo anticipazioni di liquidita'' del DL 35/2013', 2, 3, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6640', 'P'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (5)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='utilizzo_fondo_anticip');
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'popolaz_residente','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6640','P'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (5)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='popolaz_residente');	  
	  
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_debito_autoriz', 'Disavanzo derivante da debito autorizzato e non contratto', 2, 3, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6640','P'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (5)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_debito_autoriz');

	  
	  
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
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'SIAC-6640'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
	and t_ente.ente_proprietario_id in (5)
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);

-- SIAC-6640 Maurizio - FINE
 
 
-- SIAC-6641 Maurizio - INIZIO  

-- RENDICONTO
INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'utilizzo_fondo_anticip_rnd','Utilizzo Fondo anticipazioni di liquidita'' del DL 35/2013 (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6641', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (5)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='utilizzo_fondo_anticip_rnd');
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'popolaz_residente_rnd','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile) - (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6641', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (5)
	and data_cancellazione IS NULL
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='popolaz_residente_rnd');	  	  
	  

INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_debito_aut_non_contr_rnd','Disavanzo derivante da debito autorizzato e non contratto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6641', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (5)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_debito_aut_non_contr_rnd');	 


INSERT INTO  siac_t_voce_conf_indicatori_sint (
voce_conf_ind_codice,
voce_conf_ind_desc,
voce_conf_ind_decimali,
voce_conf_ind_num_anni_input,
voce_conf_ind_split_missione_13,
validita_inizio,
validita_fine,
ente_proprietario_id,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione,
voce_conf_ind_tipo)
SELECT 'disav_ammin_lettera_e_rnd','Disavanzo di amministrazione di cui alla lettera E dell''allegato al rendiconto riguardante il risultato di amministrazione presunto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'SIAC-6641', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (5)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_ammin_lettera_e_rnd');	 

	  
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
	now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, 'SIAC-6641'
FROM siac_t_ente_proprietario t_ente,
	siac_t_bil t_bil,
    siac_t_periodo t_periodo,
    siac_t_voce_conf_indicatori_sint t_voce_ind
where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
	and t_bil.periodo_id=t_periodo.periodo_id
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (5)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);

-- SIAC-6641 Maurizio - FINE 