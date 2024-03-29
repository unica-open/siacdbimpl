/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿rollback;
begin;

/*insert into siac_t_class
(
  classif_code,
  classif_desc,
  classif_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
 'a',
 'Personale',
 tipo.classif_tipo_id,
 clock_timestamp(),
 'admin-pdce-carica-SIAC-6661',
 tipo.ente_proprietario_id
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
     siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero = 'B.13'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code not like '%GSA'
and   r.classif_id=c.classif_id
and   tree.classif_fam_tree_id=r.classif_fam_tree_id
and   fam.classif_fam_id=tree.classif_fam_id
and   r.data_cancellazione is null
and   r.validita_fine is null;



insert into siac_r_class_fam_tree
(
  classif_fam_tree_id,
  classif_id,
  classif_id_padre,
  ordine,
  livello,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tree.classif_fam_tree_id,
       cnew.classif_id,
       c.classif_id,
       r.ordine||'.'||cnew.classif_code,
       r.livello+1,
       clock_timestamp(),
       'admin-pdce-carica-SIAC-6661',
       tipo.ente_proprietario_id
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
     siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam,
     siac_t_class cnew
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero = 'B.13'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code not like '%GSA'
and   r.classif_id=c.classif_id
and   tree.classif_fam_tree_id=r.classif_fam_tree_id
and   fam.classif_fam_id=tree.classif_fam_id
and   cnew.ente_proprietario_id=2
and   cnew.login_operazione ='admin-pdce-carica-SIAC-6661'
and   r.data_cancellazione is null
and   r.validita_fine is null;*/

begin;
select
fnc_siac_bko_caricamento_pdce_conto
( 2019,
  2,
  'AMBITO_FIN',
  'SIAC-6661',
  now()::timestamp
)

NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 75646244
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 482719
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.

select *
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
--and   conto.login_operazione like '%SIAC-6661%' -- 73
and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%' -- 50


select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
-- 50
select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='A'
-- 23

select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
and   not exists
(
select 1
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%'
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.data_cancellazione is null
and  conto.validita_fine is null
)

select  *
from siac_r_pdce_conto_class r
where r.ente_proprietario_id=2
and   r.login_operazione like '%SIAC-6661%'
and  r.data_cancellazione is null
-- 69

select bko.*
from siac_t_pdce_conto conto,siac_bko_t_caricamento_pdce_conto bko
where conto.ente_proprietario_id=2
and   conto.login_operazione like '%SIAC-6661%'
and   not exists
(
select 1 from siac_r_pdce_conto_class r
where r.pdce_conto_id=conto.pdce_conto_id
and   r.login_operazione like '%SIAC-6661%'
and   r.data_cancellazione is null
)
and   bko.pdce_conto_code=conto.pdce_conto_code
and   coalesce(bko.codifica_bil,'')!=''


select bko.*
from siac_t_pdce_conto conto,siac_bko_t_caricamento_pdce_conto bko,siac_r_pdce_conto_attr rattr,siac_t_attr attr
where conto.ente_proprietario_id=2
and   conto.login_operazione like '%SIAC-6661%'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   bko.conto_foglia='S'
and   rattr.pdce_conto_id=conto.pdce_conto_id
and   attr.attr_id=rattr.attr_id
and   attr.attr_code='pdce_conto_foglia'
and   rattr.boolean='S'
and   rattr.login_operazione like '%SIAC-6661%'
and   conto.pdce_conto_code='1.4.2.01.01.002'
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
-- 38


select ambito.ambito_code,contoPadre.pdce_conto_id, contoPadre.pdce_conto_code, bko.*
from siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto contoPadre,
     siac_d_ambito ambito,siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
     siac_d_pdce_conto_tipo tipo
where bko.tipo_operazione='I'
and   not exists
(
select 1
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%'
and   conto.pdce_conto_code=bko.pdce_conto_code
)
and   ambito.ente_proprietario_id=2
and   ambito.ambito_code=bko.ambito
and   contoPadre.ente_proprietario_id=ambito.ente_proprietario_id
and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
and   contoPadre.livello=bko.livello-1
and   contoPadre.ambito_id=ambito.ambito_id
and   contoPadre.pdce_conto_code =
      SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
and   tipo.pdce_ct_tipo_code=bko.tipo_conto
and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
and   contoPadre.data_cancellazione is null
and   contopadre.validita_fine is null
and   fam.ambito_id=ambito.ambito_id
and   fam.pdce_fam_code=bko.classe_conto
and   tree.pdce_fam_id=fam.pdce_fam_id1@%' -- 50


select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
-- 50
select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='A'
-- 23

select *
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
and   not exists
(
select 1
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%'
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.data_cancellazione is null
and  conto.validita_fine is null
)

select  *
from siac_r_pdce_conto_class r
where r.ente_proprietario_id=2
and   r.login_operazione like '%SIAC-6661%'
and  r.data_cancellazione is null
-- 69

select bko.*
from siac_t_pdce_conto conto,siac_bko_t_caricamento_pdce_conto bko
where conto.ente_proprietario_id=2
and   conto.login_operazione like '%SIAC-6661%'
and   not exists
(
select 1 from siac_r_pdce_conto_class r
where r.pdce_conto_id=conto.pdce_conto_id
and   r.login_operazione like '%SIAC-6661%'
and   r.data_cancellazione is null
)
and   bko.pdce_conto_code=conto.pdce_conto_code
and   coalesce(bko.codifica_bil,'')!=''


select bko.*
from siac_t_pdce_conto conto,siac_bko_t_caricamento_pdce_conto bko,siac_r_pdce_conto_attr rattr,siac_t_attr attr
where conto.ente_proprietario_id=2
and   conto.login_operazione like '%SIAC-6661%'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   bko.conto_foglia='S'
and   rattr.pdce_conto_id=conto.pdce_conto_id
and   attr.attr_id=rattr.attr_id
and   attr.attr_code='pdce_conto_foglia'
and   rattr.boolean='S'
and   rattr.login_operazione like '%SIAC-6661%'
and   conto.pdce_conto_code='1.4.2.01.01.002'
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
-- 38


select ambito.ambito_code,contoPadre.pdce_conto_id, contoPadre.pdce_conto_code, bko.*
from siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto contoPadre,
     siac_d_ambito ambito,siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
     siac_d_pdce_conto_tipo tipo
where bko.tipo_operazione='I'
and   not exists
(
select 1
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%'
and   conto.pdce_conto_code=bko.pdce_conto_code
)
and   ambito.ente_proprietario_id=2
and   ambito.ambito_code=bko.ambito
and   contoPadre.ente_proprietario_id=ambito.ente_proprietario_id
and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
and   contoPadre.livello=bko.livello-1
and   contoPadre.ambito_id=ambito.ambito_id
and   contoPadre.pdce_conto_code =
      SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
and   tipo.pdce_ct_tipo_code=bko.tipo_conto
and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
and   contoPadre.data_cancellazione is null
and   contopadre.validita_fine is null
and   fam.ambito_id=ambito.ambito_id
and   fam.pdce_fam_code=bko.classe_conto
and   tree.pdce_fam_id=fam.pdce_fam_id