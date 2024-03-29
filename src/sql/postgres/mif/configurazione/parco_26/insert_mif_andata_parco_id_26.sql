/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 19.02.2016 Sofia
-- PARCO id=26
select * from siac_t_ente_oil
where ente_proprietario_id=26
INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '000000','00000','0001','000000' ,'0000000',FALSE,FALSE,
  'Unicredit Banca', 'Monica Leschiera' , 'Bruno Aimone Gigio Monica Leschiera',
  26,'2016-01-01','admin');


select * From mif_d_flusso_elaborato_tipo
where ente_proprietario_id=26
-- mif_d_flusso_elaborato_tipo
select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=26
-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',26);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',26);


-- 80
-- 81


select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=26
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set flusso_elab_mif_default='94506780017'
where flusso_elab_mif_tipo_id=80
and   flusso_elab_mif_code='codice_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Ente di Gestione Aree Protette delle Alpi Cozie'
where flusso_elab_mif_tipo_id=80
and   flusso_elab_mif_code='descrizione_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Salbertrand'
where flusso_elab_mif_tipo_id=80
and   flusso_elab_mif_code='ente_localita';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Via Fransuà Fontan 1'
where flusso_elab_mif_tipo_id=80
and   flusso_elab_mif_code='ente_indirizzo';

-- da prod parco id=28

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
            ||  26||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  80
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=28
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
--and   tipo.flusso_elab_mif_tipo_code='REVMIF'
order by d.flusso_elab_mif_ordine;



select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.ente_proprietario_id=26
order by d.flusso_elab_mif_ordine


update mif_d_flusso_elaborato
set flusso_elab_mif_default='94506780017'
where flusso_elab_mif_tipo_id=81
and   flusso_elab_mif_code='codice_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Ente di Gestione Aree Protette delle Alpi Cozie'
where flusso_elab_mif_tipo_id=81
and   flusso_elab_mif_code='descrizione_ente';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Salbertrand'
where flusso_elab_mif_tipo_id=81
and   flusso_elab_mif_code='ente_localita';

update mif_d_flusso_elaborato
set flusso_elab_mif_default='Via Fransuà Fontan 1'
where flusso_elab_mif_tipo_id=81
and   flusso_elab_mif_code='ente_indirizzo';


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
            ||  26||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  81
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=28
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
--and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
order by d.flusso_elab_mif_ordine;









-- non caricato perchè il parco stampa
/*

-- siac_d_accredito_tipo_oil
select * from siac_d_accredito_tipo_oil
where ente_proprietario_id=&ente


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
VALUES (  '71',  'PAGAMENTO PER CASSA INTERNO',  null,  '2016-01-01',  &ente,  'admin');





-- siac_r_accredito_tipo_oil

select * from siac_r_accredito_tipo_oil r
where r.accredito_tipo_oil_rel_id=31

select  r.accredito_tipo_oil_rel_id, oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc,
        tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo, siac_d_accredito_tipo_oil oil
where r.ente_proprietario_id=&ente
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   oil.accredito_tipo_oil_id=r.accredito_tipo_oil_id
order by 2,3

-- 51 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('CT','EP','MP')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='51'
);



-- 52 - A MEZZO BOLLETTINO CCP
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('CP')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='52'
);

-- 53 - BONIFICO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('CB','BP','BD','CD')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='53'
);


-- 55 - ASSEGNO CIRCOLARE
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('AS','CI')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='55'
);

-- 57 - ASSEGNO TRAENZA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('AB')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='57'
);

-- 61 - GIROFONDI BANCA D''ITALIA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('GF')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='61'
);

-- 65 - PAGAMENTO PER CASSA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2015-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('DB')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='65'
);

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('CB')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='69'
);

-- 69 - BONIFINO ESTERO AREA SEPA
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('BP','BD','CD')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='69'
);

-- 71 - PAGAMENTO PER CASSA INTERNO
INSERT INTO siac_r_accredito_tipo_oil( accredito_tipo_id, accredito_tipo_oil_id,  validita_inizio, ente_proprietario_id,  login_operazione)
( select accr.accredito_tipo_id,oil.accredito_tipo_oil_id,'2016-01-01',&ente,'admin'
  from siac_d_accredito_tipo accr , siac_d_accredito_tipo_oil oil
  where accr.ente_proprietario_id=&ente
  and   accr.accredito_tipo_code in ('PC')
  and   oil.ente_proprietario_id=&ente
  and   oil.accredito_tipo_oil_code='71'
);
*/






select tipo.accredito_tipo_code, tipo.accredito_tipo_desc,
       gruppo.accredito_gruppo_id,gruppo.accredito_gruppo_code,tipo.login_operazione,tipo.data_creazione
from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=26
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
order by tipo.login_operazione,tipo.accredito_tipo_code

select * from siac_t_modpag mdp , siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=26
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('BP','CD','CB')

--- BP GE
--- CD CB -- CB

select * from siac_t_modpag mdp , siac_d_accredito_tipo tipo
where mdp.ente_proprietario_id=26
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code in ('CT')


update siac_d_accredito_tipo tipo
set accredito_gruppo_id=g.accredito_gruppo_id
from siac_d_accredito_gruppo g
where g.ente_proprietario_id=26
and   g.accredito_gruppo_code='GE'
and   tipo.accredito_tipo_code='BP'
and   tipo.ente_proprietario_id=g.ente_proprietario_id

