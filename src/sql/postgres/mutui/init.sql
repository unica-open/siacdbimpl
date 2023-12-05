/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


INSERT INTO siac_d_gruppo_azioni 
(gruppo_azioni_code, gruppo_azioni_desc, titolo, validita_inizio,
ente_proprietario_id,
login_operazione) 
select 'MUTUI', 
'Mutui',
'13 - Mutui',
now(),
e.ente_proprietario_id,
'admin'
from siac_t_ente_proprietario e where e.in_uso 
and not exists (select 1 from siac_d_gruppo_azioni x where 
x.gruppo_azioni_code='MUTUI' and ente_proprietario_id=e.ente_proprietario_id)
;




select fnc_siac_bko_inserisci_azione('OP-MUT-gestisciMutuo', 'Inserisci mutuo', 
	'/../siacbilapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'MUTUI');
	
select fnc_siac_bko_inserisci_azione('OP-MUT-leggiMutuo', 'Ricerca mutuo', 
	'/../siacbilapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'MUTUI');
	

	
INSERT INTO siac.siac_d_mutuo_tipo_tasso(mutuo_tipo_tasso_code, mutuo_tipo_tasso_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('F', 'Fisso'),
	('V', 'Variabile')
) AS tmp(codice, descrizione)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_tipo_tasso mtt
	WHERE mtt.mutuo_tipo_tasso_code = tmp.codice
	and mtt.ente_proprietario_id=e.ente_proprietario_id
);

INSERT INTO siac.siac_d_mutuo_periodo_rimborso(mutuo_periodo_rimborso_code, mutuo_periodo_rimborso_desc,
	mutuo_periodo_numero_mesi, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, tmp.numero_mesi, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('M', 'Mensile', 1),
	('B', 'Bimestrale',2),
	('T', 'Trimestrale',3),
	('Q', 'Quadrimestrale',4),
	('S', 'Semestrale',6),
	('A', 'Annuale',12)
) AS tmp(codice, descrizione, numero_mesi)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_periodo_rimborso mpr
	WHERE mpr.mutuo_periodo_rimborso_code = tmp.codice
	and mpr.ente_proprietario_id=e.ente_proprietario_id
);


INSERT INTO siac.siac_d_mutuo_stato(mutuo_stato_code, mutuo_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('B', 'BOZZA'),
	('D', 'DEFINITIVO'),
	('A', 'ANNULLATO')
) AS tmp(codice, descrizione)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_stato ms
	WHERE ms.mutuo_stato_code = tmp.codice
	and ms.ente_proprietario_id = e.ente_proprietario_id
);

delete from siac.siac_d_mutuo_stato where mutuo_stato_code = 'V';

INSERT INTO siac.siac_d_mutuo_variazione_tipo (mutuo_variazione_tipo_code, mutuo_variazione_tipo_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('P', 'PIANO'),
	('T', 'TASSO')
) AS tmp(codice, descrizione)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_variazione_tipo ms
	WHERE ms.mutuo_variazione_tipo_code = tmp.codice
	and ms.ente_proprietario_id = e.ente_proprietario_id
);

