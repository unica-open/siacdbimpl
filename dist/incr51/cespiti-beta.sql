/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- gruppo azioni INV-INVENTARIO INIZIO

INSERT INTO
  siac.siac_d_gruppo_azioni
(
  gruppo_azioni_code,
  gruppo_azioni_desc,
  titolo, 
  validita_inizio,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  login_operazione
)
select 'INV',
'Inventario',
'12 - Inventario',
now(),
a.ente_proprietario_id,
now(),
now(),
'admin'
from siac_t_ente_proprietario a
where
not exists (select 1 
from siac_d_gruppo_azioni z 
where z.gruppo_azioni_code='INV'
and z.ente_proprietario_id=a.ente_proprietario_id
and z.data_cancellazione is null);

--- gruppo azioni INV-INVENTARIO FINE

-- AZIONI INIZIO
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azione_code, tmp.azione_desc, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, now(), dat.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
	--CATEGORIA
	('OP-INV-insCategCespiti', 'Inserisci categoria cespiti', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-gestisciCategCespiti', 'Gestisci categoria cespiti', 'AZIONE_SECONDARIA', 'INV'),
	('OP-INV-ricCategCespiti', 'Ricerca categoria cespiti', 'ATTIVITA_SINGOLA', 'INV'),
	
	--TIPO BENE
	('OP-INV-insTipoBene', 'Inserisci tipo bene cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-gestisciTipoBene', 'Gestisci tipo bene cespite', 'AZIONE_SECONDARIA', 'INV'),
	('OP-INV-ricTipoBene', 'Ricerca tipo bene cespite', 'ATTIVITA_SINGOLA', 'INV'),
	
	--CESPITE
	('OP-INV-insCespite', 'Inserisci anagrafica cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-gestisciCespite', 'Gestisci anagrafica cespite', 'AZIONE_SECONDARIA', 'INV'),
	('OP-INV-ricCespite', 'Ricerca anagrafica cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-insDonazione', 'Inserisci Donazione/Rinvenimento Cespite', 'ATTIVITA_SINGOLA', 'INV'),
	
	--VARIAZIONI CESPITE
	('OP-INV-gestisciVarCespite', 'Gestisci variazione cespite', 'AZIONE_SECONDARIA', 'INV'),
	('OP-INV-insRivCespite', 'Inserisci rivalutazione cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-ricRivCespite', 'Ricerca rivalutazione cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-insSvalCespite', 'Inserisci svalutazione cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-ricSvalCespite', 'Ricerca svalutazione cespite', 'ATTIVITA_SINGOLA', 'INV'),
	
	--DISMISSIONI CESPITE
	('OP-INV-insDisCespite', 'Inserisci dismissione cespite', 'ATTIVITA_SINGOLA', 'INV'),
	('OP-INV-gestisciDisCespite', 'Gestisci dismissione cespite', 'AZIONE_SECONDARIA', 'INV'),
	('OP-INV-ricDisCespite', 'Ricerca dismissione cespite', 'ATTIVITA_SINGOLA', 'INV')	
	
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_code = tmp.azione_code
	AND ta.ente_proprietario_id = dat.ente_proprietario_id
	AND ta.data_cancellazione IS NULL
);

--AZIONI FINE

--CODIFICHE: tipo calcolo inizio
INSERT INTO
  siac.siac_d_cespiti_categoria_calcolo_tipo
(
  cescat_calcolo_tipo_code,
  cescat_calcolo_tipo_desc,
  ente_proprietario_id,  
  validita_inizio,  
  data_creazione,
  data_modifica,
  login_operazione
)
SELECT tmp.code, tmp.descr, tep.ente_proprietario_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), now(),now(),'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('100', 'Quota intera'), ('50', '50% quota'),('12', 'In 12-esimi'),('365', 'In 365-esimi')) AS tmp(code, descr)
WHERE NOT EXISTS (select 1 
from siac_d_cespiti_categoria_calcolo_tipo z 
where z.cescat_calcolo_tipo_code=tmp.code
and z.ente_proprietario_id=tep.ente_proprietario_id
and z.data_cancellazione is null
)
ORDER BY tep.ente_proprietario_id, tmp.code;
--CODIFICHE: tipo calcolo fine

--CODIFICHE: classificazione giuridica inizio
insert into	siac_d_cespiti_classificazione_giuridica
(ces_class_giu_code,  ces_class_giu_desc, validita_inizio, data_creazione, ente_proprietario_id,  login_operazione)
SELECT tmp.code, tmp.descr,to_timestamp('2016-01-01', 'YYYY-MM-DD'), now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep           
CROSS JOIN(VALUES ('1','BENE DISPONIBILE'), ('2','BENE INDISPONIBILE'), ('3','BENE DEMANIALE')) as tmp(code, descr)
WHERE not exists (
 SELECT 1 FROM siac_d_cespiti_classificazione_giuridica et
 WHERE et.ces_class_giu_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.data_cancellazione is null); 
--CODIFICHE: classificazione giuridica fine

