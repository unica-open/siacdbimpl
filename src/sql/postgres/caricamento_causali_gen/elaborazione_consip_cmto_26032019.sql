/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
s e l e c t   * 
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
 b e g i n ; 
 
 s e l e c t 
 
 f n c _ s i a c _ b k o _ c a r i c a m e n t o _ p d c e _ c o n t o 
 
 (   2 0 1 9 , 
 
     3 , 
 
     ' A M B I T O _ F I N ' , 
 
     ' S I A C - 6 6 6 1 ' , 
 
     n o w ( ) : : t i m e s t a m p 
 
 ) 
 
 
 
 N O T I C E :     s t r M e s s a g g i o = I n s e r i m e n t o   c o d i c e   d i   b i l a n c i o   B . 1 3 . a   [ s i a c _ t _ c l a s s ] .   9 6 4 7 9 0 2 8 
 
 N O T I C E :     s t r M e s s a g g i o = I n s e r i m e n t o   c o d i c e   d i   b i l a n c i o   B . 1 3 . a   [ s i a c _ r _ c l a s s _ f a m _ t r e e ] .   4 9 2 6 4 6 
 
 N O T I C E :     C o n t i   l i v e l l o   V   i n s e r i t i = 8 
 
 N O T I C E :     C o n t i   l i v e l l o   V I   i n s e r i t i = 3 1 
 
 N O T I C E :     C o n t i   l i v e l l o   V I I   i n s e r i t i = 1 1 
 
 N O T I C E :     A t t r i b u t i   p d c e _ c o n t o _ f o g l i a   i n s e r i t i = 3 8 
 
 N O T I C E :     A t t r i b u t i   p d c e _ c o n t o _ d i _ l e g g e   i n s e r i t i = 5 0 
 
 N O T I C E :     A t t r i b u t i   p d c e _ a m m o r t a m e n t o   i n s e r i t i = 0 
 
 N O T I C E :     A t t r i b u t i   p d c e _ c o n t o _ a t t i v o   i n s e r i t i = 5 0 
 
 N O T I C E :     A t t r i b u t i   p d c e _ c o n t o _ s e g n o _ n e g a t i v o   i n s e r i t i = 0 
 
 N O T I C E :     C o d i f i c h e   d i   b i l a n c i o     p d c e _ c o n t o   i n s e r i t e = 4 4 
 
 N O T I C E :     C o d i f i c h e   d i   b i l a n c i o     p d c e _ c o n t o   i n s e r i t e = 2 5 
 
 N O T I C E :     I n s e r i m e n t o   c o n t i   P D C _ E C O N   d i   g e n e r a l e   a m b i t o C o d e = A M B I T O _ F I N .   E l a b o r a z i o n e   t e r m i n a t a . 
 
 
 
 r o l l b a c k ; 
 
 b e g i n ; 
 
 s e l e c t 
 
 f n c _ s i a c _ b k o _ c a r i c a m e n t o _ c a u s a l i 
 
 ( 
 
     2 0 1 9 , 
 
     3 , 
 
     ' A M B I T O _ F I N ' , 
 
       ' S I A C - 6 6 6 1 ' , 
 
     n o w ( ) : : t i m e s t a m p 
 
 ) ; 
 
 
 
 s e l e c t   c o u n t ( * ) 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 w h e r e   c a r i c a t a = f a l s e 
 
 - -   4 8 0 
 
 
 
 s e l e c t   d i s t i n c t   b k o . c o d i c e _ c a u s a l e 
 
 f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
 - -   2 3 7 
 
 
 
 
 
 
 
 N O T I C E :     n u m e r o C a u s a l i = 2 3 7 
 
 N O T I C E :     n u m e r o S t a t o C a u s a l i = 2 3 7 
 
 N O T I C E :     n u m e r o P d c F i n C a u s a l i = 2 3 7 
 
 N O T I C E :     n u m e r o C o n t i C a u s a l i = 4 7 4 
 
 N O T I C E :     n u m e r o C o n t i S E G N O C a u s a l i = 4 8 0 
 
 N O T I C E :     n u m e r o C o n t i T I P O I M P O R T O C a u s a l i = 4 7 4 
 
 N O T I C E :     n u m e r o C o n t i U T I L I Z Z O C O N T O C a u s a l i = 4 7 4 
 
 N O T I C E :     n u m e r o C o n t i U T I L I Z Z O I M P O R T O C a u s a l i = 4 7 4 
 
 N O T I C E :     n u m e r o C a u s a l i E v e n t o = 5 5 6 
 
 N O T I C E :     I n s e r i m e n t o   c a u s a l e   d i   g e n e r a l e   a m b i t o C o d e = A M B I T O _ F I N .   I n s e r i t e   2 3 7   c a u s a l i . 
 
 
 
 
 
 s e l e c t     * 
 
 f r o m   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o 
 
 - -   6 6 5 
 
 
 
 s e l e c t     d i s t i n c t   b k o . c o d i c e _ c a u s a l e ,   b k o . e v e n t o - - , b k o . e u 
 
 f r o m   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o 
 
 w h e r e     e x i s t s 
 
 ( s e l e c t   1   f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   c 
 
 w h e r e   c . c a r i c a t a = f a l s e 
 
 a n d       c . c o d i c e _ c a u s a l e = b k o . c o d i c e _ c a u s a l e ) 
 
 
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
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 3 
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
         s e l e c t   d i s t i n c t   e p . c a u s a l e _ e p _ i d , 
 
               e v e n t o . e v e n t o _ i d 
 
 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o , s i a c _ t _ c a u s a l e _ e p   e p , 
 
           s i a c _ d _ e v e n t o   e v e n t o , s i a c _ d _ e v e n t o _ t i p o   t i p o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 3 
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
 
 
         s e l e c t   d i s t i n c t   e p . c a u s a l e _ e p _ c o d e , s t a t o . c a u s a l e _ e p _ s t a t o _ c o d e , a m b i t o . a m b i t o _ c o d e , e p . v a l i d i t a _ i n i z i o 
 
 f r o m     s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ r _ c a u s a l e _ e p _ s t a t o   r s , s i a c _ d _ c a u s a l e _ e p _ s t a t o   s t a t o , 
 
           s i a c _ d _ a m b i t o   a m b i t o 
 
 w h e r e   e p . e n t e _ p r o p r i e t a r i o _ i d = 3 
 
 a n d       e p . c a u s a l e _ e p _ c o d e   l i k e   ' % U . 2 . 0 2 . 0 4 . 0 7 . 0 0 5 % ' 
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