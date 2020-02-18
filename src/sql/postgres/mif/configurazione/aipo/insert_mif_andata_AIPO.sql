/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 25.01.2016 Sofia
-- AIPO id=4

INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '001278','02008','0001','001278' ,'9032006',FALSE,TRUE,
  'UNICREDIT BANCA SPA', null , null,
  4,'2016-01-01','admin');

-- mif_d_flusso_elaborato_tipo

select * From mif_d_flusso_elaborato_tipo
where ente_proprietario_id=4
-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',4);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',4);



-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=4


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '71',  'PAGAMENTO PER CASSA INTERNA',  null,  '2016-01-01',  4,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '72',  'BOLLET. PRESTAMPATO DALL''ENTE',  null,  '2016-01-01',  4,  'admin');



-- siac_d_accredito_tipo
-- non è migrata la CT - lasciamo CON - CONTANTI
select tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       gruppo.accredito_gruppo_id,gruppo.accredito_gruppo_code,tipo.login_operazione
from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=4
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by tipo.login_operazione,tipo.accredito_tipo_code;

-- siac_r_accredito_tipo_oil


select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=4
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('AI','AV','CT','PC','MF','TE','TT','CE','AP','DP')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='51'
);

INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('CON')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='51'
);

-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('CP')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='52'
);

-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('CB','BP','BD','CD')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='53'
);


-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('AS','AC')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('AB')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('GF','CBI')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='61'
);

-- 65 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('GC')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='65'
);

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='69'
);



-- 71 - PAGAMENTO PER CASSA INTERNA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('CI')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='71'
);

-- 72 - BOLLET. PRESTAMPATO DALL''ENTE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',4,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=4
  and   accr.accredito_tipo_code in ('PP')
  and   oil.ente_proprietario_id=4
  and   oil.accredito_tipo_oil_code='72'
);




