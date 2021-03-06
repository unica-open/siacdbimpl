/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
��C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ s t i l o _ s i a c _ a t t o _ a m m _ v e r i f i c a _ a n n u l l a b i l i t a 
 
 ( 
 
     a t t o a m m _ i d _ i n   i n t e g e r 
 
 ) 
 
 R E T U R N S   b o o l e a n   A S 
 
 $ b o d y $ 
 
 D E C L A R E 
 
 
 
 a n n u l l a b i l e   b o o l e a n ; 
 
 c o d R e s u l t   i n t e g e r : = n u l l ; 
 
 
 
 
 
 t e s t _ d a t a   t i m e s t a m p ; 
 
 
 
 b e g i n 
 
 t e s t _ d a t a : = n o w ( ) ; 
 
 a n n u l l a b i l e : =   t r u e ; 
 
 
 
 
 
 
 
     s e l e c t   1   i n t o   c o d R e s u l t 
 
     f r o m   s i a c _ r _ a t t o _ a m m _ s t a t o   r s A t t o ,   s i a c _ d _ a t t o _ a m m _ s t a t o   s t a t o 
 
     w h e r e   r s A t t o . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
     a n d       s t a t o . a t t o a m m _ s t a t o _ i d = r s a t t o . a t t o a m m _ s t a t o _ i d 
 
     a n d       s t a t o . a t t o a m m _ s t a t o _ c o d e = ' A N N U L L A T O ' 
 
     a n d       t e s t _ d a t a   b e t w e e n   r s A t t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r s A t t o . v a l i d i t a _ f i n e ,   t e s t _ d a t a ) 
 
     a n d       r s A t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     l i m i t   1 ; 
 
     i f   c o d R e s u l t   i s   n o t   n u l l     t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
     r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   a t t o   a n n u l l a t o   % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     i f   a n n u l l a b i l e = t r u e   t h e n 
 
 
 
 
 
         s e l e c t   1     i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ b i l _ s t a t o _ o p _ a t t o _ a m m 
 
         w h e r e   a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d   d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;     e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   b i l _ s t a t o _ o p   % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ c a u s a l e _ a t t o _ a m m   r A t t o 
 
         w h e r e   r A t t o . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d   t e s t _ d a t a   b e t w e e n   r A t t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r A t t o . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d   r A t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;       e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   c a u s a l e _ a t t o _ a m m   % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t o _ a m m     r A t t o ,   s i a c _ t _ l i q u i d a z i o n e   l i q 
 
         w h e r e   r A t t o . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       l i q . l i q _ i d = r A t t o . l i q _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r A t t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r A t t o . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r A t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       l i q . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l     t h e n   a n n u l l a b i l e : = f a l s e ;     e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   l i q u i d a z i o n e _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
         - -   s o l o   i m p e g n i - a c c e r t a m e n t i   d e f i n i t i v i 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r A t t o   , s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s ,   s i a c _ d _ m o v g e s t _ s t a t o   s t a t o 
 
         w h e r e   r A t t o . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       t s . m o v g e s t _ t s _ i d = r a t t o . m o v g e s t _ t s _ i d 
 
         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e   i n   ( ' D ' , ' N ' ) 
 
         a n d       t e s t _ d a t a   b e t w e e n   r s . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r s . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       t e s t _ d a t a   b e t w e e n   r A t t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a t t o . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r A t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;     e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   m o v g e s t _ t s _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ m u t u o _ a t t o _ a m m   r A t t o ,   s i a c _ t _ m u t u o   m 
 
         w h e r e   r A t t o . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       m . m u t _ i d = r A t t o . m u t _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r A t t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r A t t o . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r A t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l     t h e n   a n n u l l a b i l e : = f a l s e ;         e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   m u t u o _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t o _ a m m   r a ,   s i a c _ t _ o r d i n a t i v o   o 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       o . o r d _ i d = r a . o r d _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l     t h e n   a n n u l l a b i l e : = f a l s e ;     e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   o r d i n a t i v o _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ p r e d o c _ a t t o _ a m m   r a ,   s i a c _ t _ p r e d o c   p 
 
         w h e r e     r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d         p . p r e d o c _ i d = r a . p r e d o c _ i d 
 
         a n d         t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d         r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d         p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   p r e d o c _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
 	 s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ p r o g r a m m a _ a t t o _ a m m   r a ,   s i a c _ t _ p r o g r a m m a   p 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       p . p r o g r a m m a _ i d = r a . p r o g r a m m a _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   p r o g r a m m a _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
 
 
     e n d   i f ; 
 
 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ s u b d o c _ a t t o _ a m m   r a ,   s i a c _ t _ s u b d o c   s u b ,   s i a c _ t _ d o c   d o c 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       s u b . s u b d o c _ i d = r a . s u b d o c _ i d 
 
         a n d       d o c . d o c _ i d = s u b . d o c _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   s u b d o c _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
         s e l e c t   1     i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ r _ v a r i a z i o n e _ s t a t o   r a ,   s i a c _ t _ b i l _ e l e m _ d e t _ v a r   d v a r , s i a c _ t _ v a r i a z i o n e   v a r 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       d v a r . v a r i a z i o n e _ s t a t o _ i d = r a . v a r i a z i o n e _ s t a t o _ i d 
 
         a n d       v a r . v a r i a z i o n e _ i d = r a . v a r i a z i o n e _ i d 
 
         a n d       t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       d v a r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       v a r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   v a r i a z i o n e _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ t _ a t t o _ a l l e g a t o   r a 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d   t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d   r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   a t t o _ a l l e g a t o _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ t _ c a r t a c o n t   r a 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d   t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d   r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l   l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   c a r t a c o n t _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ t _ c a s s a _ e c o n _ o p e r a z   r a 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d   t e s t _ d a t a   b e t w e e n   r a . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( r a . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d   r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l   l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   c a s s a _ e c o n _ o p e r a z _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
 
 
 
 
     e n d   i f ; 
 
 
 
     i f   a n n u l l a b i l e   =   t r u e   T H E N 
 
 
 
 
 
 
 
 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ t _ m o d i f i c a     r a ,   s i a c _ r _ m o d i f i c a _ s t a t o   s t ,   s i a c _ d _ m o d i f i c a _ s t a t o   s t a 
 
         w h e r e   r a . a t t o a m m _ i d = a t t o a m m _ i d _ i n 
 
         a n d       s t . m o d _ i d = r a . m o d _ i d 
 
         a n d       s t a . m o d _ s t a t o _ i d = s t . m o d _ s t a t o _ i d 
 
         a n d       s t a . m o d _ s t a t o _ c o d e < > ' A ' 
 
         a n d       t e s t _ d a t a   b e t w e e n   s t . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e ( s t . v a l i d i t a _ f i n e , t e s t _ d a t a ) 
 
         a n d       s t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r a . d a t a _ c a n c e l l a z i o n e   i s   n u l l   l i m i t   1 ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n   a n n u l l a b i l e : = f a l s e ;   e n d   i f ; 
 
         r a i s e   n o t i c e   '   A t t o   a n n u l l a b i l e   :   e s i s t e   m o d i f i c a _ a t t o _ a m m     % ' , ( n o t   a n n u l l a b i l e ) ; 
 
     e n d   i f ; 
 
 
 
 r e t u r n   a n n u l l a b i l e ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   n o _ d a t a _ f o u n d   t h e n 
 
                 r e t u r n   f a l s e ; 
 
   	 w h e n   o t h e r s     T H E N 
 
   	 	 R A I S E   E X C E P T I O N   ' E r r o r e   D B   %   % ' , S Q L S T A T E , s u b s t r i n g ( S Q L E R R M   f r o m   1   f o r   1 0 0 0 ) ; 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 