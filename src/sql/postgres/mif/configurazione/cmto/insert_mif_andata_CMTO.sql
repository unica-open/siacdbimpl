/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 20.12.2016 Sofia
-- CMTO id=3
-- tutto da verificare
-- siac_d_accredito_tipo_oil
-- siac_r_accredito_tipo_oil
-- siac_d_accredito_tipo
-- 02.02.2017 Sofia PROD

INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '751335','02008','0001','751335' ,'540300',TRUE,TRUE,
  'UNICREDIT BANCA SPA - V. GARIBALDI 2 TO', null , null,
  3,'2016-01-01','admin');

select * from siac_t_ente_oil
where ente_proprietario_id=3
-- mif_d_flusso_elaborato_tipo
-- flussi andata
select *
from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=3

insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',3);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',3);


--- Tutti da verificare
-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=3


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  3,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  3,  'admin');


select substring(gruppo.accredito_gruppo_code,1,length(gruppo.accredito_gruppo_code)),
       substring(tipo.accredito_tipo_code,1,length(tipo.accredito_tipo_code)), tipo.accredito_tipo_desc
from siac_d_accredito_tipo  tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
--and   gruppo.accredito_gruppo_code in ('CO','GE')
--and   gruppo.accredito_gruppo_code in ('CCP')
and   gruppo.accredito_gruppo_code in ('CB')
order by 1,2


select substring(gruppo.accredito_gruppo_code,1,length(gruppo.accredito_gruppo_code)),
       substring(tipo.accredito_tipo_code,1,length(tipo.accredito_tipo_code)), tipo.accredito_tipo_desc
from siac_d_accredito_tipo  tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   not exists ( select 1 from siac_r_accredito_tipo_oil r
                   where r.ente_proprietario_id=3
                   and   r.accredito_tipo_id=tipo.accredito_tipo_id)
order by 1,2


begin;
update siac_d_accredito_tipo tipo
set    accredito_gruppo_id=gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
--and   tipo.accredito_tipo_code in ('3','5','6','8')
and   tipo.accredito_tipo_code in ('5','6','8')
and   gruppo.accredito_gruppo_code='GE'
and   gruppo.ente_proprietario_id=tipo.ente_proprietario_id


-- siac_r_accredito_tipo_oil

select * from siac_r_accredito_tipo_oil
where ente_proprietario_id=3;

begin;
delete from siac_r_accredito_tipo_oil
where ente_proprietario_id=3;

select  oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, gruppo.accredito_gruppo_code,tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil, siac_d_accredito_gruppo gruppo
where r.ente_proprietario_id=3
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by 1,2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
--  and   accr.accredito_tipo_code in ('CON','3','4','6','12','14','99')
  and   accr.accredito_tipo_code in ('3','4','6','12','14','99')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='51'
);

-- segnalare
select tipo.accredito_tipo_code, count(*)
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('3')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.quietanziante is  null -- 3
group by tipo.accredito_tipo_code

select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       mdp.quietanziante, mdp.quietanziante_codice_fiscale
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('3')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.quietanziante is  null -- 3
and   sog.soggetto_id=mdp.soggetto_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by sog.soggetto_code::integer,mdp.modpag_id
-- 130

-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('2')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='52'
);


select tipo.accredito_tipo_code, count(*)
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('2')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.contocorrente is null -- 3
group by tipo.accredito_tipo_code

-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('1','10','7','9')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='53'
);

-- segnalare
select tipo.accredito_tipo_code, mdp.*
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('1')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.iban is  null

select tipo.accredito_tipo_code, mdp.*
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('1','10','7','9')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.iban is null -- 644
-- sono tutti 1 e hanno contocorrente valorizzato, ma 1 usato anche con iban
-- dopo secondo giro non ce ne sono piu


select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       mdp.iban, mdp.contocorrente, mdp.bic, mdp.banca_denominazione
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('1','10','7','9')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.iban is  null
and   sog.soggetto_id=mdp.soggetto_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by sog.soggetto_code::integer,mdp.modpag_id

-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('8')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('5')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',3,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('11')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='61'
);

select tipo.accredito_tipo_code, mdp.*
from siac_t_modpag mdp, siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('11')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
--and   mdp.contocorrente is null
and   mdp.contocorrente_intestazione is null
-- 27 da segnalare


select sog.soggetto_code, sog.soggetto_desc,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       mdp.contocorrente
from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_t_soggetto sog, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=3
and   tipo.accredito_tipo_code in ('11')
and   mdp.accredito_tipo_id=tipo.accredito_tipo_id
and   mdp.contocorrente_intestazione is null
and   sog.soggetto_id=mdp.soggetto_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by sog.soggetto_code::integer,mdp.modpag_id

-- 65 - PAGAMENTO PER CASSA
/*INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('GC')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='65'
);*/

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=3
  and   accr.accredito_tipo_code in ('1')
  and   oil.ente_proprietario_id=3
  and   oil.accredito_tipo_oil_code='69'
);