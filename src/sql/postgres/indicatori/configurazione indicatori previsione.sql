/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
	Questa istruzione e' già stata lanciata l'anno scorso e non dovrebbe essere lanciata.
	Potrebbe servire solo nel caso ci sia un ente nuovo.

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

*/

-- Inserimento del parametro che identifica quanti anni indietro si deve andare per le stampe degli indicatori.
-- Lo scorso anno era 3 per tutti gli enti, ho messo 3 anche per il 2019.
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
	gestione_livello_id, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin'
from siac_d_gestione_livello a
	where a.gestione_livello_code ='CONF_NUM_ANNI_BIL_PREV_INDIC_2019'
		and a.data_cancellazione IS NULL
    and not exists (select 1
      from siac_r_gestione_ente z
      where z.ente_proprietario_id=a.ente_proprietario_id
      and z.gestione_livello_id=a.gestione_livello_id);




--CONFIGURAZIONE DELLE TABELLE PER INDICATORI SINTETICI - 	REGIONE
-- i dati delle singole voci sulla tabella "siac_t_voce_conf_indicatori_sint" dovrebbero essere gli stessi, a meno che
-- nel 2019 non ne siano stati aggiunti di nuovi.
-- Sulla tabella "siac_t_conf_indicatori_sint" verranno registrati i valori dall'utente tramite apposita interfaccia.
-- La seguente INSERT va eseguita solo per Regione (comunque c'è L'ID dell'ente, quindi non dovrebbe creare problemi se
-- eseguita su altri DB).
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

/*  CONFIGURAZIONE DELLE TABELLE PER INDICATORI SINTETICI per Enti Strumentali
			Esclusi i seguenti enti:

		 1 = Citta' di Torino
		 2 = Regione Piemonte
		 3 = Citta' Metropolitana di Torino
		 8 = Ente modello EELL
		15 = Ente Fittizio Per Gestione
		29 = Comune di Alessandria
		30 = Comune di Vercelli
		31 = Provincia di Vercelli
		32 = Provincia di Asti
		33 = Scuola Comunale di Musica F.A. Vallotti

	Valgono le stesse considerazioni fatte per la Regione, cioe' su "siac_t_voce_conf_indicatori_sint" le varie voci
	dovrebbero essere le stesse del 2018.
		*/

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
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1
      from siac_t_conf_indicatori_sint z
      where z.bil_id=t_bil.bil_id
      and z.ente_proprietario_id=t_ente.ente_proprietario_id
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);

/*  CONFIGURAZIONE DELLE TABELLE PER INDICATORI SINTETICI per ENTI LOCALI.
			Inseriti solo per i seguenti enti:

		 1 = Citta' di Torino
		 3 = Citta' Metropolitana di Torino
		 8 = Ente modello EELL
		15 = Ente Fittizio Per Gestione
		29 = Comune di Alessandria
		30 = Comune di Vercelli
		31 = Provincia di Vercelli
		32 = Provincia di Asti
		33 = Scuola Comunale di Musica F.A. Vallotti

	Valgono le stesse considerazioni fatte per la Regione e per gli Enti Strumentali, cioe' su
	"siac_t_voce_conf_indicatori_sint" le varie voci dovrebbero essere le stesse del 2018.
		*/
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
	and t_ente.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
    and t_periodo.anno='2019'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1
      from siac_t_conf_indicatori_sint z
      where z.bil_id=t_bil.bil_id
      and z.ente_proprietario_id=t_ente.ente_proprietario_id
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);

-- Caricamento della configurazione per gli indicatori analitici per tutti gli enti.
-- Le procedure inseriscono i dati di  RENDICONTO dell'anno indicato come terzo pramentro (in questo caso 2018) per l'anno
-- di bilancio indicato come secondo parametro (2019).
-- Inserimento sulle tabelle siac_t_conf_indicatori_entrata e siac_t_conf_indicatori_spesa
-- ATTENZIONE che le preocedure lanciate per tutti gli enti (primo parametro = 0) potrebbero impiegare vari minuti.


/*
	Per le Entrate:
 Procedura per configurare i dati del Rendiconto di Entrata suddivisi per
 Titolo/Tipologia sulla tabella siac_t_conf_indicatori_entrata estraendoli dal
 sistema.
 La procedura inserisce i dati degli anni precedenti quello del bilancio indicato.
 La procedura puo' essere anche lanciata per aggiornare i dati gia' inseriti.

 Parametri:
 	- p_ente_prop_id; ente da configurare; indicare 0 per configurarli tutti.
  	- p_anno_ini_rend_prev; anno del bilancio interessato.
  	- p_anno; anno del rendiconto da inserire.
    - p_azzera_importi; se = true azzera gli importi dell'anno specificato invece che
    	calcolarli.
    - p_annulla_importi; se = true annulla gli importi dell'anno specificato invece che
    	calcolarli.

*/
select * FROM "fnc_configura_indicatori_entrata"(0,'2019','2018',false, false);

/*
	Per le Spese:
 Procedura per configurare i dati del Rendiconto di Spesa suddivisi per
 Missione/Programma sulla tabella siac_t_conf_indicatori_spesa estraendoli dal
 sistema.
 La procedura inserisce i dati degli anni precedenti quello del bilancio indicato.
 La procedura puo' essere anche lanciata per aggiornare i dati gia' inseriti.

 Parametri:
 	- p_ente_prop_id; ente da configurare; indicare 0 per configurarli tutti.
  	- p_anno_ini_rend_prev; anno del bilancio interessato.
  	- p_anno; anno del rendiconto da inserire.
    - p_azzera_importi; se = true azzera gli importi dell'anno specificato invece che
    	calcolarli.
    - p_annulla_importi; se = true annulla gli importi dell'anno specificato invece che
    	calcolarli.

*/
select * FROM "fnc_configura_indicatori_spesa"(0,'2019','2018',false, false);

