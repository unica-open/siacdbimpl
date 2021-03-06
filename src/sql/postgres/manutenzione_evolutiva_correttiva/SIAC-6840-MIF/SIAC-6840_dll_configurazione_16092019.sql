/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
��- -   n u o v e   c o l o n n e   x   m i f _ d _ f l u s s o _ e l a b o r a t o 
 
 S E L E C T   *   f r o m   f n c _ d b a _ a d d _ c o l u m n _ p a r a m s   ( ' m i f _ t _ o r d i n a t i v o _ s p e s a ' ,   ' m i f _ o r d _ p a g o p a _ n u m _ a v v i s o ' ,   ' v a r c h a r ( 5 0 ) ' ) ; 
 
 S E L E C T   *   f r o m   f n c _ d b a _ a d d _ c o l u m n _ p a r a m s   ( ' m i f _ t _ o r d i n a t i v o _ s p e s a ' ,   ' m i f _ o r d _ p a g o p a _ c o d f i s c ' ,   ' v a r c h a r ( 1 6 ) ' ) ; 
 
 
 
 - -   i n s e r i m e n t o   n u o v i   t a g   s u   m i f _ d _ f l u s s o _ e l a b o r a t o 
 
 I N S E R T   I N T O   m i f _ d _ f l u s s o _ e l a b o r a t o 
 
 ( 
 
             f l u s s o _ e l a b _ m i f _ o r d i n e , 
 
             f l u s s o _ e l a b _ m i f _ c o d e ,   f l u s s o _ e l a b _ m i f _ d e s c ,   f l u s s o _ e l a b _ m i f _ a t t i v o , 
 
             f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ,   f l u s s o _ e l a b _ m i f _ t a b e l l a ,   f l u s s o _ e l a b _ m i f _ c a m p o , 
 
             f l u s s o _ e l a b _ m i f _ d e f a u l t ,   f l u s s o _ e l a b _ m i f _ e l a b ,   f l u s s o _ e l a b _ m i f _ p a r a m , 
 
             v a l i d i t a _ i n i z i o ,   e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ,   f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b , 
 
             f l u s s o _ e l a b _ m i f _ q u e r y ,   f l u s s o _ e l a b _ m i f _ x m l _ o u t , f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 ) 
 
 s e l e c t   1 5 0 , ' a v v i s o _ p a g o P A ' , ' a v v i s o _ p a g o P A ' , t r u e , 
 
               ' f l u s s o _ o r d i n a t i v i . o r d i n a t i v i . m a n d a t o . i n f o r m a z i o n i _ b e n e f i c i a r i o . i n f o r m a z i o n i _ a g g i u n t i v e ' , ' ' , N U L L , N U L L , t r u e , 
 
               ' A V V I S O   P A G O P A ' , ' 2 0 1 9 - 0 1 - 0 1 ' , e n t e . e n t e _ p r o p r i e t a r i o _ i d , ' S I A C - 6 8 4 0 ' , 1 3 6 , N U L L , t r u e , t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,     m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e     e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d         t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d         t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d         n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1   f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 
 
 w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ o r d i n e = 1 5 0 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ c o d e = ' a v v i s o _ p a g o P A ' 
 
 ) ; 
 
 
 
 I N S E R T   I N T O   m i f _ d _ f l u s s o _ e l a b o r a t o 
 
 ( 
 
             f l u s s o _ e l a b _ m i f _ o r d i n e , 
 
             f l u s s o _ e l a b _ m i f _ c o d e ,   f l u s s o _ e l a b _ m i f _ d e s c ,   f l u s s o _ e l a b _ m i f _ a t t i v o , 
 
             f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ,   f l u s s o _ e l a b _ m i f _ t a b e l l a ,   f l u s s o _ e l a b _ m i f _ c a m p o , 
 
             f l u s s o _ e l a b _ m i f _ d e f a u l t ,   f l u s s o _ e l a b _ m i f _ e l a b ,   f l u s s o _ e l a b _ m i f _ p a r a m , 
 
             v a l i d i t a _ i n i z i o ,   e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ,   f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b , 
 
             f l u s s o _ e l a b _ m i f _ q u e r y ,   f l u s s o _ e l a b _ m i f _ x m l _ o u t , f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 ) 
 
 s e l e c t   1 5 1 , ' c o d i c e _ i d e n t i f i c a t i v o _ e n t e ' , ' C o d i c e   f i s c a l e   s o g g e t t o   i n t e s t a t a r i o   m a n d a t o ' , t r u e , 
 
               ' f l u s s o _ o r d i n a t i v i . o r d i n a t i v i . m a n d a t o . i n f o r m a z i o n i _ b e n e f i c i a r i o . i n f o r m a z i o n i _ a g g i u n t i v e . a v v i s o _ p a g o P A ' , 
 
               ' m i f _ t _ o r d i n a t i v o _ s p e s a ' , ' m i f _ o r d _ p a g o p a _ c o d f i s c ' , ' ' , t r u e , ' ' , ' 2 0 1 9 - 0 1 - 0 1 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , ' S I A C - 6 8 4 0 ' , 1 3 7 , N U L L , t r u e , t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,     m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e     e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d         t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d         t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d         n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1   f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 
 
 w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ o r d i n e = 1 5 1 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ c o d e = ' c o d i c e _ i d e n t i f i c a t i v o _ e n t e ' 
 
 ) ; 
 
 
 
 I N S E R T   I N T O   m i f _ d _ f l u s s o _ e l a b o r a t o 
 
 ( 
 
             f l u s s o _ e l a b _ m i f _ o r d i n e , 
 
             f l u s s o _ e l a b _ m i f _ c o d e ,   f l u s s o _ e l a b _ m i f _ d e s c ,   f l u s s o _ e l a b _ m i f _ a t t i v o , 
 
             f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e ,   f l u s s o _ e l a b _ m i f _ t a b e l l a ,   f l u s s o _ e l a b _ m i f _ c a m p o , 
 
             f l u s s o _ e l a b _ m i f _ d e f a u l t ,   f l u s s o _ e l a b _ m i f _ e l a b ,   f l u s s o _ e l a b _ m i f _ p a r a m , 
 
             v a l i d i t a _ i n i z i o ,   e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ,   f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b , 
 
             f l u s s o _ e l a b _ m i f _ q u e r y ,   f l u s s o _ e l a b _ m i f _ x m l _ o u t , f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 ) 
 
 s e l e c t   1 5 2 , ' n u m e r o _ a v v i s o ' , ' N u m e r o   a v v i s o ' , t r u e , 
 
               ' f l u s s o _ o r d i n a t i v i . o r d i n a t i v i . m a n d a t o . i n f o r m a z i o n i _ b e n e f i c i a r i o . i n f o r m a z i o n i _ a g g i u n t i v e . a v v i s o _ p a g o P A ' , 
 
               ' m i f _ t _ o r d i n a t i v o _ s p e s a ' , ' m i f _ o r d _ p a g o p a _ n u m _ a v v i s o ' , N U L L , t r u e , N U L L , ' 2 0 1 9 - 0 1 - 0 1 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , ' S I A C - 6 8 4 0 ' , 1 3 8 , N U L L , t r u e , t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,     m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1   f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 
 
 w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ o r d i n e = 1 5 2 
 
 a n d   m i f . f l u s s o _ e l a b _ m i f _ c o d e = ' n u m e r o _ a v v i s o ' 
 
 ) ; 
 
 
 
 - -   s p o s t a m e n t o   t a g 
 
 u p d a t e     m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 
 
 s e t           f l u s s o _ e l a b _ m i f _ o r d i n e = m i f . f l u s s o _ e l a b _ m i f _ o r d i n e + 3 
 
 f r o m         s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e     e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d         m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d         m i f . f l u s s o _ e l a b _ m i f _ o r d i n e > = 1 5 0 
 
 a n d         m i f . f l u s s o _ e l a b _ m i f _ c o d e   ! = ' a v v i s o _ p a g o P A ' 
 
 a n d         m i f . f l u s s o _ e l a b _ m i f _ c o d e _ p a d r e   n o t   l i k e   ' % a v v i s o _ p a g o P A % ' 
 
 a n d         e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d       m i f . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 ) 
 
 a n d   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 1 , m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ o r d i n e = 1 5 0 
 
 a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ c o d e   ! = ' a v v i s o _ p a g o P A ' 
 
 ) 
 
 a n d   n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m i f 1 , m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = ' M A N D M I F _ S P L U S ' 
 
 a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ t i p o _ i d = t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
 - - a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ o r d i n e = 1 5 0 
 
 a n d       m i f 1 . f l u s s o _ e l a b _ m i f _ c o d e   = ' a v v i s o _ p a g o P A ' 
 
 ) ; 
 
 
 
 - -   i n s e r i m e n t o   n u o v a   m o d a l i t a   d i   a c c r e d i t o 
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
     a c c r e d i t o _ g r u p p o _ i d , 
 
     l o g i n _ o p e r a z i o n e , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     v a l i d i t a _ i n i z i o 
 
 ) 
 
 s e l e c t   ' A P A ' , 
 
               ' A V V I S O   P A G O P A ' , 
 
               0 , 
 
               g r u p p o . a c c r e d i t o _ g r u p p o _ i d , 
 
               ' S I A C - 6 8 4 0 ' , 
 
               g r u p p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
               n o w ( ) 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d       g r u p p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e = ' G E ' 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o   a c c r e 
 
 w h e r e   a c c r e . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       a c c r e . a c c r e d i t o _ g r u p p o _ i d = g r u p p o . a c c r e d i t o _ g r u p p o _ i d 
 
 a n d       a c c r e . a c c r e d i t o _ t i p o _ c o d e = ' A P A ' 
 
 a n d       a c c r e . a c c r e d i t o _ t i p o _ d e s c = ' A V V I S O   P A G O P A ' 
 
 a n d       a c c r e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       a c c r e . v a l i d i t a _ f i n e   i s   n u l l 
 
 ) ; 
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
     l o g i n _ o p e r a z i o n e , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     v a l i d i t a _ i n i z i o 
 
 ) 
 
 s e l e c t   ' 2 2 ' , 
 
               ' A V V I S O   P A G O P A ' , 
 
               ' S I A C - 6 8 4 0 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               n o w ( ) 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l 
 
 w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 2 2 ' 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c = ' A V V I S O   P A G O P A ' 
 
 a n d       o i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       o i l . v a l i d i t a _ f i n e   i s   n u l l 
 
 ) ; 
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
     l o g i n _ o p e r a z i o n e , 
 
     e n t e _ p r o p r i e t a r i o _ i d , 
 
     v a l i d i t a _ i n i z i o 
 
 ) 
 
 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d , 
 
               o i l . a c c r e d i t o _ t i p o _ o i l _ i d , 
 
                 ' S I A C - 6 8 4 0 ' , 
 
               e n t e . e n t e _ p r o p r i e t a r i o _ i d , 
 
               n o w ( ) 
 
 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
           s i a c _ d _ a c c r e d i t o _ t i p o   t i p o , 
 
           s i a c _ d _ a c c r e d i t o _ t i p o _ o i l   o i l 
 
 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d   i n   ( 2 , 3 , 4 , 5 , 1 0 , 1 3 , 1 4 , 1 6 ) 
 
 a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ c o d e = ' A P A ' 
 
 a n d       t i p o . a c c r e d i t o _ t i p o _ d e s c = ' A V V I S O   P A G O P A ' 
 
 a n d       o i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ c o d e = ' 2 2 ' 
 
 a n d       o i l . a c c r e d i t o _ t i p o _ o i l _ d e s c = ' A V V I S O   P A G O P A ' 
 
 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
 a n d       o i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       o i l . v a l i d i t a _ f i n e   i s   n u l l 
 
 a n d       n o t   e x i s t s 
 
 ( 
 
 s e l e c t   1 
 
 f r o m   s i a c _ r _ a c c r e d i t o _ t i p o _ o i l   r 
 
 w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 a n d       r . a c c r e d i t o _ t i p o _ i d = t i p o . a c c r e d i t o _ t i p o _ i d 
 
 a n d       r . a c c r e d i t o _ t i p o _ o i l _ i d = o i l . a c c r e d i t o _ t i p o _ o i l _ i d 
 
 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
 ) ; 