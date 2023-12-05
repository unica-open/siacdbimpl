/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



declare
 
/* Esempio:
 * 
 * select fnc_siac_bko_inserisci_azione('OP-BKOF014-annullaAttivazioniContabili', 'Annulla attivazioni contabili', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
 * 
 */

begin
	
 INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select codice, descrizione, ta.azione_tipo_id, ga.gruppo_azioni_id, url, CURRENT_DATE,
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = codice_tipo
  and ga.gruppo_azioni_code = codice_gruppo
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code=codice);
  	
  return 'azione creata o esistente';

end;
;
