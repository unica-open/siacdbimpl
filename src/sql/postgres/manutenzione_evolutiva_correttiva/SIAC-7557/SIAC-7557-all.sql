 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	

CREATE TABLE IF NOT EXISTS siac.sirfel_t_dati_ritenuta (
  id_ritenuta SERIAL, 
  ente_proprietario_id INTEGER NOT NULL,
  id_fattura INTEGER NOT NULL,
  tipo VARCHAR(4) NOT NULL,
  importo NUMERIC(15,2) NOT NULL,
  aliquota NUMERIC(6,2) NOT NULL,
  causale_pagamento VARCHAR(4),
  validita_inizio timestamp without time zone NOT NULL,
  validita_fine timestamp without time zone,
  data_creazione timestamp without time zone NOT NULL DEFAULT now(),
  data_modifica timestamp without time zone NOT NULL DEFAULT now(),
  data_cancellazione timestamp without time zone,
  login_operazione character varying(200),
  CONSTRAINT pk_sirfel_t_dati_ritenuta PRIMARY KEY (id_ritenuta),
  CONSTRAINT sirfel_t_dati_ritenuta_fk1 FOREIGN KEY (id_fattura, ente_proprietario_id)
  REFERENCES siac.sirfel_t_fattura(id_fattura, ente_proprietario_id)
) ;

/*CREATE SEQUENCE IF NOT EXISTS siac.sirfel_t_dati_ritenuta_num_id_seq
  INCREMENT 1 MINVALUE 1
  MAXVALUE 9223372036854775807 START 1
  CACHE 1;
ALTER SEQUENCE siac.sirfel_t_dati_ritenuta_num_id_seq RESTART WITH 2;*/


CREATE OR REPLACE VIEW siac.siac_v_dwh_datiritenuta_sirfel
 AS
select siac.sirfel_t_fattura.id_fattura, siac.sirfel_t_dati_ritenuta.aliquota, siac.sirfel_t_dati_ritenuta.importo, siac.sirfel_t_dati_ritenuta.tipo
from siac.sirfel_t_dati_ritenuta, siac.sirfel_t_fattura
where siac.sirfel_t_fattura.id_fattura = siac.sirfel_t_dati_ritenuta.id_fattura 
and siac.sirfel_t_fattura.ente_proprietario_id = siac.sirfel_t_dati_ritenuta.ente_proprietario_id
and siac.sirfel_t_dati_ritenuta.data_cancellazione is null;

GRANT SELECT ON siac.siac_v_dwh_datiritenuta_sirfel TO siac_dwh; 

insert into siac.sirfel_t_dati_ritenuta 
(id_ritenuta, id_fattura, ente_proprietario_id, tipo, importo, aliquota, validita_inizio, data_creazione, data_modifica, login_operazione, causale_pagamento)  
select 
nextval('siac.SIRFEL_T_DATI_RITENUTA_NUM_ID_SEQ'), id_fattura, ente_proprietario_id, tipo_ritenuta, importo_ritenuta, aliquota_ritenuta, now(), data_inserimento, now(), 'SIAC-7557', causale_pagamento 
from siac.sirfel_t_fattura where tipo_ritenuta is not null;

drop table if exists siac.sirfel_t_fattura_bck;

create table siac.sirfel_t_fattura_bck as select * from siac.sirfel_t_fattura;

update siac.sirfel_t_fattura 
set tipo_ritenuta = null, aliquota_ritenuta = null, causale_pagamento = null, importo_ritenuta = null
where tipo_ritenuta is not null;


ALTER TABLE siac.sirfel_d_natura ALTER COLUMN codice TYPE varchar(4);
ALTER TABLE siac.sirfel_t_riepilogo_beni ALTER COLUMN natura TYPE VARCHAR(4);
ALTER TABLE siac.sirfel_t_cassa_previdenziale ALTER COLUMN natura TYPE VARCHAR(4);

