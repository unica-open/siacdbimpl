/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 11.11.2016 Sofia
-- 20.12.2016 Sofia - TU
-- REGP id=2
-- tutto da verificare
-- siac_d_accredito_tipo_oil
-- siac_r_accredito_tipo_oil
-- siac_d_accredito_tipo
-- 03.02.2017 Sofia migrazione prod
INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '727080','02008','0001','727080' ,'6220100',TRUE,TRUE,
  'UNICREDIT BANCA SPA - V. GARIBALDI 2 TO', null , null,
  2,'2016-01-01','admin');


select * from siac_t_ente_oil
where ente_proprietario_id=2

-- mif_d_flusso_elaborato_tipo
-- flussi andata
select *
from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=2

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',2);

-- 143
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',2);
-- 144

--- Tutti da verificare
-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=2


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  2,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  2,  'admin');



select substring(gruppo.accredito_gruppo_code,1,length(gruppo.accredito_gruppo_code)),
       substring(tipo.accredito_tipo_code,1,length(tipo.accredito_tipo_code)), tipo.accredito_tipo_desc,
       tipo.login_operazione
from siac_d_accredito_tipo  tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   tipo.login_operazione like 'migr%'
order by 1,2


select substring(gruppo.accredito_gruppo_code,1,length(gruppo.accredito_gruppo_code)),
       substring(tipo.accredito_tipo_code,1,length(tipo.accredito_tipo_code)), tipo.accredito_tipo_desc,
       tipo.login_operazione
from siac_d_accredito_tipo  tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   not exists ( select 1 from siac_r_accredito_tipo_oil r
                   where r.ente_proprietario_id=2
                   and   r.accredito_tipo_id=tipo.accredito_tipo_id )
order by 1,2

-- siac_r_accredito_tipo_oil

select * from siac_r_accredito_tipo_oil
where ente_proprietario_id=2;

select  oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, gruppo.accredito_gruppo_code,tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil, siac_d_accredito_gruppo gruppo
where r.ente_proprietario_id=2
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by 1,2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('CT','F2','F3','FI','RI')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='51'
);

select count(*)
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CT')
and   mdp.quietanziante is null -- 6
-- 6

select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       stato.modpag_stato_code,
       mdp.quietanziante ,mdp.quietanziante_codice_fiscale
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_r_modpag_stato r, siac_d_modpag_stato stato
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CT')
and   mdp.quietanziante is null
and   sog.soggetto_id=mdp.soggetto_id
and   r.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=r.modpag_stato_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by sog.soggetto_code::integer

-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('CP')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='52'
);

select mdp.*
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CP')
and   mdp.contocorrente is  null -- 0
-- 0


-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('CB','BP')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='53'
);

-- segnalare
select count(*)
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CB','BP')
and   mdp.iban is null -- 1161
-- 38525


select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       stato.modpag_stato_code,
	   mdp.contocorrente, mdp.bic, mdp.banca_denominazione, mdp.iban
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_r_modpag_stato r, siac_d_modpag_stato stato
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CB','BP')
and   mdp.iban is null -- 1161
and   sog.soggetto_id=mdp.soggetto_id
and   r.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=r.modpag_stato_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by sog.soggetto_code::integer

-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('AC')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('AB')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',2,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('GF')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='61'
);

select count(*)
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('GF')
and   mdp.contocorrente is null --6
-- 2146

select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       stato.modpag_stato_code,
	   mdp.contocorrente,mdp.contocorrente_intestazione
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_r_modpag_stato r, siac_d_modpag_stato stato
where mdp.ente_proprietario_id=2
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('GF')
and   mdp.contocorrente is null
and   sog.soggetto_id=mdp.soggetto_id
and   r.modpag_id=mdp.modpag_id
and   stato.modpag_stato_id=r.modpag_stato_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by sog.soggetto_code::integer


-- 65 - PAGAMENTO PER CASSA
/*INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('GC')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='65'
);*/

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=2
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=2
  and   oil.accredito_tipo_oil_code='69'
);


