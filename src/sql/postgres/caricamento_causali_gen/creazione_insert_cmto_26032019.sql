/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 3 ente_proprietario_id) ente
order by bko.carica_pdce_conto_id


select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 3 ente_proprietario_id) ente
where bko.caricata=false
order by bko.carica_cau_id

select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 3 ente_proprietario_id) ente
where bko.caricata=false
order by bko.carica_cau_id

select 'insert into siac_bko_t_causale_evento ( pdc_fin ,codice_causale,tipo_evento,evento,eu ,ente_proprietario_id ) values ('
         ||quote_nullable(bko.pdc_fin)||','
         ||quote_nullable(bko.codice_causale)||','
         ||quote_nullable(bko.tipo_evento)||','
         ||quote_nullable(bko.evento)||','
         ||quote_nullable(bko.eu)||','
         ||ente.ente_proprietario_id || ');'
from  siac_bko_t_causale_evento bko,
       (select 3 ente_proprietario_id) ente
order by bko.carica_cau_ev_id



select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) select '
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id ||
' where not exists ( select 1 from siac_t_pdce_conto conto,siac_d_ambito ambito, siac_d_pdce_conto_tipo tipo
                     where conto.ente_proprietario_id='
                     ||ente.ente_proprietario_id
                     ||' and conto.pdce_conto_code='
                     ||quote_nullable(bko.pdce_conto_code)
                     ||' and conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id and tipo.ente_proprietario_id=conto.ente_proprietario_id '
                     ||' and tipo.pdce_ct_tipo_code='
                     ||quote_nullable(bko.tipo_conto)
                     ||' and ambito.ente_proprietario_id=conto.ente_proprietario_id and ambito.ambito_code='
                     ||quote_nullable(bko.ambito)
                     ||' and conto.data_cancellazione is null and conto.validita_fine is null );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id
            ||' );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id


select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
where bko.caricata=false
order by ente.ente_proprietario_id,bko.carica_cau_id


select 'insert into siac_bko_t_causale_evento ( pdc_fin ,codice_causale,tipo_evento,evento,eu ,ente_proprietario_id ) values ('
         ||quote_nullable(bko.pdc_fin)||','
         ||quote_nullable(bko.codice_causale)||','
         ||quote_nullable(bko.tipo_evento)||','
         ||quote_nullable(bko.evento)||','
         ||quote_nullable(bko.eu)||','
         ||ente.ente_proprietario_id || ');'