/*
* N2.X Campi non soggetti
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.1',
'non soggette ad IVA ai sensi degli articoli da 7 a 7- septies del D.P.R. n. 633/1972'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.2',
'non soggette - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N3.X Campi non imponibili
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.1',
'non imponibili - esportazioni'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.2',
'non imponibili - cessioni intracomunitarie'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.3',
'non imponibili - cessioni verso San Marino'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.4',
'non imponibili - operazioni assimilate alle cessioni all’esportazione'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.5',
'non imponibili - a seguito di dichiarazioni d’intento'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.6',
'non imponibili - altre operazioni che non concorrono alla formazione del plafond'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N6.X Campi inversione contabile
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.1',
'inversione contabile - cessione di rottami e altri materiali di recupero'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.2',
'inversione contabile - cessione di oro e argento puro'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.3',
'inversione contabile - subappalto nel settore edile'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.4',
'inversione contabile - cessione di fabbricati'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.5',
'inversione contabile - cessione di telefoni cellulari'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.6',
'inversione contabile - cessione di prodotti elettronici'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.7',
'inversione contabile - prestazioni comparto edile e settori connessi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.7'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.8',
'inversione contabile - operazioni settore energetico'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.8'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.9',
'inversione contabile - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.9'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);





insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD20',
'Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD20'
and   tipoDOC.descrizione='Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93'
);

 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
	
insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD21',
'Autofattura per splafonamento',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD21'
and   tipoDOC.descrizione='Autofattura per splafonamento'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD22',
'Estrazione benida Deposito IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD22'
and   tipoDOC.descrizione='Estrazione benida Deposito IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD23',
'Estrazione beni da Deposito IVA con versamento dell'' IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD23'
and   tipoDOC.descrizione='Estrazione beni da Deposito IVA con versamento dell'' IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD24',
'Fattura differita di cui all''art.21, comma 4, lett. a)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD24'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, lett. a)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD25',
'Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD25'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD26',
'Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD26'
and   tipoDOC.descrizione='Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD27',
'Fattura per autoconsumo o per cessioni gratuite senza rivalsa',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,15)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD27'
and   tipoDOC.descrizione='Fattura per autoconsumo o per cessioni gratuite senza rivalsa'
);




insert into siac.sirfel_d_modalita_pagamento(ente_proprietario_id, codice, descrizione)
	select ente.ente_proprietario_id, 'MP23', 'PagoPA'
	from siac.siac_t_ente_proprietario ente
	where NOT EXISTS (
		SELECT 1 FROM siac.sirfel_d_modalita_pagamento z WHERE z.codice = 'MP23' AND z.ente_proprietario_id = ente.ente_proprietario_id);
		

INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.az_code, tmp.az_desc, ta.azione_tipo_id, ga.gruppo_azioni_id, tmp.az_url, to_timestamp('01/01/2017','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
from siac_d_azione_tipo ta
join siac_t_ente_proprietario e on (ta.ente_proprietario_id = e.ente_proprietario_id)
join siac_d_gruppo_azioni ga on (ga.ente_proprietario_id = e.ente_proprietario_id)
join (values
	('OP-COM-ricTipoDocumento', 'Ricerca Tipo Documento FEL - Contabilia', 'ATTIVITA_SINGOLA', 'FIN_BASE2', '/../siacbilapp/azioneRichiesta.do'),
	('OP-COM-insTipoDocumento', 'Inserisci Tipo Documento FEL - Contabilia', 'ATTIVITA_SINGOLA', 'FIN_BASE2', '/../siacbilapp/azioneRichiesta.do')
) as tmp (az_code, az_desc, az_tipo, az_gruppo, az_url) on (tmp.az_tipo = ta.azione_tipo_code and tmp.az_gruppo = ga.gruppo_azioni_code)
where not exists (
	select 1
	from siac_t_azione z
	where z.azione_tipo_id = ta.azione_tipo_id
	and z.azione_code = tmp.az_code
);


SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_iva_aliquota', 'codice', 'varchar(4)');

COMMENT ON COLUMN siac.siac_t_iva_aliquota.codice IS 'Codice Natura';

SELECT * FROM  fnc_dba_add_fk_constraint('siac_t_iva_aliquota', 'siac_t_iva_aliquota_sirfel_d_natura', 'codice,ente_proprietario_id', 'sirfel_d_natura', 'codice,ente_proprietario_id');



--NUOVE COLONNE ALLA TABELLA TIPO DOCUMENTO FEL: SIRFEL_D_TIPO_DOCUMENTO
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_e_id', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_s_id', 'integer');

COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_e_id IS 'Tipo Documento CONTABILIA entrata';
COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_s_id IS 'Tipo Documento CONTABILIA spesa';

SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_e_sirfel_d_tipo_documento', 'doc_tipo_e_id', 'siac_d_doc_tipo', 'doc_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_s_sirfel_d_tipo_documento', 'doc_tipo_s_id', 'siac_d_doc_tipo', 'doc_tipo_id');




update siac_t_iva_aliquota   ia
set codice =  (select codice from sirfel_d_natura where codice =  'N2.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc = 'ART. 74 C.1 LETT. C DPR 633/72 (LIBRI)';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N3.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc ='ART. 72 C.3 N.3 D.P.R. 633/72 TRATTATI INTERNAZ.';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N4' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc in ('4% - Esente', '10% - Esente', '22% - Esente');

update siac_t_iva_aliquota  ia
set codice = (select codice from sirfel_d_natura where codice =  'N6.9' and ia.ente_proprietario_id =ente_proprietario_id) 
where ivaaliquota_desc in ('4% - ART.17-TER SCISSIONE PAGAMENTI','10% - ART.17-TER SCISSIONE PAGAMENTI',
'22% - ART.17-TER SCISSIONE PAGAMENTI');



update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FTV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD01') and ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id)),
	doc_tipo_s_id = (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCD' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD04') and ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FAT' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  (
'TD01',
'TD02',
'TD22',
'TD23',
'TD24',
'TD25',
'TD26'
)
and  ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD03')
and  ente_proprietario_id in (2,15);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NTE' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD05')
and  ente_proprietario_id in (2,15);

update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD06')
and  ente_proprietario_id in (2,15);