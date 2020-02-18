/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 11.02.2016 Sofia
-- PV.VERCELLI id=31

--- tutto ancora da fare
select * from siac_t_ente_oil
where ente_proprietario_id=31


INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '917702','02008','0001','917702' ,'844500',FALSE,FALSE,
  '', null , null,
  31,'2016-01-01','admin');

select * From siac_t_ente_proprietario
where ente_proprietario_id=31

update siac_t_ente_proprietario
set codice_fiscale='80005210028'
where ente_proprietario_id=31

-- mif_d_flusso_elaborato_tipo
select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=31

-- 78
-- 79

-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',31);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',31);

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=31
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
--and   t.flusso_elab_mif_tipo_code='MANDMIF')
and   t.flusso_elab_mif_tipo_code='REVMIF')
order by d.flusso_elab_mif_ordine

-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=31


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  31,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '71',  'PAGAMENTO PER CASSA INTERNA',  null,  '2016-01-01',  31,  'admin');


select tipo.accredito_tipo_code, m.*
from siac_t_modpag m, siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CB','CB1','CBC','CBE')


select tipo.accredito_tipo_code, m.*
from siac_t_modpag m, siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   m.iban is not null

-- update 'CB1','CBC','CBE'

update siac_d_accredito_tipo tipo set accredito_gruppo_id=gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=31
and   gruppo.accredito_gruppo_code='GE'
and   tipo.accredito_tipo_code in ('CB1','CBC','CBE')
and   tipo.ente_proprietario_id=31


--- update modpag

update siac_t_modpag m set note=contocorrente, contocorrente=null
from siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   tipo.accredito_tipo_code='CB'
and   m.iban is not null
and   lentgh(m.iban)>2
and   m.contocorrente is not null;


select tipo.accredito_tipo_code, m.*
from siac_t_modpag m, siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   tipo.accredito_tipo_code='CP'


update siac_d_accredito_tipo tipo set accredito_gruppo_id=gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=31
and   gruppo.accredito_gruppo_code='GE'
and   tipo.accredito_tipo_code in ('CP')
and   tipo.ente_proprietario_id=31


select tipo.accredito_tipo_code, m.*
from siac_t_modpag m, siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   tipo.accredito_tipo_code='GF'


update siac_d_accredito_tipo tipo set accredito_gruppo_id=gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=31
and   gruppo.accredito_gruppo_code='GE'
and   tipo.accredito_tipo_code in ('GF')
and   tipo.ente_proprietario_id=31


select tipo.accredito_tipo_code, m.*
from siac_t_modpag m, siac_d_accredito_tipo tipo
where m.ente_proprietario_id=31
and   tipo.accredito_tipo_id=m.accredito_tipo_id
and   tipo.accredito_tipo_code='CT'



update siac_d_accredito_tipo tipo set accredito_gruppo_id=gruppo.accredito_gruppo_id
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=31
and   gruppo.accredito_gruppo_code='GE'
and   tipo.accredito_tipo_code in ('CT')
and   tipo.ente_proprietario_id=31

-- siac_r_accredito_tipo_oil


select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=31
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('CB1','CBC','CBE','CP','GF','CT','CE','EP','LD','TE','VP','XX')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='51'
);


-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('CCP')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='52'
);

-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='53'
);


-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('CBI')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='61'
);

-- 65 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=31
  and   oil.accredito_tipo_oil_code='65'
);

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=accr.ente_proprietario_id
  and   oil.accredito_tipo_oil_code='69'
);


-- 71 - PAGAMENTO PER CASSA INTERNA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=31
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=31
  and   oil.accredito_tipo_oil_code='71'
);


