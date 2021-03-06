/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿rollback;
begin;
select
fnc_siac_bko_caricamento_causali
(
  2019,
  2,
  'AMBITO_FIN',
   'SIAC-6661',
  now()::timestamp
);

NOTICE:  numeroCausali=240 (260)
NOTICE:  numeroStatoCausali=240
NOTICE:  numeroPdcFinCausali=240
NOTICE:  numeroContiCausali=474 (517)
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=606 -- ok
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 240 causali.


NOTICE:  numeroCausali=240
NOTICE:  numeroStatoCausali=240
NOTICE:  numeroPdcFinCausali=240
NOTICE:  numeroContiCausali=474
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=606
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 240 causali.


select count(*)
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 523
-- 480

select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 260
-- 240

select distinct bko.codice_causale, bko.pdc_econ_patr
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 517 causale-conti
-- 474 causale-conti
select distinct bko.codice_causale, bko.pdc_econ_patr,bko.segno
from siac_bko_t_caricamento_causali bko
where caricata=false
-- 480


select  *
from siac_bko_t_causale_evento bko
-- 665

select  distinct bko.codice_causale, bko.evento--,bko.eu
from siac_bko_t_causale_evento bko
where  exists
(select 1 from siac_bko_t_caricamento_causali c
where c.caricata=false
and   c.codice_causale=bko.codice_causale)
-- 609

select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where not exists
(select 1 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ep.login_operazione   like '%SIAC-6661%')

select *
from siac_t_causale_ep ep
where ep.ente_proprietario_id=2
and   ep.login_operazione  like '%SIAC-6661%'
-- 240

select *
from siac_r_causale_ep_stato r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_causale_ep_class r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'


select *
from siac_r_causale_ep_pdce_conto r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_causale_ep_pdce_conto_oper r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'

select *
from siac_r_evento_causale r
where r.ente_proprietario_id=2
and   r.login_operazione  like '%SIAC-6661%'



select distinct bko.codice_causale
from siac_bko_t_caricamento_causali bko
where  exists
(select 1 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ep.login_operazione  not like '%SIAC-6661%'
)
-- 20
select distinct ep.causale_ep_code, ambito.ambito_code, ep.login_operazione
from siac_bko_t_caricamento_causali bko, siac_t_causale_ep ep,siac_d_ambito ambito
where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ambito.ambito_id=ep.ambito_id
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null

select bko.*
from siac_bko_t_caricamento_causali bko, siac_t_causale_ep ep,siac_d_ambito ambito
where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale
 and   ambito.ambito_id=ep.ambito_id
 -- 43
 begin;
 update siac_bko_t_caricamento_causali bko
 set    caricata=true
 from siac_t_causale_ep ep
 where ep.ente_proprietario_id=2
 and   ep.causale_ep_code=bko.codice_causale

-----------------------

select *
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale like '%U.2.02.04.07.005%'
-- 35

--queste invece sono sbagliate sul file
-- ORD-U.3.01.0105.001
--ORD-U.3.01.0105.002
--ORD-U.3.01.0105.003

select distinct bko.codice_causale
from  siac_bko_t_caricamento_causali bko
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)


select  bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio,
        bko.*
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale in
(
'ORD-U.3.01.0105.001',
'ORD-U.3.01.0105.002',
'ORD-U.3.01.0105.003'
)
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null


select distinct bko.caricata,ep.causale_ep_code,stato.causale_ep_stato_code,ambito.ambito_code,ep.validita_inizio
from  siac_bko_t_caricamento_causali bko,siac_t_causale_ep ep,siac_r_causale_ep_stato rs,siac_d_causale_ep_stato stato,
     siac_d_ambito ambito
where bko.codice_causale like '%U.2.02.04.07.005%'
and   ep.ente_proprietario_id=2
and   ep.causale_ep_code=bko.codice_causale
and   rs.causale_ep_id=ep.causale_ep_id
and   stato.causale_ep_stato_id=rs.causale_ep_stato_id
and   ambito.ambito_id=ep.ambito_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

