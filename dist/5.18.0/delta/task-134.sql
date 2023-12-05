/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


/*
 * task-134
 * Paolo Simone
 */

select fnc_siac_bko_inserisci_azione('OP-BKOF020-aggiornaAccertamentoConBloccoRagioneria',
									 'Accertamenti - Backoffice aggiorna accertamento con blocco ragioneria', 
									 '/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE'
);