from  siac_bko_t_causale_evento bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
order by ente.ente_proprietario_id, bko.carica_cau_ev_id                  | | q u o t e _ n u l l a b l e ( b k o . t i p o _ o p e r a z i o n e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c l a s s e _ c o n t o ) | | ' , ' 
 
                         | | b k o . l i v e l l o | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o d i f i c a _ b i l ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . t i p o _ c o n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ f o g l i a ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ d i _ l e g g e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ c o d i f i c a _ i n t e r n a ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . a m m o r t a m e n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ a t t i v o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ s e g n o _ n e g a t i v o ) | | ' , ' 
 
                         | | e n t e . e n t e _ p r o p r i e t a r i o _ i d   | | 
 
 '   w h e r e   n o t   e x i s t s   (   s e l e c t   1   f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ d _ a m b i t o   a m b i t o ,   s i a c _ d _ p d c e _ c o n t o _ t i p o   t i p o 
 
                                           w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = ' 
 
                                           | | e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
                                           | | '   a n d   c o n t o . p d c e _ c o n t o _ c o d e = ' 
 
                                           | | q u o t e _ n u l l a b l e ( b k o . p d c e _ c o n t o _ c o d e ) 
 
                                           | | '   a n d   c o n t o . p d c e _ c t _ t i p o _ i d = t i p o . p d c e _ c t _ t i p o _ i d   a n d   t i p o . e n t e _ p r o p r i e t a r i o _ i d = c o n t o . e n t e _ p r o p r i e t a r i o _ i d   ' 
 
                                           | | '   a n d   t i p o . p d c e _ c t _ t i p o _ c o d e = ' 
 
                                           | | q u o t e _ n u l l a b l e ( b k o . t i p o _ c o n t o ) 
 
                                           | | '   a n d   a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = c o n t o . e n t e _ p r o p r i e t a r i o _ i d   a n d   a m b i t o . a m b i t o _ c o d e = ' 
 
                                           | | q u o t e _ n u l l a b l e ( b k o . a m b i t o ) 
 
                                           | | '   a n d   c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l   a n d   c o n t o . v a l i d i t a _ f i n e   i s   n u l l   ) ; ' 
 
 f r o m       s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
               ( s e l e c t   4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   5   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 0   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 3   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 6   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   2 9   e n t e _ p r o p r i e t a r i o _ i d 
 
                 )   e n t e 
 
 o r d e r   b y   e n t e . e n t e _ p r o p r i e t a r i o _ i d ,   b k o . c a r i c a _ p d c e _ c o n t o _ i d 
 
 
 
 s e l e c t   ' I N S E R T   I N T O   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   (   p d c e _ c o n t o _ c o d e , p d c e _ c o n t o _ d e s c , t i p o _ o p e r a z i o n e , c l a s s e _ c o n t o , l i v e l l o , c o d i f i c a _ b i l ,   t i p o _ c o n t o , c o n t o _ f o g l i a , c o n t o _ d i _ l e g g e , c o n t o _ c o d i f i c a _ i n t e r n a , a m m o r t a m e n t o , c o n t o _ a t t i v o , c o n t o _ s e g n o _ n e g a t i v o , e n t e _ p r o p r i e t a r i o _ i d   )   v a l u e s   (   ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . p d c e _ c o n t o _ c o d e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . p d c e _ c o n t o _ d e s c ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . t i p o _ o p e r a z i o n e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c l a s s e _ c o n t o ) | | ' , ' 
 
                         | | b k o . l i v e l l o | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o d i f i c a _ b i l ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . t i p o _ c o n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ f o g l i a ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ d i _ l e g g e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ c o d i f i c a _ i n t e r n a ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . a m m o r t a m e n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ a t t i v o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ s e g n o _ n e g a t i v o ) | | ' , ' 
 
                         | | e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
                         | | '   ) ; ' 
 
 f r o m       s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
               ( s e l e c t   4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   5   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 0   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 3   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 6   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   2 9   e n t e _ p r o p r i e t a r i o _ i d 
 
                 )   e n t e 
 
 o r d e r   b y   e n t e . e n t e _ p r o p r i e t a r i o _ i d ,   b k o . c a r i c a _ p d c e _ c o n t o _ i d 
 
 
 
 
 
 s e l e c t   ' I N S E R T   I N T O   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   (   p d c _ f i n , c o d i c e _ c a u s a l e , d e s c r i z i o n e _ c a u s a l e , p d c _ e c o n _ p a t r , s e g n o , c o n t o _ i v a , l i v e l l i , t i p o _ c o n t o ,   t i p o _ i m p o r t o ,   u t i l i z z o _ c o n t o , u t i l i z z o _ i m p o r t o , c a u s a l e _ d e f a u l t ,   e u ,   e n t e _ p r o p r i e t a r i o _ i d   )   v a l u e s   ( ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . p d c _ f i n ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o d i c e _ c a u s a l e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . d e s c r i z i o n e _ c a u s a l e ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . p d c _ e c o n _ p a t r ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . s e g n o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c o n t o _ i v a ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . l i v e l l i ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . t i p o _ c o n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . t i p o _ i m p o r t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . u t i l i z z o _ c o n t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . u t i l i z z o _ i m p o r t o ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . c a u s a l e _ d e f a u l t ) | | ' , ' 
 
                         | | q u o t e _ n u l l a b l e ( b k o . e u ) | | ' , ' 
 
                         | | e n t e . e n t e _ p r o p r i e t a r i o _ i d   | |   ' ) ; ' 
 
 f r o m       s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o , 
 
               ( s e l e c t   4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   5   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 0   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 3   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 6   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   2 9   e n t e _ p r o p r i e t a r i o _ i d )   e n t e 
 
 w h e r e   b k o . c a r i c a t a = f a l s e 
 
 o r d e r   b y   e n t e . e n t e _ p r o p r i e t a r i o _ i d , b k o . c a r i c a _ c a u _ i d 
 
 
 
 
 
 s e l e c t   ' i n s e r t   i n t o   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   (   p d c _ f i n   , c o d i c e _ c a u s a l e , t i p o _ e v e n t o , e v e n t o , e u   , e n t e _ p r o p r i e t a r i o _ i d   )   v a l u e s   ( ' 
 
                   | | q u o t e _ n u l l a b l e ( b k o . p d c _ f i n ) | | ' , ' 
 
                   | | q u o t e _ n u l l a b l e ( b k o . c o d i c e _ c a u s a l e ) | | ' , ' 
 
                   | | q u o t e _ n u l l a b l e ( b k o . t i p o _ e v e n t o ) | | ' , ' 
 
                   | | q u o t e _ n u l l a b l e ( b k o . e v e n t o ) | | ' , ' 
 
                   | | q u o t e _ n u l l a b l e ( b k o . e u ) | | ' , ' 
 
                   | | e n t e . e n t e _ p r o p r i e t a r i o _ i d   | |   ' ) ; ' 
 
 f r o m     s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o , 
 
               ( s e l e c t   4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   5   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 0   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 3   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 4   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   1 6   e n t e _ p r o p r i e t a r i o _ i d 
 
                 u n i o n 
 
                 s e l e c t   2 9   e n t e _ p r o p r i e t a r i o _ i d )   e n t e 
 
 o r d e r   b y   e n t e . e n t e _ p r o p r i e t a r i o _ i d ,   b k o . c a r i c a _ c a u _ e v _ i d 