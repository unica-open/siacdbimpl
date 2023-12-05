/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_d_prima_nota_rel_tipo
(
  pnota_rel_tipo_code,
  pnota_rel_tipo_desc,
  ente_proprietario_id,  
  validita_inizio,  
  data_creazione,
  data_modifica,
  login_operazione
)
SELECT tmp.code, tmp.descr, tep.ente_proprietario_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), now(),now(),'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('COGE-INV', 'Prima nota da contabilita generale'), ('INV-COGE', 'Prima nota da inventario contabile')) AS tmp(code, descr)
WHERE NOT EXISTS (select 1 
	from siac_d_prima_nota_rel_tipo z 
	where z.pnota_rel_tipo_code=tmp.code
	and z.ente_proprietario_id=tep.ente_proprietario_id
	and z.data_cancellazione is null
)
ORDER BY tep.ente_proprietario_id, tmp.code;


INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.urlapplicazione , FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
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

-- Aggiornamento azioni cespiti per allineamento con prototipo statico
UPDATE siac_t_azione SET azione_desc = 'Inserisci Tipo Bene' WHERE azione_code = 'OP-INV-insTipoBene';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Tipo Bene' WHERE azione_code = 'OP-INV-ricTipoBene';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Categoria Cespite' WHERE azione_code = 'OP-INV-insCategCespiti';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Categoria Cespite' WHERE azione_code = 'OP-INV-ricCategCespiti';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Donazione/Rinvenimento Cespite' WHERE azione_code = 'OP-INV-insDonazione';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Scheda Cespite' WHERE azione_code = 'OP-INV-insCespite';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Scheda Cespite' WHERE azione_code = 'OP-INV-ricCespite';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Registro Prime Note Definitive Verso Inventario Contabile' WHERE azione_code = 'OP-INV-ricRegistroA';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Prime Note Elaborate Dall''Inventario' WHERE azione_code = 'OP-INV-ricRegistroB';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Dismissione Beni' WHERE azione_code = 'OP-INV-insDisCespite';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Dismissione Beni' WHERE azione_code = 'OP-INV-ricDisCespite';
UPDATE siac_t_azione SET azione_desc = 'Ammortamento Annuo' WHERE azione_code = 'OP-INV-gestisciAmmAnnuo';
UPDATE siac_t_azione SET azione_desc = 'Ammortamento Massivo' WHERE azione_code = 'OP-INV-gestisciAmmMassivo';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Rivalutazione Cespite' WHERE azione_code = 'OP-INV-insRivCespite';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Rivalutazione Cespite' WHERE azione_code = 'OP-INV-ricRivCespite';
UPDATE siac_t_azione SET azione_desc = 'Inserisci Svalutazione Cespite' WHERE azione_code = 'OP-INV-insSvalCespite';
UPDATE siac_t_azione SET azione_desc = 'Ricerca Svalutazione Cespite' WHERE azione_code = 'OP-INV-ricSvalCespite';
UPDATE siac_t_azione SET azione_desc = 'Gestisci Categoria Cespite' WHERE azione_code = 'OP-INV-gestisciCategCespiti';
UPDATE siac_t_azione SET azione_desc = 'Gestisci Tipo Bene' WHERE azione_code = 'OP-INV-gestisciTipoBene';
UPDATE siac_t_azione SET azione_desc = 'Gestisci Scheda Cespite' WHERE azione_code = 'OP-INV-gestisciCespite';
UPDATE siac_t_azione SET azione_desc = 'Gestisci Variazione Cespite' WHERE azione_code = 'OP-INV-gestisciVarCespite';
UPDATE siac_t_azione SET azione_desc = 'Gestisci Dismissione Beni' WHERE azione_code = 'OP-INV-gestisciDisCespite';
