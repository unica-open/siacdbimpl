/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 26.01.2016 Sofia
-- PARCO id=14
INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '000000','00000','0001','000000' ,'617708',FALSE,FALSE,
  'BANCA POPOLARE DI MILANO', null , null,
  14,'2016-01-01','admin');

-- mif_d_flusso_elaborato_tipo
-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,
  flusso_elab_mif_tipo_dec,
  validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF',true,'2016-01-01','admin',14);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file,
  flusso_elab_mif_tipo_dec,
  validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF',true,'2016-01-01','admin',14);


-- Da richiedere decodifiche tipo pagamento specifiche del tesoriere
-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=14

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
VALUES (  '01',  'CASSA',  null,  '2016-01-01',  14,  'admin');

-- non attribuito
INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '02',  'REGOLARIZZAZIONE',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '03',  'BONIFICO BANCARIO E POSTALE',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '04',  'SEPA CREDIT TRANSFER',  'SEPA',  '2016-01-01',  14,  'admin');

-- assegno di traenza
INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '05',  'ASSEGNO BANCARIO E POSTALE',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '06',  'ASSEGNO CIRCOLARE',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '07',  'ACCREDITO CONTO CORRENTE POSTALE',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '08',  'F24EP',  null,  '2016-01-01',  14,  'admin');

INSERT INTO siac_d_accredito_tipo_oil(  accredito_tipo_oil_code,  accredito_tipo_oil_desc,  accredito_tipo_oil_area,  validita_inizio,  ente_proprietario_id,  login_operazione)
VALUES (  '09',  'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A',  null,  '2016-01-01',  14,  'admin');




-- siac_r_accredito_tipo_oil

select * from siac_r_accredito_tipo_oil r
where r.accredito_tipo_oil_rel_id=14

select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=14
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3



-- 01 - CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('AC','CT','DA','DB','F2','F3','F4')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='01'
);



-- 07 - ACCREDITO CONTO CORRENTE POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('CP')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='07'
);

-- 03 - BONIFICO BANCARIO E POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('CB','CD')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='03'
);


-- 06 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='06'
);

-- 05 - ASSEGNO BANCARIO E POSTALE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='05'
);

-- 09 - ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('GF')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='09'
);



-- 04 - SEPA CREDIT TRANSFER
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',oil.ente_proprietario_id,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=14
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=14
  and   oil.accredito_tipo_oil_code='04'
);