rollback;
begin;
update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.001'
where codice_causale='ORD-U.3.01.0105.001'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.002'
where codice_causale='ORD-U.3.01.0105.002'

update siac_bko_t_caricamento_causali bko
set    codice_causale='ORD-U.3.01.01.05.003'
where codice_causale='ORD-U.3.01.0105.003'



-----------------------
select ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code,
       count(*)

from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
     siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=2
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.login_operazione like '%'||'SIAC-6661'||'-'||bko.eu||'%'
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.causale_ep_code=bko.codice_causale
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.evento_tipo_code=bko.tipo_evento
    and   evento.evento_tipo_id=tipo.evento_tipo_id
    and   evento.evento_code=bko.evento
    and   bko.caricata=false
/*    and    exists
    (
    select 1 from siac_r_evento_causale r1
    where r1.causale_ep_id = ep.causale_ep_id
    and   r1.evento_id=evento.evento_id
    and   r1.login_operazione not like '%SIAC-6661%'
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )*/
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    group by ep.causale_ep_id,
       evento.evento_id,
       ep.causale_ep_code,
       evento.evento_code
    having count(*)>1
    order by 1,2


    select  *
    from siac_bko_t_causale_evento bko
    where bko.codice_causale in
    (
    'ROR-I-RP-U.3.01.01.05.003',
    'ROR-I-RP-U.3.01.01.05.002',
    'ROR-I-RP-U.3.01.01.05.001'
    )
    and  bko.evento ='ROR-I-RP-INS'
    -- ROR-I-RP-U.3.01.01.05.003 ROR-I-RP-INS
    -- ROR-I-RP-U.3.01.01.05.002
    -- ROR-I-RP-U.3.01.01.05.001 = b k o . c o d i c e _ c a u s a l e 
 
 
 
 - - - - - - - - - - - - - - - - - - - - - - - 
 
 
 
 s e l e c t   * 
 
 f r o m     s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 w h e r e   b k o . c o d i c e _ c a u s a l e   l i k e   ' % U . 2 . 0 2 . 0 4 . 0 7 . 0 0 5 % ' 
 
 - -   3 5 
 
 
 
 - - q u e s t e   i n v e c e   s o n o   s b a g l i a t e   s u l   f i l e 
 
 - -   O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 1 
 
 - - O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 2 
 
 - - O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 3 
 
 
 
 s e l e c t   d i s t i n c t   b k o . c o d i c e _ c a u s a l e 
 
 f r o m     s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 w h e r e   b k o . c o d i c e _ c a u s a l e   i n 
 
 ( 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 1 ' , 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 2 ' , 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 3 ' 
 
 ) 
 
 
 
 
 
 s e l e c t     b k o . c a r i c a t a , e p . c a u s a l e _ e p _ c o d e , s t a t o . c a u s a l e _ e p _ s t a t o _ c o d e , a m b i t o . a m b i t o _ c o d e , e p . v a l i d i t a _ i n i z i o , 
 
                 b k o . * 
 
 f r o m     s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o , s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ r _ c a u s a l e _ e p _ s t a t o   r s , s i a c _ d _ c a u s a l e _ e p _ s t a t o   s t a t o , 
 
           s i a c _ d _ a m b i t o   a m b i t o 
 
 w h e r e   b k o . c o d i c e _ c a u s a l e   i n 
 
 ( 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 1 ' , 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 2 ' , 
 
 ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 3 ' 
 
 ) 
 
 a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
 a n d       r s . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
 a n d       s t a t o . c a u s a l e _ e p _ s t a t o _ i d = r s . c a u s a l e _ e p _ s t a t o _ i d 
 
 a n d       a m b i t o . a m b i t o _ i d = e p . a m b i t o _ i d 
 
 a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
 
 
 s e l e c t   d i s t i n c t   b k o . c a r i c a t a , e p . c a u s a l e _ e p _ c o d e , s t a t o . c a u s a l e _ e p _ s t a t o _ c o d e , a m b i t o . a m b i t o _ c o d e , e p . v a l i d i t a _ i n i z i o 
 
 f r o m     s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o , s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ r _ c a u s a l e _ e p _ s t a t o   r s , s i a c _ d _ c a u s a l e _ e p _ s t a t o   s t a t o , 
 
           s i a c _ d _ a m b i t o   a m b i t o 
 
 w h e r e   b k o . c o d i c e _ c a u s a l e   l i k e   ' % U . 2 . 0 2 . 0 4 . 0 7 . 0 0 5 % ' 
 
 a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
 a n d       r s . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
 a n d       s t a t o . c a u s a l e _ e p _ s t a t o _ i d = r s . c a u s a l e _ e p _ s t a t o _ i d 
 
 a n d       a m b i t o . a m b i t o _ i d = e p . a m b i t o _ i d 
 
 a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
 
 
 r o l l b a c k ; 
 
 b e g i n ; 
 
 u p d a t e   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 s e t         c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 1 ' 
 
 w h e r e   c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 1 ' 
 
 
 
 u p d a t e   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 s e t         c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 2 ' 
 
 w h e r e   c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 2 ' 
 
 
 
 u p d a t e   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 s e t         c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 3 ' 
 
 w h e r e   c o d i c e _ c a u s a l e = ' O R D - U . 3 . 0 1 . 0 1 0 5 . 0 0 3 ' 
 
 
 
 
 
 
 
 - - - - - - - - - - - - - - - - - - - - - - - 
 
 s e l e c t   e p . c a u s a l e _ e p _ i d , 
 
               e v e n t o . e v e n t o _ i d , 
 
               e p . c a u s a l e _ e p _ c o d e , 
 
               e v e n t o . e v e n t o _ c o d e , 
 
               c o u n t ( * ) 
 
 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o , s i a c _ t _ c a u s a l e _ e p   e p , 
 
           s i a c _ d _ e v e n t o   e v e n t o , s i a c _ d _ e v e n t o _ t i p o   t i p o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | ' S I A C - 6 6 6 1 ' | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o . e v e n t o _ t i p o _ c o d e = b k o . t i p o _ e v e n t o 
 
         a n d       e v e n t o . e v e n t o _ t i p o _ i d = t i p o . e v e n t o _ t i p o _ i d 
 
         a n d       e v e n t o . e v e n t o _ c o d e = b k o . e v e n t o 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 / *         a n d         e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ e v e n t o _ c a u s a l e   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ i d   =   e p . c a u s a l e _ e p _ i d 
 
         a n d       r 1 . e v e n t o _ i d = e v e n t o . e v e n t o _ i d 
 
         a n d       r 1 . l o g i n _ o p e r a z i o n e   n o t   l i k e   ' % S I A C - 6 6 6 1 % ' 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) * / 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         g r o u p   b y   e p . c a u s a l e _ e p _ i d , 
 
               e v e n t o . e v e n t o _ i d , 
 
               e p . c a u s a l e _ e p _ c o d e , 
 
               e v e n t o . e v e n t o _ c o d e 
 
         h a v i n g   c o u n t ( * ) > 1 
 
         o r d e r   b y   1 , 2 
 
 
 
 
 
         s e l e c t     * 
 
         f r o m   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o 
 
         w h e r e   b k o . c o d i c e _ c a u s a l e   i n 
 
         ( 
 
         ' R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 3 ' , 
 
         ' R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 2 ' , 
 
         ' R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 1 ' 
 
         ) 
 
         a n d     b k o . e v e n t o   = ' R O R - I - R P - I N S ' 
 
         - -   R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 3   R O R - I - R P - I N S 
 
         - -   R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 2 
 
         - -   R O R - I - R P - U . 3 . 0 1 . 0 1 . 0 5 . 0 0 1 