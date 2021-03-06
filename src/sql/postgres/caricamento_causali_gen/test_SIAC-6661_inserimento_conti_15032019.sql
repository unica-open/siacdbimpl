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
and   tree.pdce_fam_id=fam.pdce_fam_id1 @ % '   - -   5 0 
 
 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o 
 
 w h e r e   b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
 - -   5 0 
 
 s e l e c t   * 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o 
 
 w h e r e   b k o . t i p o _ o p e r a z i o n e = ' A ' 
 
 - -   2 3 
 
 
 
 s e l e c t   * 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o 
 
 w h e r e   b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
 w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' a d m i n - c a r i c a - p d c e - S I A C - 6 6 6 1 @ % ' 
 
 a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d     c o n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
 ) 
 
 
 
 s e l e c t     * 
 
 f r o m   s i a c _ r _ p d c e _ c o n t o _ c l a s s   r 
 
 w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
 a n d     r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -   6 9 
 
 
 
 s e l e c t   b k o . * 
 
 f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o 
 
 w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1   f r o m   s i a c _ r _ p d c e _ c o n t o _ c l a s s   r 
 
 w h e r e   r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 ) 
 
 a n d       b k o . p d c e _ c o n t o _ c o d e = c o n t o . p d c e _ c o n t o _ c o d e 
 
 a n d       c o a l e s c e ( b k o . c o d i f i c a _ b i l , ' ' ) ! = ' ' 
 
 
 
 
 
 s e l e c t   b k o . * 
 
 f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ r _ p d c e _ c o n t o _ a t t r   r a t t r , s i a c _ t _ a t t r   a t t r 
 
 w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
 a n d       b k o . p d c e _ c o n t o _ c o d e = c o n t o . p d c e _ c o n t o _ c o d e 
 
 a n d       b k o . c o n t o _ f o g l i a = ' S ' 
 
 a n d       r a t t r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 a n d       a t t r . a t t r _ i d = r a t t r . a t t r _ i d 
 
 a n d       a t t r . a t t r _ c o d e = ' p d c e _ c o n t o _ f o g l i a ' 
 
 a n d       r a t t r . b o o l e a n = ' S ' 
 
 a n d       r a t t r . l o g i n _ o p e r a z i o n e   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
 a n d       c o n t o . p d c e _ c o n t o _ c o d e = ' 1 . 4 . 2 . 0 1 . 0 1 . 0 0 2 ' 
 
 a n d       r a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
 - -   3 8 
 
 
 
 
 
 s e l e c t   a m b i t o . a m b i t o _ c o d e , c o n t o P a d r e . p d c e _ c o n t o _ i d ,   c o n t o P a d r e . p d c e _ c o n t o _ c o d e ,   b k o . * 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o P a d r e , 
 
           s i a c _ d _ a m b i t o   a m b i t o , s i a c _ t _ p d c e _ f a m _ t r e e   t r e e , s i a c _ d _ p d c e _ f a m   f a m , 
 
           s i a c _ d _ p d c e _ c o n t o _ t i p o   t i p o 
 
 w h e r e   b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
 w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' a d m i n - c a r i c a - p d c e - S I A C - 6 6 6 1 @ % ' 
 
 a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 ) 
 
 a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
 a n d       c o n t o P a d r e . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       c o n t o P a d r e . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
 a n d       c o n t o P a d r e . l i v e l l o = b k o . l i v e l l o - 1 
 
 a n d       c o n t o P a d r e . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
 a n d       c o n t o P a d r e . p d c e _ c o n t o _ c o d e   = 
 
             S U B S T R I N G ( b k o . p d c e _ c o n t o _ c o d e   f r o m   1   f o r   l e n g t h ( b k o . p d c e _ c o n t o _ c o d e ) -   p o s i t i o n ( ' . '   i n   r e v e r s e ( b k o . p d c e _ c o n t o _ c o d e ) ) ) 
 
 a n d       t i p o . p d c e _ c t _ t i p o _ c o d e = b k o . t i p o _ c o n t o 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       c o n t o P a d r e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       c o n t o p a d r e . v a l i d i t a _ f i n e   i s   n u l l 
 
 a n d       f a m . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
 a n d       f a m . p d c e _ f a m _ c o d e = b k o . c l a s s e _ c o n t o 
 
 a n d       t r e e . p d c e _ f a m _ i d = f a m . p d c e _ f a m _ i d 