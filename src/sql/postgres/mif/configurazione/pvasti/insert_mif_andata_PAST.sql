/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 29.01.2016 Sofia
-- P.ASTI id=32

-- TAG MIF
-- Test_AID
-- Test_ABI
-- Test_IdTLQWeb
-- codice_ente_BT

-- gestione firme

-- codice_ente  ( codice fiscale )
-- descrizione_ente ( denominazione ente )
-- ente_localita (comune)
-- ente_indirizzo (via)

select * from siac_t_ente_oil
where ente_proprietario_id=32

INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '000000','02008','0001','000000' ,'0000000',FALSE,FALSE,
  'UNICREDIT', null , null,
  32,'2016-01-01','admin');



-- mif_d_flusso_elaborato_tipo
select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=32
-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',32);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',32);



-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=32


INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '51',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '52',  'A MEZZO BOLLETTINO CCP',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '53',  'BONIFICO',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '55',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '57',  'ASSEGNO DI TRAENZA',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '61',  'GIROFONDI BANCA D''ITALIA',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '65',  'PAGAMENTO PER CASSA',  null,  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '69',  'BONIFICO ESTERO AREA SEPA',  'SEPA',  '2016-01-01',  32,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '71',  'PAGAMENTO PER CASSA INTERNA',  null,  '2016-01-01',  32,  'admin');



-- siac_r_accredito_tipo_oil

delete from siac_r_accredito_tipo_oil  where ente_proprietario_id=32
select * from siac_r_accredito_tipo_oil r
where r.accredito_tipo_oil_rel_id=32

select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=32
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('CON','CB1','CP','CT','CT','CT1','F24EP','GF','RPP','TE','VP','XX','DB')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='51'
);


-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('CCP')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='52'
);

-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='53'
);


-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('AC')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('CBI')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='61'
);

-- 65 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='65'
);

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='69'
);


-- 71 - PAGAMENTO PER CASSA INTERNA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=32
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=32
  and   oil.accredito_tipo_oil_code='71'
);


