/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_d_siope_documento_tipo(siope_documento_tipo_code, siope_documento_tipo_desc, siope_documento_tipo_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('E', 'Elettronico', 'ELETTRONICO'),
	('A', 'Analogico', 'ANALOGICO')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_documento_tipo dsdt
	WHERE dsdt.ente_proprietario_id = tep.ente_proprietario_id
	AND dsdt.siope_documento_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_documento_tipo_analogico(siope_documento_tipo_analogico_code, siope_documento_tipo_analogico_desc, siope_documento_tipo_analogico_desc_bnkit, siope_documento_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, dsdt.siope_documento_tipo_id, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_siope_documento_tipo dsdt ON dsdt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('FA', 'Fattura analogica', 'FATT_ANALOGICA', 'A'),
	('DE', 'Documento equivalente', 'DOC_EQUIVALENTE', 'A')) AS tmp (code, descr, bnkit, tipo)
WHERE dsdt.siope_documento_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_documento_tipo_analogico dsdta
	WHERE dsdta.ente_proprietario_id = tep.ente_proprietario_id
	AND dsdta.siope_documento_tipo_analogico_code = tmp.code
	AND dsdta.siope_documento_tipo_id = dsdt.siope_documento_tipo_id
)
ORDER BY tep.ente_proprietario_id, tmp.code, tmp.tipo;

INSERT INTO siac.siac_d_siope_scadenza_motivo(siope_scadenza_motivo_code, siope_scadenza_motivo_desc, siope_scadenza_motivo_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('SF', 'Scadenza fattura', 'SCAD_FATTURA'),
	('CSF', 'Corretta scadenza fattura', 'CORRETTA_SCAD_FATTURA'),
	('SDT', 'Sospensione decorrenza termini', 'SOSP_DECORRENZA_TERMINI')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_scadenza_motivo dssm
	WHERE dssm.ente_proprietario_id = tep.ente_proprietario_id
	AND dssm.siope_scadenza_motivo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_assenza_motivazione(siope_assenza_motivazione_code, siope_assenza_motivazione_desc, siope_assenza_motivazione_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('AL', 'Acquisto locazione', 'ACQUISTO_LOCAZIONE'),
	('AR', 'Arbitrato', 'ARBITRATO'),
	('SB', 'Servizi BNKIT', 'SERVIZI_BNKIT'), 
	('CO', 'Contratti', 'CONTRATTI'),
	('AP', 'Appalti', 'APPALTI'),
	('AE', 'Appalti energia', 'APPALTI_ENERGIA'),
	('SP', 'Sponsorizzazione', 'SPONSORIZZAZIONE'),
	('PR', 'Prestazioni', 'PRESTAZIONI'),
	('SS', 'Scelta socio', 'SCELTA_SOCIO'),
	('ID', 'CIG in corso di definizione', '')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_assenza_motivazione dsam
	WHERE dsam.ente_proprietario_id = tep.ente_proprietario_id
	AND dsam.siope_assenza_motivazione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_siope_tipo_debito(siope_tipo_debito_code, siope_tipo_debito_desc, siope_tipo_debito_desc_bnkit, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.bnkit, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('CO', 'Commerciale', 'COMMERCIALE'),
	('NC', 'Non commerciale', 'NON_COMMERCIALE')) AS tmp (code, descr, bnkit)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_siope_tipo_debito dstd
	WHERE dstd.ente_proprietario_id = tep.ente_proprietario_id
	AND dstd.siope_tipo_debito_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('ORDINATIVI_MIF_TRASMISSIONE', 'Trasmissione ordinativi MIF')) AS tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac.siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017/01/01', 'YYYY/MM/DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS', 'Trasmissione ordinativi MIF a SIOPE+', 'ORDINATIVI_MIF_TRASMISSIONE'),
	('ORDINATIVI_MIF_TRASMETTI_UNIIT', 'Trasmissione ordinativi MIF a UNIIT', 'ORDINATIVI_MIF_TRASMISSIONE')) AS tmp (code, descr, tipo)
WHERE tmp.tipo = dgt.gestione_tipo_code
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_livello_code = tmp.code
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
)
ORDER BY tep.ente_proprietario_id, tmp.code, tmp.tipo;

INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017/01/01', 'YYYY/MM/DD'), dgl.ente_proprietario_id, 'admin'
FROM siac_d_gestione_livello dgl
WHERE dgl.gestione_livello_code = 'ORDINATIVI_MIF_TRASMETTI_UNIIT'
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = dgl.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
)
ORDER BY dgl.ente_proprietario_id;