--CODIFICHE: eventi inizio
insert into siac_d_evento_tipo (evento_tipo_code, evento_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN(VALUES ('INV-COGE', 'Da Inventario Beni Mobili a CoGe')) as tmp(code, descr)
WHERE NOT EXISTS (
    SELECT 1
    FROM siac_d_evento_tipo tipo 
    WHERE tipo.evento_tipo_code=tmp.code
    and tipo.ente_proprietario_id=tep.ente_proprietario_id
    and tipo.data_cancellazione is null
);

insert into siac_d_evento_tipo (evento_tipo_code, evento_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN(VALUES ('COGE-INV', 'Da CoGe a Inventario Beni Mobili')) as tmp(code, descr)
WHERE NOT EXISTS (
    SELECT 1 FROM siac_d_evento_tipo tipo 
    WHERE tipo.evento_tipo_code=tmp.code
    and tipo.ente_proprietario_id=tep.ente_proprietario_id
    and tipo.data_cancellazione is null);

insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('VEM', 'Vendita bene Mobile con Minusvalenza','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);

 insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('AMR', 'Ammortamento Residuo Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);

insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('VEP', 'Vendita bene Mobile con Plusvalenza','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);
                    
insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('DIS', 'Dismissione Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);


insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('DON', 'Donazione Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);
            
insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('AMA', 'Ammortamento Annuo Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);

insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('RIV', 'Rivalutazione Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);

insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('SVA', 'Svalutazione Bene Mobile','INV-COGE')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);


insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('MVA', 'Modifica Valore Bene Mobile','COGE-INV')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);   
 
insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('ACQ','Acquisto Bene Mobile','COGE-INV')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null);   


insert into siac_d_evento (

			evento_code, 
            evento_desc,
            evento_tipo_id, 
            validita_inizio, 
            ente_proprietario_id, 
            login_operazione)

SELECT tmp.code, tmp.descr, dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'         
FROM siac_t_ente_proprietario tep
JOIN siac_d_evento_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id           
CROSS JOIN(VALUES ('VEN','Vendita Bene Mobile','COGE-INV')) as tmp(code, descr, tipo)
WHERE dgt.evento_tipo_code = tmp.tipo
and not exists (
 SELECT 1 FROM siac_d_evento et
 WHERE et.evento_code=tmp.code
 and et.ente_proprietario_id=tep.ente_proprietario_id
 and et.evento_tipo_id=dgt.evento_tipo_id
 and et.data_cancellazione is null); 

insert into siac_r_causale_ep_tipo_evento_tipo (
           causale_ep_tipo_id,
           evento_tipo_id, 
           validita_inizio, 
           ente_proprietario_id, 
           login_operazione) 

SELECT dge.causale_ep_tipo_id,dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep JOIN siac_d_evento_tipo dgt ON (tep.ente_proprietario_id=dgt.ente_proprietario_id) 
    JOIN siac_d_causale_ep_tipo dge ON (tep.ente_proprietario_id=dge.ente_proprietario_id)
CROSS JOIN(VALUES ('LIB','INV-COGE')) as tmp(causale,tipo) 
WHERE dgt.evento_tipo_code=tmp.tipo
and dge.causale_ep_tipo_code=tmp.causale          
and not exists (
 SELECT 1
 FROM siac_r_causale_ep_tipo_evento_tipo tipoc
 WHERE tipoc.causale_ep_tipo_id=dge.causale_ep_tipo_id
 and tipoc.evento_tipo_id=dgt.evento_tipo_id
 and tipoc.ente_proprietario_id=tep.ente_proprietario_id
 and tipoc.data_cancellazione is null);
 
insert into siac_r_causale_ep_tipo_evento_tipo (
           causale_ep_tipo_id,
           evento_tipo_id, 
           validita_inizio, 
           ente_proprietario_id, 
           login_operazione) 

SELECT dge.causale_ep_tipo_id,dgt.evento_tipo_id, to_timestamp('2016-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep JOIN siac_d_evento_tipo dgt ON (tep.ente_proprietario_id=dgt.ente_proprietario_id) 
    JOIN siac_d_causale_ep_tipo dge ON (tep.ente_proprietario_id=dge.ente_proprietario_id)
CROSS JOIN(VALUES ('LIB','COGE-INV')) as tmp(causale,tipo) 
WHERE dgt.evento_tipo_code=tmp.tipo
and dge.causale_ep_tipo_code=tmp.causale          
and not exists (
 SELECT 1
 FROM siac_r_causale_ep_tipo_evento_tipo tipoc
 WHERE tipoc.causale_ep_tipo_id=dge.causale_ep_tipo_id
 and tipoc.evento_tipo_id=dgt.evento_tipo_id
 and tipoc.ente_proprietario_id=tep.ente_proprietario_id
 and tipoc.data_cancellazione is null);
 --CODIFICHE: eventi fine
 
 --CODIFICHE: stato variazione cespiti inizio
 INSERT INTO siac_d_cespiti_variazione_stato (ces_var_stato_code, ces_var_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ces_var_stato_code, tmp.ces_var_stato_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('P', 'Provvisorio'),
	('D', 'Definitivo'),
	('A', 'Annullato')
) AS tmp(ces_var_stato_code, ces_var_stato_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cespiti_variazione_stato dcvs
	WHERE dcvs.ces_var_stato_code = tmp.ces_var_stato_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ces_var_stato_code;
 --CODIFICHE: stato variazione cespiti fine

--CODIFICHE: stato dismissione cespiti inizio
 INSERT INTO siac_d_cespiti_dismissioni_stato (ces_dismissioni_stato_code, ces_dismissioni_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.ces_dismissioni_stato_code, tmp.ces_dismissioni_stato_desc, tep.ente_proprietario_id, now(), 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES
	('P', 'Provvisorio'),
	('D', 'Definitivo'),
	('N.D.', 'Scritture non presenti')
) AS tmp(ces_dismissioni_stato_code, ces_dismissioni_stato_desc)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_cespiti_dismissioni_stato dcvs
	WHERE dcvs.ces_dismissioni_stato_code = tmp.ces_dismissioni_stato_code
	AND dcvs.ente_proprietario_id = tep.ente_proprietario_id
	AND dcvs.data_cancellazione IS NULL
)
ORDER BY tep.ente_proprietario_id, tmp.ces_dismissioni_stato_code;

 --CODIFICHE: stato dismissione cespiti fine
 

