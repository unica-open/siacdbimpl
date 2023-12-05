/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.urlapplicazione , FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	--CATEGORIA
	('OP-INV-insCategCespiti', 'Inserisci Categoria Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciCategCespiti', 'Gestisci Categoria Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricCategCespiti', 'Ricerca Categoria Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--TIPO BENE
	('OP-INV-insTipoBene', 'Inserisci Tipo Bene', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciTipoBene', 'Gestisci Tipo Bene', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricTipoBene', 'Ricerca Tipo Bene', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--CESPITE
	('OP-INV-insCespite', 'Inserisci Scheda Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciCespite', 'Gestisci Scheda Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricCespite', 'Ricerca Scheda Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insDonazione', 'Inserisci Donazione/Rinvenimento Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--VARIAZIONI CESPITE
	('OP-INV-gestisciVarCespite', 'Gestisci Variazione Cespite', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insRivCespite', 'Inserisci Rivalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricRivCespite', 'Ricerca Rivalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-insSvalCespite', 'Inserisci Svalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricSvalCespite', 'Ricerca Svalutazione Cespite', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	--DISMISSIONI CESPITE
	('OP-INV-insDisCespite', 'Inserisci Dismissione Beni', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciDisCespite', 'Gestisci Dismissione Beni', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-ricDisCespite', 'Ricerca Dismissione Beni', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	-- *****************************************************************************************
	------ V02
	('OP-INV-gestisciAmmMassivo','Ammortamento Massivo', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciAmmAnnuo','Ammortamento Annuo', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	---V03
	('OP-FLUSSO-CESPITI','Gestione flusso cespiti', 'ATTIVITA_SINGOLA', 'INV', '/../siacintegser/ElaboraFileService'),
	--V04
	('OP-INV-ricRegistroB', 'Ricerca Prime Note Elaborate Dall''Inventario', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciRegistroB', 'Gestisci registro B', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-validaRegistroB', 'Valida registro B', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	--V05
	-- REGISTRO A
	('OP-INV-ricRegistroA', 'Ricerca Registro Prime Note Definitive Verso Inventario Contabile', 'ATTIVITA_SINGOLA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	('OP-INV-gestisciRegistroA', 'Gestisci Registro Prime Note Definitive Verso Inventario Contabile', 'AZIONE_SECONDARIA', 'INV', '/../siacbilapp/azioneRichiesta.do'),
	
	
	-- Per comodita' di scrittura
	(null, null, null, null, null)
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code, urlapplicazione) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);
