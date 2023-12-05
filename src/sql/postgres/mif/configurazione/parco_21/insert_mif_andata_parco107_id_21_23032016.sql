/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 23.03.2016 Sofia
-- PARCO id=21 p107
select * from siac_t_ente_oil
where ente_proprietario_id=21

INSERT INTO siac_t_ente_oil(ente_oil_aid, ente_oil_abi,  ente_oil_progressivo, ente_oil_idtlqweb, ente_oil_codice,
							ente_oil_firma_manleva, ente_oil_firme_ord,
                            ente_oil_tes_desc,
                            ente_oil_resp_amm,
                            ente_oil_resp_ord,
                            ente_proprietario_id,  validita_inizio, login_operazione)
VALUES
( '000000','00000','0001','000000' ,'0000000',FALSE,FALSE,
  'B.R.E. Banca S.p.A.', 'Luciana Baretto' , 'Canavese Geom.Giuseppe Luciana Baretto',
  21,'2016-01-01','admin');

-- mif_d_flusso_elaborato_tipo
select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=21

--- 86
--- 87

-- flussi andata
insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  , flusso_elab_mif_nome_file,validita_inizio,login_operazione,ente_proprietario_id)
values
('MANDMIF','Flusso XML Mandati (ordinativi spesa)','MANDMIF','2016-01-01','admin',21);


insert into mif_d_flusso_elaborato_tipo
( flusso_elab_mif_tipo_code, flusso_elab_mif_tipo_desc  ,flusso_elab_mif_nome_file, validita_inizio,login_operazione,ente_proprietario_id)
values
('REVMIF','Flusso XML Reversali (ordinativi entrata)','REVMIF','2016-01-01','admin',21);
-- 88
-- 89

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
            ||  21||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  tipo_a.flusso_elab_mif_tipo_id
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato_tipo tipo_a
where d.ente_proprietario_id=18
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   tipo_a.ente_proprietario_id=21
and   tipo_a.flusso_elab_mif_tipo_code='MANDMIF';


select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by d.flusso_elab_mif_ordine

select * from siac_t_ente_proprietario
where ente_proprietario_id=21


select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code in ('codice_ente','descrizione_ente','ente_localita','ente_indirizzo')
order by d.flusso_elab_mif_ordine

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='96009220045'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='codice_ente'

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Ente di Gestione delle Aree Protette delle Alpi Marittime'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='descrizione_ente'

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Valdieri'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='ente_localita'

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Piazza Regina Elena 30'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='ente_indirizzo'


-- REVMIF
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
            ||  21||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  tipo_a.flusso_elab_mif_tipo_id
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato_tipo tipo_a
where d.ente_proprietario_id=18
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   tipo_a.ente_proprietario_id=21
and   tipo_a.flusso_elab_mif_tipo_code='REVMIF';


select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by d.flusso_elab_mif_ordine




select d.*
from mif_d_flusso_elaborato d, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code in ('codice_ente','descrizione_ente','ente_localita','ente_indirizzo')
order by d.flusso_elab_mif_ordine

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='96009220045'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='codice_ente';

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Ente di Gestione delle Aree Protette delle Alpi Marittime'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='descrizione_ente';

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Valdieri'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='ente_localita';

update 	mif_d_flusso_elaborato d
set flusso_elab_mif_default='Piazza Regina Elena 30'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=21
and   tipo.flusso_elab_mif_tipo_code='REVMIF'
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_code='ente_indirizzo';