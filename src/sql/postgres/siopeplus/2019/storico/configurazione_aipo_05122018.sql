/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- -   0 5 . 1 2 . 2 0 1 8   S o f i a   -   A I P O 
 
 - -   m a n c a   c o n f   T A G 
 
 
 
 - -   a t t i v a z i o n e 
 
 
 
 u p d a t e   s i a c _ r _ g e s t i o n e _ e n t e   r 
 
 s e t         g e s t i o n e _ l i v e l l o _ i d = d n e w . g e s t i o n e _ l i v e l l o _ i d , 
 
               d a t a _ m o d i f i c a = n o w ( ) , 
 
               l o g i n _ o p e r a z i o n e = r . l o g i n _ o p e r a z i o n e | | ' - a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ g e s t i o n e _ l i v e l l o   d , s i a c _ d _ g e s t i o n e _ l i v e l l o   d n e w 
 
 w h e r e   d . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       d . g e s t i o n e _ l i v e l l o _ c o d e = ' O R D I N A T I V I _ M I F _ T R A S M E T T I _ U N I I T ' 
 
 a n d       r . g e s t i o n e _ l i v e l l o _ i d = d . g e s t i o n e _ l i v e l l o _ i d 
 
 a n d       d n e w . e n t e _ p r o p r i e t a r i o _ i d = d . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       d n e w . g e s t i o n e _ l i v e l l o _ c o d e = ' O R D I N A T I V I _ M I F _ T R A S M E T T I _ S I O P E _ P L U S ' 
 
 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
 
 
 b e g i n ; 
 
 u p d a t e   s i a c _ t _ e n t e _ o i l   e 
 
 s e t         e n t e _ o i l _ s i o p e _ p l u s = t r u e 
 
 w h e r e   e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 u p d a t e   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 s e t       f l u s s o _ e l a b _ m i f _ n o m e _ f i l e = ' R i c S i s C _ R S ' 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' R I C F I M I F ' ; 
 
 
 
 
 
 - - -   c o n f i g u r a z i o n e 
 
 
 
 - -   r i c h i e d e r e   i   v a l o r i   s e g u e n t i 
 
 u p d a t e   s i a c _ t _ e n t e _ o i l   e 
 
 s e t         e n t e _ o i l _ c o d i c e _ i p a = ' U F E S 0 6 ' ,   - -   < c o d i c e _ e n t e > 
 
               e n t e _ o i l _ c o d i c e _ i s t a t = ' 0 0 0 7 1 4 2 5 0 ' ,   - -   < c o d i c e _ i s t a t _ e n t e > 
 
               e n t e _ o i l _ c o d i c e _ t r a m i t e = ' A 2 A - 0 8 5 1 7 0 6 6 ' ,   - -   < c o d i c e _ t r a m i t e _ e n t e > 
 
               e n t e _ o i l _ c o d i c e _ t r a m i t e _ b t = ' A 2 A - 3 2 8 5 4 4 3 6 ' ,   - -   < c o d i c e _ t r a m i t e _ B T > 
 
               e n t e _ o i l _ c o d i c e _ p c c _ u f f = ' A X 8 D P Y ' , 
 
               e n t e _ o i l _ c o d i c e _ o p i = ' R P I _ O P I ' , 
 
               e n t e _ o i l _ e s c l _ a n n u l l i = T R U E 
 
 w h e r e   e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 
 
 - -   i n s e r i m e n t o   t i p o   M A N D M I F _ P L U S 
 
 i n s e r t   i n t o   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o 
 
 ( f l u s s o _ e l a b _ m i f _ t i p o _ c o d e , 
 
   f l u s s o _ e l a b _ m i f _ t i p o _ d e s c , 
 
   f l u s s o _ e l a b _ m i f _ n o m e _ f i l e , 
 
   v a l i d i t a _ i n i z i o , 
 
   e n t e _ p r o p r i e t a r i o _ i d , 
 
   l o g i n _ o p e r a z i o n e , 
 
   f l u s s o _ e l a b _ m i f _ t i p o _ d e c 
 
 ) 
 
 v a l u e s 
 
 ( 
 
 ' M A N D M I F _ S P L U S ' , 
 
 ' S i o p e +   -   F l u s s o   X M L   M a n d a t i   ( o r d i n a t i v i   s p e s a ) ' , 
 
 ' M A N D M I F _ S P L U S ' , 
 
 ' 2 0 1 9 - 0 1 - 0 1 ' , 
 
 4 , 
 
 ' a d m i n - s i o p e + ' , 
 
 t r u e 
 
 ) ; 
 
 
 
 - -   i n s e r i m e n t o   t i p o   R E V M I F _ S P L U S 
 
 i n s e r t   i n t o   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o 
 
 ( f l u s s o _ e l a b _ m i f _ t i p o _ c o d e , 
 
   f l u s s o _ e l a b _ m i f _ t i p o _ d e s c , 
 
   f l u s s o _ e l a b _ m i f _ n o m e _ f i l e , 
 
   v a l i d i t a _ i n i z i o , 
 
   e n t e _ p r o p r i e t a r i o _ i d , 
 
   l o g i n _ o p e r a z i o n e , 
 
   f l u s s o _ e l a b _ m i f _ t i p o _ d e c 
 
 ) 
 
 v a l u e s 
 
 ( 
 
 ' R E V M I F _ S P L U S ' , 
 
 ' S i o p e +   -   F l u s s o   X M L   R e v e r s a l i   ( o r d i n a t i v i   i n c a s s o ) ' , 
 
 ' R E V M I F _ S P L U S ' , 
 
 ' 2 0 1 9 - 0 1 - 0 1 ' , 
 
 4 , 
 
 ' a d m i n - s i o p e + ' , 
 
 t r u e 
 
 ) ; 
 
 
 
 i n s e r t   i n t o   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o 
 
 ( 
 
     f l u s s o _ e l a b _ m i f _ t i p o _ c o d e , 
 
     f l u s s o _ e l a b _ m i f _ t i p o _ d e s c , 
 
     f l u s s o _ e l a b _ m i f _ n o m e _ f i l e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
   ' G I O C A S S A ' , 
 
   ' S i o p e +   -   G i o r n a l e   d i   C a s s a ' , 
 
   ' G d c ' , 
 
   ' 2 0 1 9 - 0 1 - 0 1 ' , 
 
   4 , 
 
   ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 s e l e c t   ' I N S E R T   I N T O   m i f _ d _ f l u s s o _ e l a b o r a t o   ( 
 
                         f l u s s o _ e l a b _ m i f _ o r d i n e , 
 
                         f l u s s o _ e l a b _ m i f _ c o d e ,   f l u s s o _ e l a b _ m i f _ d e s c ,   f l u s s o _ e l a b _ m i f _ a t t i v o , 
 
                         f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ,   f l u s s o _ e l a b _ m i f _ t a b e l l a ,   f l u s s o _ e l a b _ m i f _ c a m p o , 
 
                         f l u s s o _ e l a b _ m i f _ d e f a u l t ,   f l u s s o _ e l a b _ m i f _ e l a b ,   f l u s s o _ e l a b _ m i f _ p a r a m , 
 
                         v a l i d i t a _ i n i z i o ,   e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ,   f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b , 
 
                         f l u s s o _ e l a b _ m i f _ q u e r y ,   f l u s s o _ e l a b _ m i f _ x m l _ o u t , f l u s s o _ e l a b _ m i f _ t i p o _ i d )   v a l u e s   ( ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ o r d i n e | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c o d e ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ d e s c ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ a t t i v o | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ t a b e l l a ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c a m p o ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ d e f a u l t ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ e l a b | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ p a r a m ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( ' 2 0 1 9 - 0 1 - 0 1 ' ) | | ' , ' 
 
                         | |     t i p o _ a . e n t e _ p r o p r i e t a r i o _ i d | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . l o g i n _ o p e r a z i o n e ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ q u e r y ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ x m l _ o u t | | ' , ' 
 
                         | |     t i p o _ a . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
                         | |   ' ) ; ' 
 
 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   d , 
 
           m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o ,   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o _ a 
 
 w h e r e   d . e n t e _ p r o p r i e t a r i o _ i d = 2 9 
 
 a n d       d . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d       t i p o _ a . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o _ a . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' ; 
 
 
 
 s e l e c t   ' I N S E R T   I N T O   m i f _ d _ f l u s s o _ e l a b o r a t o   ( 
 
                         f l u s s o _ e l a b _ m i f _ o r d i n e , 
 
                         f l u s s o _ e l a b _ m i f _ c o d e ,   f l u s s o _ e l a b _ m i f _ d e s c ,   f l u s s o _ e l a b _ m i f _ a t t i v o , 
 
                         f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ,   f l u s s o _ e l a b _ m i f _ t a b e l l a ,   f l u s s o _ e l a b _ m i f _ c a m p o , 
 
                         f l u s s o _ e l a b _ m i f _ d e f a u l t ,   f l u s s o _ e l a b _ m i f _ e l a b ,   f l u s s o _ e l a b _ m i f _ p a r a m , 
 
                         v a l i d i t a _ i n i z i o ,   e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ,   f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b , 
 
                         f l u s s o _ e l a b _ m i f _ q u e r y ,   f l u s s o _ e l a b _ m i f _ x m l _ o u t , f l u s s o _ e l a b _ m i f _ t i p o _ i d )   v a l u e s   ( ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ o r d i n e | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c o d e ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ d e s c ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ a t t i v o | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ t a b e l l a ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ c a m p o ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ d e f a u l t ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ e l a b | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ p a r a m ) | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( ' 2 0 1 9 - 0 1 - 0 1 ' ) | | ' , ' 
 
                         | |     t i p o _ a . e n t e _ p r o p r i e t a r i o _ i d | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . l o g i n _ o p e r a z i o n e ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b | | ' , ' 
 
                         | |     q u o t e _ n u l l a b l e ( d . f l u s s o _ e l a b _ m i f _ q u e r y ) | | ' , ' 
 
                         | |     d . f l u s s o _ e l a b _ m i f _ x m l _ o u t | | ' , ' 
 
                         | |     t i p o _ a . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
                         | |   ' ) ; ' 
 
 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   d , 
 
           m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o ,   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o _ a 
 
 w h e r e   d . e n t e _ p r o p r i e t a r i o _ i d = 2 9 
 
 a n d       d . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' R E V M I F _ S P L U S ' 
 
 a n d       t i p o _ a . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o _ a . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' R E V M I F _ S P L U S ' ; 
 
 
 
 
 
 - -   i n s e r i m e n t o   s i a c _ d _ c o d i c e b o l l o _ p l u s 
 
 i n s e r t   i n t o   s i a c _ d _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ p l u s _ c o d e , 
 
     c o d b o l l o _ p l u s _ d e s c , 
 
     c o d b o l l o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
   ' 0 1 ' , 
 
   ' E S E N T E   B O L L O ' , 
 
   t r u e , 
 
   ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
   4 , 
 
   ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ p l u s _ c o d e , 
 
     c o d b o l l o _ p l u s _ d e s c , 
 
     c o d b o l l o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
   ' 0 2 ' , 
 
   ' A S S O G G E T T A T O   B O L L O   A   C A R I C O   E N T E ' , 
 
   f a l s e , 
 
   ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
   4 , 
 
   ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ p l u s _ c o d e , 
 
     c o d b o l l o _ p l u s _ d e s c , 
 
     c o d b o l l o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
   ' 0 3 ' , 
 
   ' A S S O G G E T T A T O   B O L L O   A   C A R I C O   B E N E F I C I A R I O ' , 
 
   f a l s e , 
 
   ' 2 0 1 7 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
   4 , 
 
   ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 - -   s i a c _ r _ c o d i c e b o l l o _ p l u s 
 
 
 
 - -   i n s e r i m e n t o   s i a c _ r _ c o d i c e b o l l o _ p l u s 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ i d , 
 
     c o d b o l l o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   b o l l o . c o d b o l l o _ i d , 
 
               p l u s . c o d b o l l o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               b o l l o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o d i c e b o l l o _ p l u s   p l u s ,   s i a c _ d _ c o d i c e b o l l o   b o l l o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o d b o l l o _ p l u s _ d e s c = ' E S E N T E   B O L L O ' 
 
 a n d       p l u s . c o d b o l l o _ p l u s _ e s e n t e = t r u e 
 
 a n d       b o l l o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       b o l l o . c o d b o l l o _ c o d e   i n   ( ' A I ' , ' 9 9 ' , ' D R P ' ) ; 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ i d , 
 
     c o d b o l l o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   b o l l o . c o d b o l l o _ i d , 
 
               p l u s . c o d b o l l o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               b o l l o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o d i c e b o l l o _ p l u s   p l u s ,   s i a c _ d _ c o d i c e b o l l o   b o l l o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o d b o l l o _ p l u s _ d e s c = ' A S S O G G E T T A T O   B O L L O   A   C A R I C O   B E N E F I C I A R I O ' 
 
 a n d       b o l l o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       b o l l o . c o d b o l l o _ c o d e   i n   ( ' S B ' ) ; 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ c o d i c e b o l l o _ p l u s 
 
 ( 
 
     c o d b o l l o _ i d , 
 
     c o d b o l l o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   b o l l o . c o d b o l l o _ i d , 
 
               p l u s . c o d b o l l o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               b o l l o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o d i c e b o l l o _ p l u s   p l u s ,   s i a c _ d _ c o d i c e b o l l o   b o l l o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o d b o l l o _ p l u s _ d e s c = ' A S S O G G E T T A T O   B O L L O   A   C A R I C O   E N T E ' 
 
 a n d       b o l l o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       b o l l o . c o d b o l l o _ c o d e   i n   ( ' S I ' , ' S D ' ) ; 
 
 
 
 
 
 
 
 - -     i n s e r t   i n   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 i n s e r t   i n t o   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ p l u s _ c o d e , 
 
     c o m m _ t i p o _ p l u s _ d e s c , 
 
     c o m m _ t i p o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
     ' C E ' , 
 
     ' A   C A R I C O   E N T E ' , 
 
     f a l s e , 
 
     ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
     4 , 
 
     ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ p l u s _ c o d e , 
 
     c o m m _ t i p o _ p l u s _ d e s c , 
 
     c o m m _ t i p o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
     ' B N ' , 
 
     ' A   C A R I C O   B E N E F I C I A R I O ' , 
 
     f a l s e , 
 
     ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
     4 , 
 
     ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ p l u s _ c o d e , 
 
     c o m m _ t i p o _ p l u s _ d e s c , 
 
     c o m m _ t i p o _ p l u s _ e s e n t e , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 v a l u e s 
 
 ( 
 
     ' E S ' , 
 
     ' E S E N T E ' , 
 
     t r u e , 
 
     ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
     4 , 
 
     ' a d m i n - s i o p e + ' 
 
 ) ; 
 
 
 
 
 
 - -   i n s e r t   i n t o   s i a c _ r _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 i n s e r t   i n t o   s i a c _ r _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ i d , 
 
     c o m m _ t i p o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . c o m m _ t i p o _ i d , 
 
               p l u s . c o m m _ t i p o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s   p l u s ,   s i a c _ d _ c o m m i s s i o n e _ t i p o   t i p o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o m m _ t i p o _ p l u s _ d e s c = ' E S E N T E ' 
 
 a n d       p l u s . c o m m _ t i p o _ p l u s _ e s e n t e = t r u e 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . c o m m _ t i p o _ c o d e   i n   ( ' E S ' ) ; 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ i d , 
 
     c o m m _ t i p o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . c o m m _ t i p o _ i d , 
 
               p l u s . c o m m _ t i p o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s   p l u s ,   s i a c _ d _ c o m m i s s i o n e _ t i p o   t i p o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o m m _ t i p o _ p l u s _ d e s c = ' A   C A R I C O   E N T E ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . c o m m _ t i p o _ c o d e   i n   ( ' C E ' ) ; 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ c o m m i s s i o n e _ t i p o _ p l u s 
 
 ( 
 
     c o m m _ t i p o _ i d , 
 
     c o m m _ t i p o _ p l u s _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . c o m m _ t i p o _ i d , 
 
               p l u s . c o m m _ t i p o _ p l u s _ i d , 
 
               ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s   p l u s ,   s i a c _ d _ c o m m i s s i o n e _ t i p o   t i p o 
 
 w h e r e   p l u s . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       p l u s . c o m m _ t i p o _ p l u s _ d e s c = ' A   C A R I C O   B E N E F I C I A R I O ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = p l u s . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . c o m m _ t i p o _ c o d e   i n   ( ' B N ' ) ; 
 
 
 
 
 
 - -   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' G F A ' , 
 
 	 	 ' A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' C B I ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' G F B ' , 
 
 	 	 ' A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' R E G A ' , 
 
 	 	 ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' R E G B ' , 
 
 	 	 ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' R E G ' , 
 
 	 	 ' R E G O L A R I Z Z A Z I O N E ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' S T I ' , 
 
 	 	 ' S T I P E N D I ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' A D A ' , 
 
 	 	 ' A D D E B I T O   P R E A U T O R I Z Z A T O ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o 
 
 ( 
 
     a c c r e d i t o _ t i p o _ c o d e , 
 
     a c c r e d i t o _ t i p o _ d e s c , 
 
     a c c r e d i t o _ p r i o r i t a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     a c c r e d i t o _ g r u p p o _ i d 
 
 ) 
 
 s e l e c t     ' C O M ' , 
 
 	 	 ' C O M P E N S A Z I O N E ' , 
 
                 0 , 
 
                 n o w ( ) , 
 
                 g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' ; 
 
 
 
 - -   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 
 
 - -   t i p i _ p a g a m e n t o   -   i n i z i o 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 1 ' , 
 
               ' C A S S A ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 2 ' , 
 
               ' B O N I F I C O   B A N C A R I O   E   P O S T A L E ' , 
 
               ' I T ' , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 3 ' , 
 
               ' S E P A   C R E D I T   T R A N S F E R ' , 
 
               ' S E P A ' , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 4 ' , 
 
               ' B O N I F I C O   E S T E R O   E U R O ' , 
 
               ' E X T R A S E P A ' , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 5 ' , 
 
               ' A C C R E D I T O   C O N T O   C O R R E N T E   P O S T A L E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 6 ' , 
 
               ' A S S E G N O   B A N C A R I O   E   P O S T A L E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 7 ' , 
 
               ' A S S E G N O   C I R C O L A R E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 8 ' , 
 
               ' F 2 4 E P ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 0 9 ' , 
 
               ' A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 0 ' , 
 
               ' A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 1 ' , 
 
               ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 2 ' , 
 
               ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 3 ' , 
 
               ' R E G O L A R I Z Z A Z I O N E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 4 ' , 
 
               ' V A G L I A   P O S T A L E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 5 ' , 
 
               ' V A G L I A   T E S O R O ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 6 ' , 
 
               ' A D D E B I T O   P R E A U T O R I Z Z A T O ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 7 ' , 
 
               ' D I S P O S I Z I O N E   D O C U M E N T O   E S T E R N O ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 8 ' , 
 
               ' C O M P E N S A Z I O N E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 - -   t i p i _ p a g a m e n t o   -   f i n e 
 
 
 
 - -   t i p i _ i n c a s s o   -   i n i z i o 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 1 9 ' , 
 
               ' A C C R E D I T O   B A N C A   D ' ' I T A L I A ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 2 0 ' , 
 
               ' P R E L I E V O   D A   C C   P O S T A L E ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
     a c c r e d i t o _ t i p o _ o i l _ a r e a , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' 2 1 ' , 
 
               ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   B A N C A   D ' ' I T A L I A ' , 
 
               n u l l , 
 
               n o w ( ) , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = 4 ; 
 
 - -   t i p i _ i n c a s s o   -   f i n e 
 
 
 
 
 
 / *   p e r   v e r i f i c a   d e i   d a t i   s u   r e g p / c m t o / c o a l 
 
 s e l e c t   o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e , 
 
     	       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c , 
 
               o i l . l o g i n _ o p e r a z i o n e , 
 
               g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e , 
 
               g r u p p o . a c c r e d i t o _ g r u p p o _ d e s c , 
 
               t i p o . a c c r e d i t o _ t i p o _ c o d e , 
 
               t i p o . a c c r e d i t o _ t i p o _ d e s c 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o , s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o , 
 
           s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l , s i a c _ r _ a c c r e d i t o _ t i p o _ o i l   r 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 2 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ i d = t i p o . a c c r e d i t o _ g r u p p o _ i d 
 
 a n d       r . a c c r e d i t o _ t i p o _ i d = t i p o . a c c r e d i t o _ t i p o _ i d 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ i d = r . a c c r e d i t o _ t i p o _ o i l _ i d 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
 a n d       o i l . l o g i n _ o p e r a z i o n e   l i k e   ' % + % ' 
 
 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
 o r d e r   b y   o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e : : i n t e g e r * / 
 
 
 
 - -   i n s e r i m e n t o   r e l a z i o n i   t i p i _ p a g a m e n t o 
 
 - -   i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 
 
 - -   0 1   -   C A S S A 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 1 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' C O N ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   0 2   -   B O N I F I C O   B A N C A R I O   E   P O S T A L E 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 2 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' B P ' , ' C B ' , ' C C B ' , ' C D ' , ' B D ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   0 3   -   S E P A   C R E D I T   T R A N S F E R 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 3 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' C B ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   0 4   -   B O N I F I C O   E S T E R O   E U R O 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 4 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' C B ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   0 5   -   A C C R E D I T O   C O N T O   C O R R E N T E   P O S T A L E 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 5 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' C C P ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   0 6   -   A S S E G N O   B A N C A R I O   E   P O S T A L E 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 6 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' A B ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   0 7   -   A S S E G N O   C I R C O L A R E 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 7 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' A S ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   0 8   -   F 2 4 E P 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 8 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' T E ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   0 9   -   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 0 9 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' G F A ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   1 0   -   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 0 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' G F B ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   1 1   -   R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   A 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 1 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' R E G A ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   1 2   -   R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   T E S O R E R I A   P R O V I N C I A L E   S T A T O   P E R   T A B   B 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 2 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' R E G B ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   1 3   -   R E G O L A R I Z Z A Z I O N E 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 3 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' R E G ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   1 6   -   A D D E B I T O   P R E A U T O R I Z Z A T O 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 6 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' A D A ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - -   1 7   -   D I S P O S I Z I O N E   D O C U M E N T O   E S T E R N O 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 7 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' S T I ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 - -   1 8   -   C O M P E N S A Z I O N E 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l 
 
 ( 
 
     a c c r e d i t o _ t i p o _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l ,   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 1 8 ' 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = o i l . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e   i n   ( ' C O M ' ) 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 - - -   c h i u s u r a   d e l l e   r e l a z i o n i   v e c c h i e 
 
 u p d a t e     s i a c _ r _ a c c r e d i t o _ t i p o _ o i l   r 
 
 s e t           d a t a _ c a n c e l l a z i o n e = n o w ( ) 
 
 w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       r . l o g i n _ o p e r a z i o n e ! = ' a d m i n - s i o p e + ' ; 
 
 
 
 
 
 - - -   T I P O   I N C A S S O 
 
 - -   t i p i _ i n c a s s i   r e g o l a r i z z a z i o n e 
 
 - -   i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ p l u s 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ p l u s 
 
   ( 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c _ i n c a s s o , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
   ) 
 
   s e l e c t   o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
                 ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   B A N C A   D ' ' I T A L I A ' , 
 
                 n o w ( ) , 
 
                 o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' 
 
   f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l 
 
   w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c = ' A C C R E D I T O   B A N C A   D ' ' I T A L I A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ p l u s 
 
   ( 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c _ i n c a s s o , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
   ) 
 
   s e l e c t   o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
                 ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   B A N C A   D ' ' I T A L I A ' , 
 
                 n o w ( ) , 
 
                 o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' 
 
   f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l 
 
   w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c = ' R E G O L A R I Z Z A Z I O N E   A C C R E D I T O   B A N C A   D ' ' I T A L I A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ r _ a c c r e d i t o _ t i p o _ p l u s 
 
   ( 
 
     a c c r e d i t o _ t i p o _ o i l _ i d , 
 
     a c c r e d i t o _ t i p o _ o i l _ d e s c _ i n c a s s o , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
   ) 
 
   s e l e c t   o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
                 ' R E G O L A R I Z Z A Z I O N E ' , 
 
                 n o w ( ) , 
 
                 o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
                 ' a d m i n - s i o p e + ' 
 
   f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l 
 
   w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c = ' R E G O L A R I Z Z A Z I O N E ' ; 
 
 
 
 
 
 
 
   - - -   C L A S S I F I C A T O R I   L I B E R I 
 
   - - -   I N C A S S O 
 
     - -   g e s t i o n e   c l a s s i f i c a t o r i   l i b e r i   i n c a s s o 
 
 
 
     - -   C L A S S I F I C A T O R E _ 2 6   O r d i n a t i v o   d i   e n t r a t a   I n f r u t t i f e r o 
 
     - -   C L A S S I F I C A T O R E _ 2 7   O r d i n a t i v o   d i   e n t r a t a   v i n c o l a t o   a   c o n t o 
 
     - -   C L A S S I F I C A T O R E _ 2 8   M o d a l i t �   i n c a s s o   O r d i n a t i v o   d i   e n t r a t a 
 
     - -   C L A S S I F I C A T O R E _ 2 9   O r d i n a t i v o   d i   e n t r a t a   s u   p r e l i e v o   d a   c c   p o s t a l e   n u m e r o 
 
 
 
   b e g i n ; 
 
   u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
   s e t         c l a s s i f _ t i p o _ d e s c = ' O r d i n a t i v o   d i   e n t r a t a   I n f r u t t i f e r o ' 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 6 ' ; 
 
 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' S I ' , 
 
                 ' I N F R U T T I F E R O ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 6 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' N O ' , 
 
                 ' F R U T T I F E R O ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 6 ' ; 
 
 
 
 
 
   u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
   s e t         c l a s s i f _ t i p o _ d e s c = ' O r d i n a t i v o   d i   e n t r a t a   v i n c o l a t o   a   c o n t o ' 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 7 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' V ' , 
 
                 ' V I N C O L A T A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 7 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' L ' , 
 
                 ' L I B E R A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 7 ' ; 
 
 
 
   - - -   m o d a l i t a   d i   i n c a s s o 
 
   u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
   s e t         c l a s s i f _ t i p o _ d e s c = ' M o d a l i t �   i n c a s s o   O r d i n a t i v o   d i   e n t r a t a ' 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' 0 1 ' , 
 
                 ' C A S S A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' 0 2 ' , 
 
                 ' A C C R E D I T O   B A N C A   D ' ' I T A L I A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' 0 3 ' , 
 
                 ' R E G O L A R I Z Z A Z I O N E ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' 0 4 ' , 
 
                 ' P R E L I E V O   D A   C C   P O S T A L E ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' 0 5 ' , 
 
                 ' C O M P E N S A Z I O N E ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 8 ' ; 
 
 
 
   u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
   s e t         c l a s s i f _ t i p o _ d e s c = ' O r d i n a t i v o   d i   e n t r a t a   s u   p r e l i e v o   d a   c c   p o s t a l e   n u m e r o ' 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 9 ' ; 
 
 
 
 
 
 - - -   P A G A M E N T O 
 
 - -   C L A S S I F I C A T O R E _ 2 2   O r d i n a t i v o   d i   p a g a m e n t o   I n f r u t t i f e r o 
 
 - -   C L A S S I F I C A T O R E _ 2 3   O r d i n a t i v o   d i   p a g a m e n t o   v i n c o l a t o   a   c o n t o 
 
 
 
 u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
 s e t         c l a s s i f _ t i p o _ d e s c = ' O r d i n a t i v o   d i   p a g a m e n t o   I n f r u t t i f e r o ' 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 2 ' ; 
 
 
 
     i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' N O ' , 
 
                 ' I N F R U T T I F E R A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 2 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' S I ' , 
 
                 ' F R U T T I F E R A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 2 ' ; 
 
 
 
   u p d a t e   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
   s e t         c l a s s i f _ t i p o _ d e s c = ' O r d i n a t i v o   d i   p a g a m e n t o   v i n c o l a t o   a   c o n t o ' 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 3 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' V ' , 
 
                 ' V I N C O L A T A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 3 ' ; 
 
 
 
   i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
   ( 
 
   	   c l a s s i f _ c o d e , 
 
           c l a s s i f _ d e s c , 
 
           c l a s s i f _ t i p o _ i d , 
 
           v a l i d i t a _ i n i z i o , 
 
           l o g i n _ o p e r a z i o n e , 
 
           e n t e _ p r o p r i e t a r i o _ i d 
 
   ) 
 
   s e l e c t   ' L ' , 
 
                 ' L I B E R A ' , 
 
                 t i p o . c l a s s i f _ t i p o _ i d , 
 
                 ' 2 0 1 9 - 0 1 - 0 1 ' : : t i m e s t a m p , 
 
                 ' a d m i n - s i o p e + ' , 
 
                 t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
   f r o m   s i a c _ D _ c l a s s _ t i p o   t i p o 
 
   w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
   a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 2 3 ' ; 
 
 
 
 
 
 
 
 - - - - - - - - - - - - -   r i c e z i o n i 
 
 
 
 - -   i n s e r t   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o 
 
 - -   Q ,   S   - -   q u i e t a n z a ,   s t o r n o   q u i e t a n z a 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o 
 
 ( 
 
     o i l _ e s i t o _ d e r i v a t o _ c o d e , 
 
     o i l _ e s i t o _ d e r i v a t o _ d e s c , 
 
     o i l _ r i c e v u t a _ t i p o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' Q U I E T A N Z A ' , 
 
               ' Q U I E T A N Z A ' , 
 
               t i p o . o i l _ r i c e v u t a _ t i p o _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ o i l _ r i c e v u t a _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . o i l _ r i c e v u t a _ t i p o _ c o d e = ' Q ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o 
 
 ( 
 
     o i l _ e s i t o _ d e r i v a t o _ c o d e , 
 
     o i l _ e s i t o _ d e r i v a t o _ d e s c , 
 
     o i l _ r i c e v u t a _ t i p o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' S T O R N O   Q U I E T A N Z A ' , 
 
               ' S T O R N O   Q U I E T A N Z A ' , 
 
               t i p o . o i l _ r i c e v u t a _ t i p o _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ o i l _ r i c e v u t a _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . o i l _ r i c e v u t a _ t i p o _ c o d e = ' S ' ; 
 
 
 
 
 
 - -   P   ,   P S   p r o v v i s o r i o ,   s t o r n o   p r o v v i s o r i o 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o 
 
 ( 
 
     o i l _ e s i t o _ d e r i v a t o _ c o d e , 
 
     o i l _ e s i t o _ d e r i v a t o _ d e s c , 
 
     o i l _ r i c e v u t a _ t i p o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' P R O V V I S O R I O ' , 
 
               ' P R O V V I S O R I O ' , 
 
               t i p o . o i l _ r i c e v u t a _ t i p o _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ o i l _ r i c e v u t a _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . o i l _ r i c e v u t a _ t i p o _ c o d e = ' P ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o 
 
 ( 
 
     o i l _ e s i t o _ d e r i v a t o _ c o d e , 
 
     o i l _ e s i t o _ d e r i v a t o _ d e s c , 
 
     o i l _ r i c e v u t a _ t i p o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e 
 
 ) 
 
 s e l e c t   ' S T O R N O   P R O V V I S O R I O ' , 
 
               ' S T O R N O   P R O V V I S O R I O ' , 
 
               t i p o . o i l _ r i c e v u t a _ t i p o _ i d , 
 
               n o w ( ) , 
 
               t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' 
 
 f r o m   s i a c _ d _ o i l _ r i c e v u t a _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       t i p o . o i l _ r i c e v u t a _ t i p o _ c o d e = ' P S ' ; 
 
 
 
 - -   i n s e r t   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 - -   q u i e t a n z a 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' M A N D A T O   E S E G U I T O ' , 
 
               ' M A N D A T O   E S E G U I T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' M A N D A T O   R E G O L A R I Z Z A T O ' , 
 
               ' M A N D A T O   R E G O L A R I Z Z A T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' R E V E R S A L E   E S E G U I T O ' , 
 
               ' R E V E R S A L E   E S E G U I T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
     o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' R E V E R S A L E   R E G O L A R I Z Z A T O ' , 
 
               ' R E V E R S A L E   R E G O L A R I Z Z A T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' Q U I E T A N Z A ' ; 
 
 
 
 
 
 
 
 - -   s t o r n o   q u i e t a n z a 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' M A N D A T O   S T O R N A T O ' , 
 
               ' M A N D A T O   S T O R N A T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' M A N D A T O   R I P R I S T I N A T O ' , 
 
               ' M A N D A T O   R I P R I S T I N A T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' R E V E R S A L E   S T O R N A T O ' , 
 
               ' R E V E R S A L E   S T O R N A T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   Q U I E T A N Z A ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
     o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' R E V E R S A L E   R I P R I S T I N A T O ' , 
 
               ' R E V E R S A L E   R I P R I S T I N A T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   Q U I E T A N Z A ' ; 
 
 
 
 
 
 
 
 - -   p r o v v i s o r i 
 
 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' S O S P E S O   U S C I T A   E S E G U I T O ' , 
 
               ' S O S P E S O   U S C I T A   E S E G U I T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' P R O V V I S O R I O ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' S O S P E S O   U S C I T A   S T O R N A T O ' , 
 
               ' S O S P E S O   U S C I T A   S T O R N A T O ' , 
 
               ' U ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   P R O V V I S O R I O ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' S O S P E S O   E N T R A T A   E S E G U I T O ' , 
 
               ' S O S P E S O   E N T R A T A   E S E G U I T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' P R O V V I S O R I O ' ; 
 
 
 
 i n s e r t   i n t o   s i a c _ d _ o i l _ q u a l i f i c a t o r e 
 
 ( 
 
   o i l _ q u a l i f i c a t o r e _ c o d e , 
 
     o i l _ q u a l i f i c a t o r e _ d e s c , 
 
     o i l _ q u a l i f i c a t o r e _ s e g n o , 
 
     o i l _ e s i t o _ d e r i v a t o _ i d , 
 
     v a l i d i t a _ i n i z i o , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     o i l _ q u a l i f i c a t o r e _ d r _ r e c 
 
 ) 
 
 s e l e c t   ' S O S P E S O   E N T R A T A   S T O R N A T O ' , 
 
               ' S O S P E S O   E N T R A T A   S T O R N A T O ' , 
 
               ' E ' , 
 
               o i l . o i l _ e s i t o _ d e r i v a t o _ i d , 
 
               n o w ( ) , 
 
               o i l . e n t e _ p r o p r i e t a r i o _ i d , 
 
               ' a d m i n - s i o p e + ' , 
 
               f a l s e 
 
 f r o m   s i a c _ d _ o i l _ e s i t o _ d e r i v a t o   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = 4 
 
 a n d       o i l . o i l _ e s i t o _ d e r i v a t o _ c o d e = ' S T O R N O   P R O V V I S O R I O ' ; 