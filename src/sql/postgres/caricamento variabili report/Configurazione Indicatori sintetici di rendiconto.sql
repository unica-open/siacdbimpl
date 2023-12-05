/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* INIZIO CONFIGURAZIONE PER REPORT SINTETICI */



		/* INDICATORI SINTETICI RENDICONTO per Enti Strumentali
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
		
		*/
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
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
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
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


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
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

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
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
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
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

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
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni(rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

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
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
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
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
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
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

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
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
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
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

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
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
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
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  

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
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
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
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

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
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
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
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
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
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

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
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


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
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

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
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


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
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
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
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
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
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

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
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
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
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
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
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id not in (1,2,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
	  
	  
	  
	  

		/* INDICATORI SINTETICI RENDICONTO per REGIONE
		
		*/
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
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');

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
SELECT 'utilizzo_fondo_anticip_rnd','Utilizzo Fondo anticipazioni di liquidità del DL 35/2013 (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (2)
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
SELECT 'popolaz_residente_rnd','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile) - (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (2)
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
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
	  
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
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


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
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

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
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
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
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

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
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

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
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
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
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
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
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

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
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
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
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

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
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
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
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  
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
SELECT 'disav_debito_aut_non_contr_rnd','Disavanzo derivante da debito autorizzato e non contratto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
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
SELECT 'disav_ammin_lettera_e_rnd','Disavanzo di amministrazione di cui alla lettera E dell''allegato al rendiconto riguardante il risultato di amministrazione presunto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_ammin_lettera_e_rnd');	 
	  
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
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
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
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

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
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
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
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
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
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

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
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


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
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

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
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


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
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
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
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
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
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

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
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
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
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (2)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
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
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (2)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
	  
	  

		/* INDICATORI SINTETICI RENDICONTO per ENTI LOCALI
		
		*/
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
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');

	  
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
SELECT 'popolaz_residente_rnd','Popolazione residente al 1 gennaio(al 1 gennaio dell''esercizio di riferimento o, se non disponibile, al 1 gennaio dell''ultimo anno disponibile) - (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where t_ente.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
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
SELECT 'ripiano_disav_rnd','Ripiano disavanzo a carico dell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='ripiano_disav_rnd');
	  
	  
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
SELECT 'somm_utilizzi_rnd','Sommatoria degli utilizzi giornalieri delle anticipazioni nell''esercizio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somm_utilizzi_rnd');


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
SELECT 'anticip_tesoreria_rnd','Anticipazione di tesoreria all''inizio dell''esercizio successivo (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='anticip_tesoreria_rnd');

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
SELECT 'max_previsto_norma_rnd','Importo massimo previsto nella norma (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='max_previsto_norma_rnd');
	  
	  
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
SELECT 'margine_corr_comp_rnd','Margine corrente di competenza (Entrate titolo 1, 2 3 - Spese Titolo 1 - Spese Titolo 4) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='margine_corr_comp_rnd');
	  

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
SELECT 'accens_prest_rinegoz_rnd','Accensione prestiti da rinegoziazioni (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='accens_prest_rinegoz_rnd');	  
	  

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
SELECT 'giorni_effett_rnd','Giorni effettivi intercorrenti tra la data di scadenza della fattura o richiesta equivalente di pagamento e la data di pagamento ai fornitori moltiplicata per l''importo dovuto (rendiconto)', 0, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='giorni_effett_rnd');	  
	  
	  
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
SELECT 'somma_imp_pagati_rnd','Somma degli importi pagati nel periodo di riferimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='somma_imp_pagati_rnd');	  	  
	  
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
SELECT 'impegni_estinz_anticip_rnd','Impegni per estinzioni anticipate (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='impegni_estinz_anticip_rnd');

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
SELECT 'debito_finanz_anno_prec_rnd','Debito da finanziamento al 31 dicembre anno precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='debito_finanz_anno_prec_rnd');
	  
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
SELECT 'disav_amm_eser_prec_rnd','Disavanzo di amministrazione esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_prec_rnd');	 

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
SELECT 'disav_amm_eser_corso_rnd','Disavanzo di amministrazione esercizio in corso (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_amm_eser_corso_rnd');	  
	  
	  
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
SELECT 'tot_disav_eser_prec_rnd','Totale Disavanzo esercizio precedente (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_eser_prec_rnd');	
	  
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
SELECT 'disav_debito_aut_non_contr_rnd','Disavanzo derivante da debito autorizzato e non contratto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
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
SELECT 'disav_ammin_lettera_e_rnd','Disavanzo di amministrazione di cui alla lettera E dell''allegato al rendiconto riguardante il risultato di amministrazione presunto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_ammin_lettera_e_rnd');	 
	  
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
SELECT 'tot_disav_amm_rnd','Totale Disavanzo amministrazione (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='tot_disav_amm_rnd');	
	  

	  
	  
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
SELECT 'disav_iscrit_spesa_rnd','Disavanzo iscritto in spesa del conto del bilancio (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='disav_iscrit_spesa_rnd');
	  

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
SELECT 'patrimonio_netto_rnd','Patrimonio netto (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='patrimonio_netto_rnd');
 	  
	 
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
SELECT 'importo_debiti_fuori_bil_ricon_rnd','Importo Debiti fuori bilancio riconosciuti e finanziati (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_rnd');	  

	  
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
SELECT 'importo_debiti_fuori_bil_corso_ricon_rnd','Importo debiti fuori bilancio in corso di riconoscimento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_corso_ricon_rnd');	  
	  

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
SELECT 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd','Importo Debiti fuori bilancio riconosciuti e in corso di finanziamento (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='importo_debiti_fuori_bil_ricon_corso_finanz_rnd');	  
	  


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
SELECT 'input_colonna_a_rnd','Input totale colonna A - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_a_rnd');	  
	  
	  

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
SELECT 'input_colonna_c_rnd','Input totale colonna C - Allegato b) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='input_colonna_c_rnd');	  


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
SELECT 'a_ris_amm_presunto_rnd','A) Risultato di amministrazione presunto al 31/12 anno precedente - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='a_ris_amm_presunto_rnd');	  
	  
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
SELECT 'b_tot_parte_accant_rnd','B) Totale parte accantonata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='b_tot_parte_accant_rnd');	  
	  
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
SELECT 'c_tot_parte_vinc_rnd','C) Totale parte vincolata - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='c_tot_parte_vinc_rnd');	 

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
SELECT 'd_tot_dest_invest_rnd','D) Totale parte destinata agli investimenti - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='d_tot_dest_invest_rnd');	 

	  
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
SELECT 'e_tot_parte_disp_rnd','E) Totale parte disponibile - Allegato a) (rendiconto)', 2, 1, false, now(), NULL, ente_proprietario_id, now(), now(), NULL, 'admin', 'R'
FROM siac_t_ente_proprietario t_ente
where data_cancellazione IS NULL
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and not exists (select 1 
      from siac_t_voce_conf_indicatori_sint z 
      where z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_codice='e_tot_parte_disp_rnd');	 
	  

/* inserimento dei record dove si registrano i valori */
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
    and t_periodo.anno='2017'
    and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
	and t_ente.ente_proprietario_id  in (1,3,8,15,29,30,31,32,33)
	and t_ente.data_cancellazione IS NULL
	and	t_bil.data_cancellazione IS NULL
    and not exists (select 1 
      from siac_t_conf_indicatori_sint z 
      where z.bil_id=t_bil.bil_id 
      and z.ente_proprietario_id=t_ente.ente_proprietario_id 
      and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);