/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ p o p o l a _ m o r e   ( 
 
     f a s e b i l e l a b i d   i n t e g e r , 
 
     e n t e p r o p r i e t a r i o i d   i n t e g e r , 
 
     a n n o b i l a n c i o   i n t e g e r , 
 
     t i p o a p e r t u r a   v a r c h a r , 
 
     l o g i n o p e r a z i o n e   v a r c h a r , 
 
     d a t a e l a b o r a z i o n e   t i m e s t a m p , 
 
     o u t   c o d i c e r i s u l t a t o   i n t e g e r , 
 
     o u t   m e s s a g g i o r i s u l t a t o   v a r c h a r 
 
 ) 
 
 R E T U R N S   r e c o r d   A S 
 
 $ b o d y $ 
 
 D E C L A R E 
 
 	 s t r M e s s a g g i o   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 	 s t r M e s s a g g i o F i n a l e   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 
 
 	 c o d R e s u l t                   i n t e g e r : = n u l l ; 
 
 
 
         b i l a n c i o I d                 i n t e g e r : = n u l l ; 
 
     	 b i l a n c i o P r e c I d         i n t e g e r : = n u l l ; 
 
         p e r i o d o I d                   i n t e g e r : = n u l l ; 
 
         p e r i o d o P r e c I d           i n t e g e r : = n u l l ; 
 
 	 d a t a I n i z i o V a l           t i m e s t a m p : = n u l l ; 
 
 
 
 
 
         b i l a n c i o E l a b I d                                       i n t e g e r : = n u l l ; 
 
 
 
         A P E _ G E S T _ P R O G R A M M I         	         	   C O N S T A N T   v a r c h a r : = ' A P E _ G E S T _ P R O G R A M M I ' ; 
 
 
 
         P _ F A S E 	 	 	 	 	 	 	   C O N S T A N T   v a r c h a r : = ' P ' ; 
 
         G _ F A S E 	 	 	 	 	         	   C O N S T A N T   v a r c h a r : = ' G ' ; 
 
 
 
 	 S T A T O _ A N   	 	 	         	           C O N S T A N T   v a r c h a r : = ' A N ' ; 
 
         n u m e r o P r o g r                                             i n t e g e r : = n u l l ; 
 
         n u m e r o C r o n o p 	 	 	 	 	   i n t e g e r : = 0 ; 
 
         p r o g r a m m a T i p o C o d e                                 v a r c h a r ( 1 0 ) : = n u l l ; 
 
 B E G I N 
 
 
 
       c o d i c e R i s u l t a t o : = n u l l ; 
 
       m e s s a g g i o R i s u l t a t o : = n u l l ; 
 
 
 
       d a t a I n i z i o V a l : =   c l o c k _ t i m e s t a m p ( ) ; 
 
 
 
 
 
       s t r m e s s a g g i o f i n a l e : = ' A p e r t u r a   P r o g r a m m i - C r o n o p r o g r a m m i   d i   t i p o   ' | | t i p o A p e r t u r a | | '   p e r   a n n o B i l a n c i o = ' | | a n n o B i l a n c i o : : v a r c h a r | | ' .   P o p o l a m e n t o . ' ; 
 
 
 
       s t r M e s s a g g i o : = ' I n s e r i m e n t o   L O G . ' ; 
 
       c o d R e s u l t : = n u l l ; 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       v a l u e s 
 
       ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - I N I Z I O . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
       e n d   i f ; 
 
 
 
 
 
 
 
 
 
       s t r M e s s a g g i o : = ' L e t t u r a   b i l a n c i o I d   e   p e r i o d o I d     p e r   a n n o B i l a n c i o = ' | | a n n o B i l a n c i o : : v a r c h a r | | ' . ' ; 
 
       s e l e c t   b i l . b i l _ i d   ,   p e r . p e r i o d o _ i d   i n t o   s t r i c t   b i l a n c i o I d ,   p e r i o d o I d 
 
       f r o m   s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r 
 
       w h e r e   b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
       a n d       p e r . a n n o : : I N T E G E R = a n n o B i l a n c i o 
 
       a n d       b i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       p e r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' L e t t u r a   b i l a n c i o I d   e   p e r i o d o I d     p e r   a n n o B i l a n c i o - 1 = ' | | ( a n n o B i l a n c i o - 1 ) : : v a r c h a r | | ' . ' ; 
 
       s e l e c t   b i l . b i l _ i d   ,   p e r . p e r i o d o _ i d   i n t o   s t r i c t   b i l a n c i o P r e c I d ,   p e r i o d o P r e c I d 
 
       f r o m   s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r 
 
       w h e r e   b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
       a n d       p e r . a n n o : : I N T E G E R = a n n o B i l a n c i o - 1 
 
       a n d       b i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       p e r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
       - - s i a c _ t _ p r o g r a m m a 
 
       - - s i a c _ r _ p r o g r a m m a _ s t a t o 
 
       - - s i a c _ r _ p r o g r a m m a _ c l a s s 
 
       - - s i a c _ r _ p r o g r a m m a _ a t t r 
 
       - - s i a c _ r _ p r o g r a m m a _ a t t o _ a m m 
 
       - - s i a c _ r _ m o v g e s t _ t s _ p r o g r a m m a 
 
       - - s i a c _ t _ c r o n o p 
 
       - - s i a c _ r _ c r o n o p _ s t a t o 
 
       - - s i a c _ r _ c r o n o p _ a t t r 
 
       - - s i a c _ t _ c r o n o p _ e l e m 
 
       - - s i a c _ r _ c r o n o p _ e l e m _ c l a s s 
 
       - - s i a c _ r _ c r o n o p _ e l e m _ b i l _ e l e m 
 
       - - s i a c _ t _ c r o n o p _ e l e m _ d e t 
 
 
 
       i f   t i p o A p e r t u r a = P _ F A S E   T H E N 
 
       	 b i l a n c i o E l a b I d : = b i l a n c i o P r e c I d ; 
 
 - -         p r o g r a m m a T i p o C o d e = G _ F A S E ; 
 
         p r o g r a m m a T i p o C o d e = P _ F A S E ; 
 
       e l s e 
 
       	 b i l a n c i o E l a b I d : = b i l a n c i o I d ; 
 
         p r o g r a m m a T i p o C o d e = P _ F A S E ; 
 
       e n d   i f ; 
 
 
 
       s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p r o g r a m m i   i n   f a s e _ b i l _ t _ p r o g r a m m i . ' ; 
 
       c o d R e s u l t : = n u l l ; 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       v a l u e s 
 
       ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
       e n d   i f ; 
 
 
 
 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ p r o g r a m m i 
 
       ( 
 
       	 f a s e _ b i l _ e l a b _ i d , 
 
 	 f a s e _ b i l _ p r o g r a m m a _ a p e _ t i p o , 
 
 	 p r o g r a m m a _ i d , 
 
 	 p r o g r a m m a _ t i p o _ i d , 
 
 	 b i l _ i d , 
 
         l o g i n _ o p e r a z i o n e , 
 
         e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       s e l e c t   f a s e B i l E l a b I d , 
 
                     t i p o A p e r t u r a , 
 
                     p r o g . p r o g r a m m a _ i d , 
 
                     t i p o . p r o g r a m m a _ t i p o _ i d , 
 
                     p r o g . b i l _ i d , 
 
                     l o g i n O p e r a z i o n e , 
 
                     p r o g . e n t e _ p r o p r i e t a r i o _ i d 
 
       f r o m   s i a c _ t _ p r o g r a m m a   p r o g , s i a c _ d _ p r o g r a m m a _ t i p o   t i p o , 
 
 	         s i a c _ r _ p r o g r a m m a _ s t a t o   r s , s i a c _ d _ p r o g r a m m a _ s t a t o   s t a t o , s i a c _ v _ b k o _ A n n o _ b i l a n c i o   a n n o 
 
       w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       t i p o . p r o g r a m m a _ t i p o _ c o d e = p r o g r a m m a T i p o C o d e 
 
       a n d       p r o g . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
       a n d       p r o g . b i l _ i d = b i l a n c i o E l a b I d   - -   d a   P   a   G 
 
       a n d       a n n o . b i l _ i d = p r o g . b i l _ i d 
 
 - -       a n d       a n n o . a n n o _ b i l a n c i o < a n n o B i l a n c i o   -   P 
 
       a n d       r s . p r o g r a m m a _ i d = p r o g . p r o g r a m m a _ i d 
 
       a n d       s t a t o . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
       a n d       s t a t o . p r o g r a m m a _ s t a t o _ c o d e ! = S T A T O _ A N 
 
       a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l 
 
       a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
       / * a n d       n o t   e x i s t s   - -   P 
 
       ( 
 
         s e l e c t   1 
 
         f r o m   s i a c _ t _ p r o g r a m m a   p 1 , s i a c _ r _ p r o g r a m m a _ S t a t o   r s 1 
 
         w h e r e   p 1 . p r o g r a m m a _ t i p o _ i d = t i p o . p r o g r a m m a _ t i p o _ i d 
 
         a n d       p 1 . p r o g r a m m a _ c o d e = p r o g . p r o g r a m m a _ c o d e 
 
         a n d       p 1 . b i l _ i d = b i l a n c i o I d 
 
         a n d       r s 1 . p r o g r a m m a _ i d = p 1 . p r o g r a m m a _ i d 
 
         a n d       r s 1 . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
         a n d       r s 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       p 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       p 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
       ) * / 
 
       a n d       n o t   e x i s t s   - -   d a   p   a   g 
 
       ( 
 
         s e l e c t   1 
 
         f r o m   s i a c _ t _ p r o g r a m m a   p 1 , s i a c _ r _ p r o g r a m m a _ S t a t o   r s 1 , s i a c _ d _ p r o g r a m m a _ t i p o   t i p o 1 
 
         w h e r e   t i p o 1 . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o 1 . p r o g r a m m a _ t i p o _ c o d e = G _ F A S E 
 
         a n d       p 1 . p r o g r a m m a _ t i p o _ i d = t i p o 1 . p r o g r a m m a _ t i p o _ i d 
 
         a n d       p 1 . p r o g r a m m a _ c o d e = p r o g . p r o g r a m m a _ c o d e 
 
         a n d       p 1 . b i l _ i d = b i l a n c i o I d 
 
         a n d       r s 1 . p r o g r a m m a _ i d = p 1 . p r o g r a m m a _ i d 
 
         a n d       r s 1 . p r o g r a m m a _ s t a t o _ i d = r s . p r o g r a m m a _ s t a t o _ i d 
 
         a n d       r s 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       p 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       p 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
       ) ; 
 
       G E T   D I A G N O S T I C S   n u m e r o P r o g r   =   R O W _ C O U N T ; 
 
 
 
       s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p r o g r a m m i   i n   f a s e _ b i l _ t _ p r o g r a m m i   n u m e r o = ' | | n u m e r o P r o g r : : v a r c h a r | | ' . ' ; 
 
       c o d R e s u l t : = n u l l ; 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       v a l u e s 
 
       ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
       e n d   i f ; 
 
 
 
       i f   c o a l e s c e ( n u m e r o P r o g r ) ! = 0   t h e n 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | '   ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         - -   m o d i f i c a r e   q u i   i n   b a s e   a   i n d i c a z i o n i   d i   F l o r i a n a   c o n   n - i n s e r t   d i v e r s e 
 
         - -   p r e v i s i o n e   q u e l l i   c o n   u s a t o _ p e r _ f p v = t r u e 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   P r e v i s i o n e   s c e l t i   c o m e   F P V . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       c r o n o p . u s a t o _ p e r _ f p v = t r u e 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       t i p o A p e r t u r a = p _ f a s e 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . P r e v i s i o n e   s c e l t i   c o m e   F P V .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
         - -   g e s t i o n e       q u e l l i   c o n   p r o v   d e f i n i t i v o 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   G e s t i o n e   c o n   p r o v v e d i m e n t o   d e f i n i t i v o . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o , 
 
                   s i a c _ r _ c r o n o p _ a t t o _ a m m   r a t t o , s i a c _ r _ a t t o _ a m m _ s t a t o   r s a t t o , s i a c _ d _ a t t o _ a m m _ s t a t o   s t a t o a t t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
 - -         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       c r o n o p . b i l _ i d = f a s e . b i l _ i d 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       r a t t o . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       r s a t t o . a t t o a m m _ i d = r a t t o . a t t o a m m _ i d 
 
         a n d       s t a t o a t t o . a t t o a m m _ s t a t o _ i d = r s a t t o . a t t o a m m _ s t a t o _ i d 
 
         a n d       s t a t o a t t o . a t t o a m m _ s t a t o _ c o d e = ' D E F I N I T I V O ' 
 
         a n d       t i p o A p e r t u r a = g _ f a s e 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r a t t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r s a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s a t t o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . G e s t i o n e   c o n   p r o v v e d i m e n t o   d e f i n i t i v o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
         - -   g e s t i o n e       q u e l l i   c o n   i m p e g n o   c o l l e g a t o   (   s e   n o n   n e   h o   g i a ' '   r i b a l t a t i   c o n   p r o v   d e f   ) 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   G e s t i o n e   c o n   i m p e g n o   c o l l e g a t o . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
 - -         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       c r o n o p . b i l _ i d = f a s e . b i l _ i d 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       t i p o A p e r t u r a = g _ f a s e 
 
         a n d       e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   s i a c _ t _ c r o n o p _ e l e m   c e l e m , s i a c _ r _ m o v g e s t _ t s _ c r o n o p _ e l e m   r m o v 
 
         w h e r e   c e l e m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c e l e m . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       r m o v . c r o n o p _ e l e m _ i d = c e l e m . c r o n o p _ e l e m _ i d 
 
         a n d       c e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   f a s e _ b i l _ t _ c r o n o p   f a s e 1 
 
         w h e r e   f a s e 1 . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       f a s e 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       f a s e 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         ) 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . G e s t i o n e   c o n   i m p e g n o   c o l l e g a t o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
         - -   p r e v i s i o n e / g e s t i o n e   q u e l l i   n o n   a n n u l l a t i   (   u l t i m o   c r o n o p   a g g i o r n a t o   )   s e   n o n   n e   h o   g i a ' '   r i b a l t a t o   p r i m a 
 
 	 c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p .   U l t i m o   c r o n o p   a g g i o r n a t o . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ c r o n o p 
 
         ( 
 
 	         f a s e _ b i l _ e l a b _ i d , 
 
 	         f a s e _ b i l _ c r o n o p _ a p e _ t i p o , 
 
 	 	 c r o n o p _ i d , 
 
 	 	 p r o g r a m m a _ i d , 
 
 	         b i l _ i d , 
 
                 l o g i n _ o p e r a z i o n e , 
 
       	         e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   f a s e . f a s e _ b i l _ e l a b _ i d , 
 
                       t i p o A p e r t u r a , 
 
                       c r o n o p . c r o n o p _ i d , 
 
                       c r o n o p . p r o g r a m m a _ i d , 
 
                       c r o n o p . b i l _ i d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c r o n o p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   f a s e _ b i l _ t _ p r o g r a m m i   f a s e , s i a c _ t _ c r o n o p   c r o n o p , s i a c _ r _ c r o n o p _ s t a t o   r s , s i a c _ d _ c r o n o p _ s t a t o   s t a t o 
 
         w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       c r o n o p . p r o g r a m m a _ i d = f a s e . p r o g r a m m a _ i d 
 
 - -         a n d       c r o n o p . b i l _ i d = b i l a n c i o E l a b I d 
 
         a n d       c r o n o p . b i l _ i d = f a s e . b i l _ i d 
 
         a n d       r s . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ i d = r s . c r o n o p _ s t a t o _ i d 
 
         a n d       s t a t o . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   f a s e _ b i l _ t _ c r o n o p   f a s e 1 
 
         w h e r e   f a s e 1 . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d 
 
         a n d       f a s e 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
         a n d       f a s e 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         ) 
 
         a n d       e x i s t s 
 
 	 ( 
 
             s e l e c t   1 
 
             f r o m   s i a c _ t _ c r o n o p   c 1 
 
             w h e r e   c 1 . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       c 1 . c r o n o p _ i d = c r o n o p . c r o n o p _ i d 
 
             a n d       c 1 . d a t a _ m o d i f i c a = 
 
             ( 
 
                 s e l e c t   m a x ( c m a x . d a t a _ m o d i f i c a ) 
 
                 f r o m   s i a c _ t _ c r o n o p   c m a x , s i a c _ r _ c r o n o p _ s t a t o   r s m a x , s i a c _ d _ c r o n o p _ s t a t o   s t m a x 
 
                 w h e r e   c m a x . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       c m a x . p r o g r a m m a _ i d = c 1 . p r o g r a m m a _ i d 
 
                 a n d       c m a x . b i l _ i d = c 1 . b i l _ i d 
 
                 a n d       r s m a x . c r o n o p _ i d = c m a x . c r o n o p _ i d 
 
                 a n d       s t m a x . c r o n o p _ s t a t o _ i d = r s m a x . c r o n o p _ s t a t o _ i d 
 
                 a n d       s t m a x . c r o n o p _ s t a t o _ c o d e ! = S T A T O _ A N 
 
                 a n d       c m a x . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       c m a x . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d       r s m a x . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       r s m a x . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) 
 
             a n d       c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	     a n d       c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c r o n o p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c r o n o p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	         n u m e r o C r o n o p : = n u m e r o C r o n o p + c o d R e s u l t ; 
 
         e n d   i f ; 
 
 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p . U l t i m o   c r o n o p   a g g i o r n a t o .   n u m e r o = ' | | c o d R e s u l t : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   c r o n o - p r o g r a m m i   i n   f a s e _ b i l _ t _ c r o n o p   n u m e r o = ' | | n u m e r o C r o n o p : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - ' | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
       e n d   i f ; 
 
       r a i s e   n o t i c e   ' P r o g r a m m m i   i n s e r i t i   i n   f a s e _ b i l _ t _ p r o g r a m m i = % ' , n u m e r o P r o g r ; 
 
       r a i s e   n o t i c e   ' C r o n o P r o g r a m m m i   i n s e r i t i   i n   f a s e _ b i l _ t _ c r o n o p = % ' , n u m e r o C r o n o p ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   s t a t o   f a s e   b i l a n c i o   I N - 1 . ' ; 
 
       u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e   f a s e 
 
       s e t   f a s e _ b i l _ e l a b _ e s i t o = ' I N - 1 ' , 
 
               f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | '   I N   C O R S O   I N - 1 . P O P O L A   P R O G R A M M I - C R O N O P . ' 
 
       w h e r e   f a s e . f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' I n s e r i m e n t o   L O G . ' ; 
 
       c o d R e s u l t : = n u l l ; 
 
       i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
       ) 
 
       v a l u e s 
 
       ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | ' - F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
       e n d   i f ; 
 
 
 
 
 
       i f   c o d i c e R i s u l t a t o = 0   t h e n 
 
         	 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | ' -   F I N E . ' ; 
 
       e l s e   m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
       e n d   i f ; 
 
 
 
       r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E R R O R E   : ' | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
 	 	 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r M e s s a g g i o F i n a l e , s t r M e s s a g g i o , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | ' E r r o r e   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
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