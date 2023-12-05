/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- PREVISIONE
select fnc_siac_bko_inserisci_azione(
	'OP-ENT-ConfStpFdce', 
	'Gestione Fondi Dubbia Esigibilità - Previsione', 
	'/../siacbilapp/azioneRichiesta.do', 
	'ATTIVITA_SINGOLA', 
	'BIL_CAP_PREV'
);

-- GESTIONE
select fnc_siac_bko_inserisci_azione(
	'OP-ENT-ConfStpFdceGes', 
	'Gestione Fondi Dubbia Esigibilità - Gestione', 
	'/../siacbilapp/azioneRichiesta.do', 
	'ATTIVITA_SINGOLA', 
	'BIL_CAP_GES'
);

-- RENDICONTO
select fnc_siac_bko_inserisci_azione(
	'OP-ENT-ConfStpFdceRen', 
	'Gestione Fondi Dubbia Esigibilità - Rendiconto', 
	'/../siacbilapp/azioneRichiesta.do', 
	'ATTIVITA_SINGOLA', 
	'BIL_CAP_GES'
);

-- TORNA IN BOZZA GESTIONE PER PROFILO SPECIFICO
select fnc_siac_bko_inserisci_azione(
	'OP-ENT-ConfStpFdceGes-Bozza', 
	'Gestione Fondi Dubbia Esigibilità - GESTIONE - Ritorno in BOZZA', 
	'/../siacbilapp/azioneRichiesta.do', 
	'AZIONE_SECONDARIA', 
	'BIL_CAP_GES'
);