/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 25.02.2016 Sofia
-- C. ALESSANDRIA id=29


select * from siac_t_ente_proprietario
where ente_proprietario_id=29;

update siac_t_ente_proprietario
set codice_fiscale='00429440068'
where ente_proprietario_id=29


select * from siac_t_ente_oil
where ente_proprietario_id=29

INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '000000','05584','0001','000000' ,'0600300',FALSE,FALSE,
  null, null , null,
  29,'2016-01-01','admin');


-- mif_d_flusso_elaborato_tipo
select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=29
-- 84
-- 85

-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,
  flusso_elab_mif_tipo_dec,
  validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF',true,'2016-01-01','admin',29);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file,
  flusso_elab_mif_tipo_dec,
  validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF',true,'2016-01-01','admin',29);


-- Da richiedere decodifiche tipo pagamento specifiche del tesoriere
-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=29
-- 9 per timo

/*
INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  &ente,  'admin');


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  &ente,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '71',  'PAGAMENTO PER CASSA INTERNO',  null,  '2016-01-01',  &ente,  'admin'); */

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '01',  'CASSA',  null,  '2016-01-01',  29,  'admin');

-- non attribuito
INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '02',  'REGOLARIZZAZIONE',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '03',  'BONIFICO BANCARIO E POSTALE',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '04',  'SEPA CREDIT TRANSFER',  'SEPA',  '2016-01-01',  29,  'admin');

-- assegno di traenza
INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '05',  'ASSEGNO BANCARIO E POSTALE',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '06',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '07',  'ACCREDITO CONTO CORRENTE POSTALE',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '08',  'F24EP',  null,  '2016-01-01',  29,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '09',  'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',  null,  '2016-01-01',  29,  'admin');




-- siac_r_accredito_tipo_oil

select * from siac_r_accredito_tipo_oil r
where r.accredito_tipo_oil_rel_id=29

select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=29
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3
-- 12 per timo
-- 13 per alessandria


-- 01 - CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('CON','GEN','LICOM','LIQUI','PAPRE','RIDBA')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='01'
);

--- 6

-- 07 - ACCREDITO CONTO CORRENTE POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('POSTA')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='07'
);

-- 1

-- 03 - BONIFICO BANCARIO E POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('BOCAS','BONIF')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='03'
);

-- 2

-- 06 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('CITRA')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='06'
);
--1
-- 05 - ASSEGNO BANCARIO E POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='05'
);

-- 09 - ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('GIRO','GIROF')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='09'
);
--2

-- 04 - SEPA CREDIT TRANSFER
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=29
  and   accr.accredito_tipo_code in ('BONIF')
  and   oil.ente_proprietario_id=29
  and   oil.accredito_tipo_oil_code='04'
);

-- 1

--- generazione script per configurazione
--- da parco id=14


-- MANDMIF

select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2016-01-01')||','
            ||  29||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  84
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=14
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
order by d.flusso_elab_mif_ordine;

select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=29
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set flusso_elab_mif_default='00429440068'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='codice_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Comune di Alessandria'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='descrizione_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Alessandria'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='ente_localita';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Piazza della Liberta'', 1'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='ente_indirizzo';


update mif_d_flusso_elaborato
set flusso_elab_mif_param='IT|BONIF|CON|SEPA'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='tipo_pagamento';


select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=29
and   d.flusso_elab_mif_code in ('codice_fiscale_beneficiario','codice_fiscale_delegato','codice_fiscale_ben_quiet')
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set flusso_elab_mif_default='00429440068'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code in ('codice_fiscale_beneficiario','codice_fiscale_delegato','codice_fiscale_ben_quiet');


select * From siac_d_codicebollo
where ente_proprietario_id=29
-- 00
-- 77
-- 99

update mif_d_flusso_elaborato
set flusso_elab_mif_param='5|99|ESENTE BOLLO|AI|ESENTE BOLLO|00|ESENTE BOLLO|77|ESENTE BOLLO|SB|ASSOGGETTATO BOLLO A CARICO BENEFICIARIO'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='assoggettamento_bollo';


------- REVMIF


select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2016-01-01')||','
            ||  29||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  85
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=14
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
order by d.flusso_elab_mif_ordine;



select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=29
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set flusso_elab_mif_default='00429440068'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='codice_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Comune di Alessandria'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='descrizione_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Alessandria'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='ente_localita';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Piazza della Liberta'', 1'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='ente_indirizzo';

select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=29
and   d.flusso_elab_mif_code in ('codice_fiscale_versante')
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set flusso_elab_mif_default='00429440068'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code in ('codice_fiscale_versante');


-- mancanti

update mif_d_flusso_elaborato
set flusso_elab_mif_default='05584'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='codice_ABI_BT';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='0600300'
where flusso_elab_mif_tipo_id=84
and   flusso_elab_mif_code='codice_ente_BT';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='05584'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='codice_ABI_BT';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='0600300'
where flusso_elab_mif_tipo_id=85
and   flusso_elab_mif_code='codice_ente_BT';
