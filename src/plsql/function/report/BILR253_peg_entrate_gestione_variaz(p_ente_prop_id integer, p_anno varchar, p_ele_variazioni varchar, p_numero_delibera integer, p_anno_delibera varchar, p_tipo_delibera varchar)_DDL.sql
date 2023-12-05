/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


��/ * 
 
 * S P D X - F i l e C o p y r i g h t T e x t :   C o p y r i g h t   2 0 2 0   |   C S I   P I E M O N T E 
 
 * S P D X - L i c e n s e - I d e n t i f i e r :   E U P L - 1 . 2 
 
 * / 
 
 C R E A T E   O R   R E P L A C E   F U N C T I O N   s i a c . " B I L R 2 5 3 _ p e g _ e n t r a t e _ g e s t i o n e _ v a r i a z "   ( 
 
     p _ e n t e _ p r o p _ i d   i n t e g e r , 
 
     p _ a n n o   v a r c h a r , 
 
     p _ e l e _ v a r i a z i o n i   v a r c h a r , 
 
     p _ n u m e r o _ d e l i b e r a   i n t e g e r , 
 
     p _ a n n o _ d e l i b e r a   v a r c h a r , 
 
     p _ t i p o _ d e l i b e r a   v a r c h a r 
 
 ) 
 
 R E T U R N S   T A B L E   ( 
 
     b i l _ a n n o   v a r c h a r , 
 
     t i t o l o e _ t i p o _ c o d e   v a r c h a r , 
 
     t i t o l o e _ t i p o _ d e s c   v a r c h a r , 
 
     t i t o l o e _ c o d e   v a r c h a r , 
 
     t i t o l o e _ d e s c   v a r c h a r , 
 
     t i p o l o g i a _ t i p o _ c o d e   v a r c h a r , 
 
     t i p o l o g i a _ t i p o _ d e s c   v a r c h a r , 
 
     t i p o l o g i a _ c o d e   v a r c h a r , 
 
     t i p o l o g i a _ d e s c   v a r c h a r , 
 
     c a t e g o r i a _ t i p o _ c o d e   v a r c h a r , 
 
     c a t e g o r i a _ t i p o _ d e s c   v a r c h a r , 
 
     c a t e g o r i a _ c o d e   v a r c h a r , 
 
     c a t e g o r i a _ d e s c   v a r c h a r , 
 
     b i l _ e l e _ c o d e   v a r c h a r , 
 
     b i l _ e l e _ d e s c   v a r c h a r , 
 
     b i l _ e l e _ c o d e 2   v a r c h a r , 
 
     b i l _ e l e _ d e s c 2   v a r c h a r , 
 
     b i l _ e l e _ i d   i n t e g e r , 
 
     b i l _ e l e _ i d _ p a d r e   i n t e g e r , 
 
     s t a n z i a m e n t o _ p r e v _ c a s s a _ a n n o   n u m e r i c , 
 
     s t a n z i a m e n t o _ p r e v _ a n n o   n u m e r i c , 
 
     s t a n z i a m e n t o _ p r e v _ a n n o 1   n u m e r i c , 
 
     s t a n z i a m e n t o _ p r e v _ a n n o 2   n u m e r i c , 
 
     r e s i d u i _ p r e s u n t i   n u m e r i c , 
 
     p r e v i s i o n i _ a n n o _ p r e c   n u m e r i c , 
 
     n u m _ c a p _ o l d   v a r c h a r , 
 
     n u m _ a r t _ o l d   v a r c h a r , 
 
     u p b   v a r c h a r , 
 
     d i s p l a y _ e r r o r   v a r c h a r 
 
 )   A S 
 
 $ b o d y $ 
 
 D E C L A R E 
 
 
 
 a n n o C a p I m p   v a r c h a r ; 
 
 a n n o C a p I m p 1   v a r c h a r ; 
 
 a n n o C a p I m p 2   v a r c h a r ; 
 
 t i p o I m p C o m p   v a r c h a r ; 
 
 t i p o I m p C a s s a   v a r c h a r ; 
 
 T i p o I m p r e s i d u i   v a r c h a r ; 
 
 T i p o I m p s t a n z r e s i d u i   v a r c h a r ; 
 
 e l e m T i p o C o d e   v a r c h a r ; 
 
 D E F _ N U L L 	 c o n s t a n t   v a r c h a r : = ' ' ;   
 
 R T N _ M E S S A G G I O   v a r c h a r ( 1 0 0 0 ) : = D E F _ N U L L ; 
 
 u s e r _ t a b l e 	 v a r c h a r ; 
 
 v _ f a m _ t i t o l o t i p o l o g i a c a t e g o r i a   v a r c h a r : = ' 0 0 0 0 3 ' ; 
 
 b i l _ e l e m _ i d   i n t e g e r ; 
 
 s t r Q u e r y   v a r c h a r ; 
 
 x _ a r r a y   V A R C H A R   [ ] ; 
 
 i n t A p p   i n t e g e r ; 
 
 s t r A p p   v a r c h a r ; 
 
 c o n t a P a r V a r B i l   i n t e g e r ; 
 
 
 
 B E G I N 
 
 
 
 / *   0 8 / 0 6 / 2 0 2 1   S I A C - 7 7 9 0 . 
 
 	 Q u e s t a   P r o c e d u r a   n a s c e   c o m e   c o p i a   d e l l a   p r o c e d u r a   B I L R 0 7 7 _ p e g _ e n t r a t e _ g e s t i o n e . 
 
         E '   s t a t a   r i v i s t a   p e r   m o t i v i   p r e s t a z i o n a l i   e   s o n o   s t a t i   a g g i u n t i   i   
 
         p a r a m e t r i   p e r   l a   g e s t i o n e   d e l l e   v a r i a z i o n i ,   i n   q u a n t o   l a   j i r a   S I A C - 7 7 9 0 
 
         p r e v e d e   l a   c r e a z i o n e   d i   u n   r e p o r t   i d e n t i c o   a   B I L R 0 7 7 / B I L 0 8 1   m a   c h e 
 
         t e n g a   c o n t o   i n   m o d o   o p z i o n a l e   i   d a t i   d e l l e   v a r i a z i o n i   i n   b o z z a . 
 
 * / 
 
 
 
 a n n o C a p I m p : =   p _ a n n o ;   
 
 a n n o C a p I m p 1 : =   ( ( p _ a n n o : : I N T E G E R ) + 1 ) : : V A R C H A R ;       
 
 a n n o C a p I m p 2 : =   ( ( p _ a n n o : : I N T E G E R ) + 2 ) : : V A R C H A R ;   
 
 
 
 T i p o I m p C o m p = ' S T A ' ;     - -   c o m p e t e n z a 
 
 T i p o I m p r e s i d u i = ' S T R ' ;   - -   r e s i d u i 
 
 T i p o I m p s t a n z r e s i d u i = ' S T I ' ;   - -   s t a n z i a m e n t o   r e s i d u o 
 
 T i p o I m p C a s s a   = ' S C A ' ;   - - - - -   p r e v i s i o n i   d i   c a s s a 
 
 e l e m T i p o C o d e : = ' C A P - E G ' ;   - -   t i p o   c a p i t o l o   G e s t i o n e 
 
 
 
 b i l _ a n n o = ' ' ; 
 
 t i t o l o e _ t i p o _ c o d e = ' ' ; 
 
 t i t o l o e _ T I P O _ D E S C = ' ' ; 
 
 t i t o l o e _ C O D E = ' ' ; 
 
 t i t o l o e _ D E S C = ' ' ; 
 
 t i p o l o g i a _ t i p o _ c o d e = ' ' ; 
 
 t i p o l o g i a _ t i p o _ d e s c = ' ' ; 
 
 t i p o l o g i a _ c o d e = ' ' ; 
 
 t i p o l o g i a _ d e s c = ' ' ; 
 
 c a t e g o r i a _ t i p o _ c o d e = ' ' ; 
 
 c a t e g o r i a _ t i p o _ d e s c = ' ' ; 
 
 c a t e g o r i a _ c o d e = ' ' ; 
 
 c a t e g o r i a _ d e s c = ' ' ; 
 
 b i l _ e l e _ c o d e = ' ' ; 
 
 b i l _ e l e _ d e s c = ' ' ; 
 
 b i l _ e l e _ c o d e 2 = ' ' ; 
 
 b i l _ e l e _ d e s c 2 = ' ' ; 
 
 b i l _ e l e _ i d = 0 ; 
 
 b i l _ e l e _ i d _ p a d r e = 0 ; 
 
 s t a n z i a m e n t o _ p r e v _ a n n o = 0 ; 
 
 s t a n z i a m e n t o _ p r e v _ a n n o 1 = 0 ; 
 
 s t a n z i a m e n t o _ p r e v _ a n n o 2 = 0 ; 
 
 r e s i d u i _ p r e s u n t i : = 0 ; 
 
 p r e v i s i o n i _ a n n o _ p r e c : = 0 ; 
 
 s t a n z i a m e n t o _ p r e v _ c a s s a _ a n n o : = 0 ; 
 
 n u m _ c a p _ o l d = ' ' ; 
 
 n u m _ a r t _ o l d = ' ' ; 
 
 u p b = ' ' ; 
 
 
 
 c o n t a P a r V a r B i l : = 0 ; 
 
 
 
 - -   s e   e '   p r e s e n t e   i l   p a r a m e t r o   c o n   l ' e l e n c o   d e l l e   v a r i a z i o n i   v e r i f i c o   c h e   a b b i a 
 
 - -   s o l o   d e i   n u m e r i   o l t r e   l e   v i r g o l e . 
 
 I F   p _ e l e _ v a r i a z i o n i   I S   N O T   N U L L   A N D   p _ e l e _ v a r i a z i o n i   < >   ' '   T H E N 
 
     x _ a r r a y   =   s t r i n g _ t o _ a r r a y ( p _ e l e _ v a r i a z i o n i ,   ' , ' ) ; 
 
     f o r e a c h   s t r A p p   i n   A R R A Y   x _ a r r a y 
 
     L O O P 
 
         i n t A p p   =   s t r A p p : : I N T E G E R ; 
 
     E N D   L O O P ; 
 
 E N D   I F ; 
 
 
 
 i f   p _ n u m e r o _ d e l i b e r a   I S   N O T     N U L L   T H E N 
 
 	 c o n t a P a r V a r B i l = c o n t a P a r V a r B i l + 1 ; 
 
 e n d   i f ; 
 
 i f   p _ a n n o _ d e l i b e r a   I S   N O T     N U L L   A N D   p _ a n n o _ d e l i b e r a   < >   ' '   T H E N 
 
 	 c o n t a P a r V a r B i l = c o n t a P a r V a r B i l + 1 ; 
 
 e n d   i f ; 
 
 i f   p _ t i p o _ d e l i b e r a   I S   N O T     N U L L   A N D   p _ t i p o _ d e l i b e r a   < >   ' '   T H E N 
 
 	 c o n t a P a r V a r B i l = c o n t a P a r V a r B i l + 1 ; 
 
 e n d   i f ; 
 
 i f   c o n t a P a r V a r B i l   n o t   i n   ( 0 , 3 )   t h e n 
 
 	 d i s p l a y _ e r r o r = ' O C C O R R E   S P E C I F I C A R E   T U T T I   E   3   I   V A L O R I   P E R   I L   P A R A M E T R O   ' ' P r o v v e d i m e n t o   d i   v a r i a z i o n e ' ' ' ; 
 
         r e t u r n   n e x t ; 
 
         r e t u r n ;                 
 
 e n d   i f ; 
 
 
 
 i f   c o n t a P a r V a r B i l   =   3   a n d   ( p _ e l e _ v a r i a z i o n i   I S   N O T   N U L L   
 
 	 A N D   p _ e l e _ v a r i a z i o n i   < >   ' ' )   t h e n 
 
 	 d i s p l a y _ e r r o r = ' S p e c i f i c a r e   u n o   s o l o   t r a   i   p a r a m e t r i   ' ' E l e n c o   n u m e r i   V a r i a z i o n e ' '   e   ' ' P r o v v e d i m e n t o   d i   v a r i a z i o n e ' ' ' ; 
 
         r e t u r n   n e x t ; 
 
         r e t u r n ;                 
 
 e n d   i f ;     
 
 
 
 s t r Q u e r y : = ' ' ; 
 
 
 
 / * 
 
 I F   ( p _ e l e _ v a r i a z i o n i   I S     N U L L   O R   p _ e l e _ v a r i a z i o n i   =   ' ' )   A N D 
 
 	 c o n t a P a r V a r B i l   =   0   A N D 
 
         ( p _ t i p o _ v a r   I S   N U L L   O R   p _ t i p o _ v a r   =   ' ' )   T H E N 
 
         d i s p l a y _ e r r o r = ' O C C O R R E   S P E C I F I C A R E   A L M E N O   1   P A R A M E T R O   R E L A T I V O   A L L E   V A R I A Z I O N I ' ; 
 
         r e t u r n   n e x t ; 
 
         r e t u r n ;     
 
         
 
 e n d   i f ; * / 
 
 
 
 s e l e c t   f n c _ s i a c _ r a n d o m _ u s e r ( ) 
 
 i n t o 	 u s e r _ t a b l e ; 
 
 
 
 
 
 s e l e c t   b i l . b i l _ i d 
 
 	 i n t o   b i l _ e l e m _ i d 
 
 f r o m   s i a c _ t _ b i l   b i l , 
 
 	 s i a c _ t _ p e r i o d o   p e r 
 
 w h e r e   b i l . p e r i o d o _ i d = p e r . p e r i o d o _ i d 
 
 	 a n d   b i l . e n t e _ p r o p r i e t a r i o _ i d = p _ e n t e _ p r o p _ i d 
 
         a n d   p e r . a n n o = p _ a n n o 
 
         a n d   b i l . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
         a n d   p e r . d a t a _ c a n c e l l a z i o n e   I S   N U L L ; 
 
         
 
 
 
 - - p r e p a r o   l a   p a r t e   d e l l a   q u e r y   r e l a t i v a   a l l e   v a r i a z i o n i . 	 
 
 i f   p _ n u m e r o _ d e l i b e r a   i s   n o t   n u l l   T H E N                 
 
         i n s e r t   i n t o   s i a c _ r e p _ v a r _ e n t r a t e         
 
         s e l e c t 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d , 
 
                         s u m ( d e t t a g l i o _ v a r i a z i o n e . e l e m _ d e t _ i m p o r t o ) ,                 
 
                         t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e ,   
 
                         u s e r _ t a b l e   u t e n t e , 
 
                         a t t o . e n t e _ p r o p r i e t a r i o _ i d ,   a n n o _ i m p o r t i . a n n o 	             	 
 
         f r o m   	 s i a c _ t _ a t t o _ a m m   	 	 	 a t t o , 
 
                         s i a c _ d _ a t t o _ a m m _ t i p o 	 	 t i p o _ a t t o , 
 
                         s i a c _ r _ a t t o _ a m m _ s t a t o   	 	 r _ a t t o _ s t a t o , 
 
                         s i a c _ d _ a t t o _ a m m _ s t a t o   	 	 s t a t o _ a t t o , 
 
                         s i a c _ r _ v a r i a z i o n e _ s t a t o 	 	 r _ v a r i a z i o n e _ s t a t o , 
 
                         s i a c _ t _ v a r i a z i o n e   	 	 	 t e s t a t a _ v a r i a z i o n e , 
 
                         s i a c _ d _ v a r i a z i o n e _ t i p o 	 	 t i p o l o g i a _ v a r i a z i o n e , 
 
                         s i a c _ d _ v a r i a z i o n e _ s t a t o   	 t i p o l o g i a _ s t a t o _ v a r , 
 
                         s i a c _ t _ b i l _ e l e m _ d e t _ v a r   	 d e t t a g l i o _ v a r i a z i o n e , 
 
                         s i a c _ t _ b i l _ e l e m 	 	 	 	 c a p i t o l o , 
 
                         s i a c _ d _ b i l _ e l e m _ t i p o   	 	 t i p o _ c a p i t o l o , 
 
                         s i a c _ d _ b i l _ e l e m _ d e t _ t i p o 	 t i p o _ e l e m e n t o , 
 
                         s i a c _ t _ p e r i o d o   	 	 	 	 a n n o _ e s e r c   , 
 
                         s i a c _ t _ b i l 	 	 	 	 	 t _ b i l , 
 
                         s i a c _ t _ p e r i o d o   	 	 	 	 a n n o _ i m p o r t i 
 
         w h e r e   	 a t t o . a t t o a m m _ t i p o _ i d 	 	 	 	 	 	 	 	 = 	 t i p o _ a t t o . a t t o a m m _ t i p o _ i d 
 
         a n d 	 	 r _ a t t o _ s t a t o . a t t o a m m _ i d 	 	 	 	 	 	 	 	 = 	 a t t o . a t t o a m m _ i d 
 
         a n d 	 	 r _ a t t o _ s t a t o . a t t o a m m _ s t a t o _ i d 	 	 	 	 	 	 = 	 s t a t o _ a t t o . a t t o a m m _ s t a t o _ i d 
 
         a n d 	 	 (   r _ v a r i a z i o n e _ s t a t o . a t t o a m m _ i d 	 	 	 	 	 	 = 	 a t t o . a t t o a m m _ i d   o r 
 
                                 r _ v a r i a z i o n e _ s t a t o . a t t o a m m _ i d _ v a r b i l       	 	 	 	 = 	 a t t o . a t t o a m m _ i d   ) 
 
         a n d 	 	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ i d 	 	 	 	 	 = 	 t e s t a t a _ v a r i a z i o n e . v a r i a z i o n e _ i d 
 
         a n d 	 	 t e s t a t a _ v a r i a z i o n e . v a r i a z i o n e _ t i p o _ i d 	 	 	 	 = 	 t i p o l o g i a _ v a r i a z i o n e . v a r i a z i o n e _ t i p o _ i d 	 
 
         a n d   	 t i p o l o g i a _ s t a t o _ v a r . v a r i a z i o n e _ s t a t o _ t i p o _ i d 	 	 = 	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ s t a t o _ t i p o _ i d 
 
         a n d 	 	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ s t a t o _ i d 	 	 	 	 = 	 d e t t a g l i o _ v a r i a z i o n e . v a r i a z i o n e _ s t a t o _ i d 
 
         a n d 	 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d 	 	 	 	 	 	 = 	 c a p i t o l o . e l e m _ i d 
 
         a n d 	 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 	 	 	 	 = 	 t i p o _ c a p i t o l o . e l e m _ t i p o _ i d 
 
         a n d 	 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ d e t _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ i d 
 
         a n d   	 t _ b i l . p e r i o d o _ i d   	 	 	 	 	 	 	 	 	 = 	 a n n o _ e s e r c . p e r i o d o _ i d 	 	 
 
         a n d   	 t _ b i l . b i l _ i d   	 	 	 	 	 	 	 	 	 	 =   t e s t a t a _ v a r i a z i o n e . b i l _ i d 
 
         a n d 	 	 a n n o _ i m p o r t i . p e r i o d o _ i d   	 	 	 	 	 	 	 = 	 d e t t a g l i o _ v a r i a z i o n e . p e r i o d o _ i d 	 
 
         a n d   	 a t t o . e n t e _ p r o p r i e t a r i o _ i d   	 	 	 	 	 	 	 =   	 p _ e n t e _ p r o p _ i d   
 
         a n d 	 	 a n n o _ e s e r c . a n n o 	 	 	 	 	 	 	 	 	 	 =   	 p _ a n n o 	 	 	 	   	 
 
         a n d 	 	 a t t o . a t t o a m m _ n u m e r o   	 	 	 	 	 	 	 	 =   	 p _ n u m e r o _ d e l i b e r a 
 
         a n d 	 	 a t t o . a t t o a m m _ a n n o 	 	 	 	 	 	 	 	 	 = 	 p _ a n n o _ d e l i b e r a 
 
         a n d 	 	 t i p o _ a t t o . a t t o a m m _ t i p o _ c o d e 	 	 	 	 	 	 	 = 	 p _ t i p o _ d e l i b e r a 
 
         a n d 	 	 s t a t o _ a t t o . a t t o a m m _ s t a t o _ c o d e 	 	 	 	 	 	 = 	 ' D E F I N I T I V O ' 	 	 	 	 	 	 	 	 	 	 
 
         - - 1 0 / 1 0 / 2 0 2 2   S I A C - 8 8 2 7     A g g i u n t o   l o   s t a t o   B D . 
 
         a n d 	 	 t i p o l o g i a _ s t a t o _ v a r . v a r i a z i o n e _ s t a t o _ t i p o _ c o d e 	 	   i n 	 ( ' B ' , ' G ' ,   ' C ' ,   ' P ' ,   ' B D ' ) 
 
         a n d 	 	 t i p o _ c a p i t o l o . e l e m _ t i p o _ c o d e 	 	 	 	 	 	 = 	 e l e m T i p o C o d e 
 
         a n d 	 	 t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e 	 	 	 	 	 i n   ( ' S T A ' , ' S C A ' , ' S T R ' ) 
 
         a n d 	 	 a t t o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 	 	 i s   n u l l 
 
         a n d 	 	 t i p o _ a t t o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 i s   n u l l 
 
         a n d 	 	 r _ a t t o _ s t a t o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 i s   n u l l 
 
         a n d 	 	 s t a t o _ a t t o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 i s   n u l l 
 
         a n d 	 	 r _ v a r i a z i o n e _ s t a t o . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
         a n d 	 	 t e s t a t a _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
         a n d 	 	 t i p o l o g i a _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
         a n d 	 	 t i p o l o g i a _ s t a t o _ v a r . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
         a n d   	 d e t t a g l i o _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
         a n d   	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 	 i s   n u l l 
 
         a n d 	 	 t i p o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 	 	 i s   n u l l 
 
         a n d 	 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e 	 	 	 i s   n u l l 
 
         a n d 	 	 t _ b i l . d a t a _ c a n c e l l a z i o n e 	 	 	 	 	 i s   n u l l 
 
         g r o u p   b y   	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d , 
 
                                 t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e ,   
 
                                 u t e n t e , 
 
                                 a t t o . e n t e _ p r o p r i e t a r i o _ i d ,   a n n o _ i m p o r t i . a n n o ; 
 
 E L S E     - - s p e c i f i c a t a   l a   v a r i a z i o n e 
 
 	 i f   p _ e l e _ v a r i a z i o n i   i s   n o t   n u l l   a n d   p _ e l e _ v a r i a z i o n i   < > ' '   t h e n 
 
             s t r Q u e r y : =   ' 
 
             i n s e r t   i n t o   s i a c _ r e p _ v a r _ e n t r a t e 
 
             s e l e c t 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d , 
 
                     s u m ( d e t t a g l i o _ v a r i a z i o n e . e l e m _ d e t _ i m p o r t o ) ,                 
 
                     t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e ,   
 
                     ' ' ' | | u s e r _ t a b l e | | ' ' '   u t e n t e , 
 
                     t e s t a t a _ v a r i a z i o n e . e n t e _ p r o p r i e t a r i o _ i d ,   a n n o _ i m p o r t i . a n n o   	             	 
 
                     f r o m   	 s i a c _ r _ v a r i a z i o n e _ s t a t o 	 	 r _ v a r i a z i o n e _ s t a t o , 
 
                                     s i a c _ t _ v a r i a z i o n e   	 	 	 t e s t a t a _ v a r i a z i o n e , 
 
                                     s i a c _ d _ v a r i a z i o n e _ t i p o 	 	 t i p o l o g i a _ v a r i a z i o n e , 
 
                                     s i a c _ d _ v a r i a z i o n e _ s t a t o   	 t i p o l o g i a _ s t a t o _ v a r , 
 
                                     s i a c _ t _ b i l _ e l e m _ d e t _ v a r   	 d e t t a g l i o _ v a r i a z i o n e , 
 
                                     s i a c _ t _ b i l _ e l e m 	 	 	 	 c a p i t o l o , 
 
                                     s i a c _ d _ b i l _ e l e m _ t i p o   	 	 t i p o _ c a p i t o l o , 
 
                                     s i a c _ d _ b i l _ e l e m _ d e t _ t i p o 	 t i p o _ e l e m e n t o , 
 
                                     s i a c _ t _ p e r i o d o   	 	 	 	 a n n o _ e s e r c   , 
 
                                     s i a c _ t _ b i l 	 	 	 	 	 t _ b i l , 
 
                                     s i a c _ t _ p e r i o d o   	 	 	 	 a n n o _ i m p o r t i 
 
                     w h e r e   	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ i d 	 	 	 	 	 = 	 t e s t a t a _ v a r i a z i o n e . v a r i a z i o n e _ i d 
 
                     a n d 	 	 t e s t a t a _ v a r i a z i o n e . v a r i a z i o n e _ t i p o _ i d 	 	 	 	 = 	 t i p o l o g i a _ v a r i a z i o n e . v a r i a z i o n e _ t i p o _ i d 	 
 
                     a n d   	 t i p o l o g i a _ s t a t o _ v a r . v a r i a z i o n e _ s t a t o _ t i p o _ i d 	 	 = 	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ s t a t o _ t i p o _ i d 
 
                     a n d 	 	 r _ v a r i a z i o n e _ s t a t o . v a r i a z i o n e _ s t a t o _ i d 	 	 	 	 = 	 d e t t a g l i o _ v a r i a z i o n e . v a r i a z i o n e _ s t a t o _ i d 
 
                     a n d 	 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d 	 	 	 	 	 	 = 	 c a p i t o l o . e l e m _ i d 
 
                     a n d 	 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 	 	 	 	 = 	 t i p o _ c a p i t o l o . e l e m _ t i p o _ i d 
 
                     a n d 	 	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ d e t _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ i d 
 
                     a n d   	 t _ b i l . p e r i o d o _ i d   	 	 	 	 	 	 	 	 	 = 	 a n n o _ e s e r c . p e r i o d o _ i d 	 	 
 
                     a n d   	 t _ b i l . b i l _ i d   	 	 	 	 	 	 	 	 	 	 =   t e s t a t a _ v a r i a z i o n e . b i l _ i d 
 
                     a n d 	 	 a n n o _ i m p o r t i . p e r i o d o _ i d   	 	 	 	 	 	 	 = 	 d e t t a g l i o _ v a r i a z i o n e . p e r i o d o _ i d 	 
 
                     a n d   	 t e s t a t a _ v a r i a z i o n e . e n t e _ p r o p r i e t a r i o _ i d   	 	 	 =   	 ' | | p _ e n t e _ p r o p _ i d   | | ' 
 
                     a n d 	 	 a n n o _ e s e r c . a n n o 	 	 	 	 	 	 	 	 	 	 =   	 ' ' ' | | p _ a n n o | | ' ' '   
 
                     a n d   	 t e s t a t a _ v a r i a z i o n e . v a r i a z i o n e _ n u m   	 	 	 	 	 i n   ( ' | | p _ e l e _ v a r i a z i o n i | | ' )     	 	 	 	 	 	 	 	 	 
 
                     - - 1 0 / 1 0 / 2 0 2 2   S I A C - 8 8 2 7     A g g i u n t o   l o   s t a t o   B D . 
 
                     a n d 	 	 t i p o l o g i a _ s t a t o _ v a r . v a r i a z i o n e _ s t a t o _ t i p o _ c o d e 	   i n 	 ( ' ' B ' ' , ' ' G ' ' ,   ' ' C ' ' ,   ' ' P ' ' ,   ' ' B D ' ' )   
 
                     a n d 	 	 t i p o _ c a p i t o l o . e l e m _ t i p o _ c o d e 	 	 	 	 	 	 = 	 ' ' ' | | e l e m T i p o C o d e | | ' ' ' 
 
                     a n d 	 	 t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e 	 	 	 	 	 i n   ( ' ' S T A ' ' , ' ' S C A ' ' , ' ' S T R ' ' ) 
 
                     a n d 	 	 r _ v a r i a z i o n e _ s t a t o . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
                     a n d 	 	 t e s t a t a _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
                     a n d 	 	 t i p o l o g i a _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
                     a n d 	 	 t i p o l o g i a _ s t a t o _ v a r . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
                     a n d   	 d e t t a g l i o _ v a r i a z i o n e . d a t a _ c a n c e l l a z i o n e 	 	 i s   n u l l 
 
                     a n d   	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 	 	 	 	 i s   n u l l 
 
                     a n d 	 	 t i p o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 	 	 i s   n u l l 
 
                     a n d 	 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e 	 	 	 i s   n u l l 
 
                     a n d 	 	 t _ b i l . d a t a _ c a n c e l l a z i o n e 	 	 	 	 	 i s   n u l l 
 
                     g r o u p   b y   	 d e t t a g l i o _ v a r i a z i o n e . e l e m _ i d , 
 
                                             t i p o _ e l e m e n t o . e l e m _ d e t _ t i p o _ c o d e ,   
 
                                             u t e n t e , 
 
                                             t e s t a t a _ v a r i a z i o n e . e n t e _ p r o p r i e t a r i o _ i d ,   a n n o _ i m p o r t i . a n n o ' ;                                         
 
 
 
             r a i s e   n o t i c e   ' Q u e r y   v a r i a z i o n i   =   % ' ,   s t r Q u e r y ; 
 
             e x e c u t e     s t r Q u e r y ; 	 
 
         e n d   i f ; 
 
 e n d   i f ; 
 
         
 
 
 
 r e t u r n   q u e r y 
 
 w i t h   s t r u t t u r a   a s   ( 
 
 	 s e l e c t   *   f r o m   " f n c _ b i l r _ s t r u t t u r a _ c a p _ b i l a n c i o _ e n t r a t e " ( p _ e n t e _ p r o p _ i d ,   p _ a n n o , ' ' ) ) , 
 
 c a p i t o l i   a s   ( 
 
     s e l e c t   c l . c l a s s i f _ i d   c a t e g o r i a _ i d , 
 
             p _ a n n o   a n n o _ b i l a n c i o , 
 
             c a p i t o l o . * ,   u p b . c l a s s i f _ c o d e   c a p i t o l o _ u p b , 
 
             C O A L E S C E ( c a p _ o l d . n u m _ c a p _ o l d , ' ' )   n u m _ c a p _ o l d ,   
 
             C O A L E S C E ( c a p _ o l d . n u m _ a r t _ o l d , ' ' )   n u m _ a r t _ o l d         
 
       f r o m   	 s i a c _ r _ b i l _ e l e m _ c l a s s   r c , 
 
                     s i a c _ t _ b i l _ e l e m   c a p i t o l o 
 
                             l e f t   j o i n   ( s e l e c t   t _ c l a s s _ u p b . c l a s s i f _ c o d e ,   r _ c a p i t o l o _ u p b . e l e m _ i d 
 
                                                     f r o m   
 
                                                             s i a c _ d _ c l a s s _ t i p o 	 c l a s s _ u p b , 
 
                                                             s i a c _ t _ c l a s s 	 	 t _ c l a s s _ u p b , 
 
                                                             s i a c _ r _ b i l _ e l e m _ c l a s s   r _ c a p i t o l o _ u p b 
 
                                                     w h e r e   t _ c l a s s _ u p b . c l a s s i f _ t i p o _ i d = c l a s s _ u p b . c l a s s i f _ t i p o _ i d   
 
                                                             a n d   t _ c l a s s _ u p b . c l a s s i f _ i d = r _ c a p i t o l o _ u p b . c l a s s i f _ i d 
 
                                                             a n d   t _ c l a s s _ u p b . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d 
 
                                                             a n d   c l a s s _ u p b . c l a s s i f _ t i p o _ c o d e = ' C L A S S I F I C A T O R E _ 3 6 '   	 	 	 	 	 	 	 	 	 
 
                                                             a n d 	 c l a s s _ u p b . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                                                             a n d   t _ c l a s s _ u p b . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                                                             a n d   r _ c a p i t o l o _ u p b . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l )   u p b 
 
                               o n   u p b . e l e m _ i d = c a p i t o l o . e l e m _ i d 
 
                               l e f t   j o i n   ( s e l e c t   r _ b i l _ e l e m _ o l d . e l e m _ i d ,   
 
                                                             c a p . e l e m _ c o d e   n u m _ c a p _ o l d , 
 
                                                             c a p . e l e m _ c o d e 2   n u m _ a r t _ o l d 
 
                                                     f r o m   s i a c _ r _ b i l _ e l e m _ r e l _ t e m p o   r _ b i l _ e l e m _ o l d , 
 
                                                             s i a c _ t _ b i l _ e l e m   c a p 
 
                                                     w h e r e   r _ b i l _ e l e m _ o l d . e l e m _ i d _ o l d = c a p . e l e m _ i d 
 
                                                             a n d   r _ b i l _ e l e m _ o l d . e n t e _ p r o p r i e t a r i o _ i d = p _ e n t e _ p r o p _ i d 
 
                                                             a n d   r _ b i l _ e l e m _ o l d . d a t a _ c a n c e l l a z i o n e   I S   N U L L 
 
                                                             a n d   c a p . d a t a _ c a n c e l l a z i o n e   I S   N U L L )   c a p _ o l d 
 
                                     o n   c a p _ o l d . e l e m _ i d = c a p i t o l o . e l e m _ i d ,                               
 
                     s i a c _ d _ c l a s s _ t i p o   c t , 
 
                     s i a c _ t _ c l a s s   c l , 
 
                     s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o ,   
 
                     s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o , 
 
                     s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                     s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o , 
 
                     s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
     w h e r e   c t . c l a s s i f _ t i p o _ i d 	 	 	 	 = 	 c l . c l a s s i f _ t i p o _ i d 
 
     a n d   c l . c l a s s i f _ i d 	 	 	 	 	 = 	 r c . c l a s s i f _ i d   
 
     a n d   c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   
 
     a n d   c a p i t o l o . e l e m _ i d 	 	 	 	 	 	 = 	 r c . e l e m _ i d   
 
     a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
     a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
     a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
     a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
     a n d   c a p i t o l o . e n t e _ p r o p r i e t a r i o _ i d = p _ e n t e _ p r o p _ i d 
 
     a n d   c a p i t o l o . b i l _ i d 	 	 	 	 	 	 =   b i l _ e l e m _ i d 	 
 
     a n d   c t . c l a s s i f _ t i p o _ c o d e 	 	 	 = 	 ' C A T E G O R I A ' 
 
     a n d   t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 =   	 e l e m T i p o C o d e 
 
     a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 = 	 ' V A ' 
 
     a n d 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 = 	 ' S T D ' 
 
     a n d   c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
     a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e 	 i s   n u l l 
 
     a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 i s   n u l l 
 
     a n d 	 r c . d a t a _ c a n c e l l a z i o n e 	 	 	 	 i s   n u l l 
 
     a n d 	 c t . d a t a _ c a n c e l l a z i o n e   	 	 	 	 i s   n u l l 
 
     a n d 	 c l . d a t a _ c a n c e l l a z i o n e   	 	 	 	 i s   n u l l 
 
     a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e 	 i s   n u l l 
 
     a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
     a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e 	 i s   n u l l 
 
     a n d 	 n o w ( )   b e t w e e n   r c . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r c . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   c t . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c t . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   c l . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c l . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
     a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) ) , 
 
 i m p _ c o m p _ a n n o   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   T i p o I m p C o m p 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) , 
 
 i m p _ c o m p _ a n n o 1   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p 1 ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   T i p o I m p C o m p 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) , 
 
 i m p _ c o m p _ a n n o 2   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p 2 ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   T i p o I m p C o m p 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) , 
 
 i m p _ s t a n z _ r e s i d u i _ a n n o   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   T i p o I m p s t a n z r e s i d u i 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) ,                   
 
   i m p _ r e s i d u i _ a n n o   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   T i p o I m p r e s i d u i 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) , 
 
 i m p _ c a s s a _ a n n o   a s   ( 
 
         s e l e c t   	 	 c a p i t o l o _ i m p o r t i . e l e m _ i d ,                                       
 
                                 s u m ( c a p i t o l o _ i m p o r t i . e l e m _ d e t _ i m p o r t o )   i m p o r t o     
 
         f r o m   	 	 s i a c _ t _ b i l _ e l e m _ d e t   c a p i t o l o _ i m p o r t i , 
 
                                 s i a c _ d _ b i l _ e l e m _ d e t _ t i p o   c a p i t o l o _ i m p _ t i p o , 
 
                                 s i a c _ t _ p e r i o d o   c a p i t o l o _ i m p _ p e r i o d o , 
 
                                 s i a c _ t _ b i l _ e l e m   c a p i t o l o , 
 
                                 s i a c _ d _ b i l _ e l e m _ t i p o   t i p o _ e l e m e n t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ s t a t o   s t a t o _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ s t a t o   r _ c a p i t o l o _ s t a t o , 
 
                                 s i a c _ d _ b i l _ e l e m _ c a t e g o r i a   c a t _ d e l _ c a p i t o l o ,   
 
                                 s i a c _ r _ b i l _ e l e m _ c a t e g o r i a   r _ c a t _ c a p i t o l o 
 
                 w h e r e   c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 c a p i t o l o _ i m p o r t i . e l e m _ i d   
 
                         a n d 	 c a p i t o l o . e l e m _ t i p o _ i d 	 	 	 	 = 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ i d   	 	 	 	 	 	                 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . e l e m _ d e t _ t i p o _ i d 	 = 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ i d   	 	 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . p e r i o d o _ i d 	 	 = 	 c a p i t o l o _ i m p o r t i . p e r i o d o _ i d   	 	 	                     
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a p i t o l o _ s t a t o . e l e m _ i d 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . e l e m _ s t a t o _ i d 	 	 = 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ i d 
 
                         a n d 	 c a p i t o l o . e l e m _ i d 	 	 	 	 	 = 	 r _ c a t _ c a p i t o l o . e l e m _ i d 
 
                         a n d 	 r _ c a t _ c a p i t o l o . e l e m _ c a t _ i d 	 	 	 = 	 c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ i d 
 
                         a n d   c a p i t o l o _ i m p o r t i . e n t e _ p r o p r i e t a r i o _ i d   =   p _ e n t e _ p r o p _ i d   
 
                         a n d 	 c a p i t o l o . b i l _ i d 	 	 	 	 	 	 = 	 b i l _ e l e m _ i d 
 
                         a n d 	 t i p o _ e l e m e n t o . e l e m _ t i p o _ c o d e   	 	 =   	 e l e m T i p o C o d e 
 
                         a n d 	 s t a t o _ c a p i t o l o . e l e m _ s t a t o _ c o d e 	 	 = 	 ' V A ' 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . a n n o   i n   ( a n n o C a p I m p ) 	 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . e l e m _ d e t _ t i p o _ c o d e   =   t i p o I m p C a s s a 
 
                         a n d   c a t _ d e l _ c a p i t o l o . e l e m _ c a t _ c o d e 	 i n   ( ' S T D ' ) 
 
                         a n d 	 c a p i t o l o _ i m p o r t i . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ t i p o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a p i t o l o _ i m p _ p e r i o d o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d 	 c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 	 i s   n u l l 
 
                         a n d 	 t i p o _ e l e m e n t o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 s t a t o _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 r _ c a p i t o l o _ s t a t o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 c a t _ d e l _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 i s   n u l l 
 
                         a n d 	 r _ c a t _ c a p i t o l o . d a t a _ c a n c e l l a z i o n e   	 	 i s   n u l l 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p o r t i . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p o r t i . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ p e r i o d o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a p i t o l o _ i m p _ t i p o . v a l i d i t a _ f i n e ,   n o w ( ) )     
 
                         a n d 	 n o w ( )   b e t w e e n   t i p o _ e l e m e n t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( t i p o _ e l e m e n t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   s t a t o _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( s t a t o _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a p i t o l o _ s t a t o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a p i t o l o _ s t a t o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   c a t _ d e l _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( c a t _ d e l _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                         a n d 	 n o w ( )   b e t w e e n   r _ c a t _ c a p i t o l o . v a l i d i t a _ i n i z i o   a n d   c o a l e s c e   ( r _ c a t _ c a p i t o l o . v a l i d i t a _ f i n e ,   n o w ( ) ) 
 
                 g r o u p   b y   c a p i t o l o _ i m p o r t i . e l e m _ i d ) , 
 
 v a r i a z _ s t a n z _ a n n o   a s   ( s e l e c t   a . e l e m _ i d ,   s u m ( a . i m p o r t o )   i m p o r t o _ v a r 
 
                                     f r o m   s i a c _ r e p _ v a r _ e n t r a t e   a 
 
                                     w h e r e   a . e n t e _ p r o p r i e t a r i o   = p _ e n t e _ p r o p _ i d 
 
                                     a n d   a . t i p o l o g i a = T i p o I m p C o m p   - -   ' ' S T A ' ' 
 
                                     a n d   a . p e r i o d o _ a n n o = a n n o C a p I m p 
 
                                     a n d   a . u t e n t e = u s e r _ t a b l e 
 
                                     g r o u p   b y     a . e l e m _ i d ) ,       
 
   v a r i a z _ s t a n z _ a n n o 1   a s   ( s e l e c t   a . e l e m _ i d ,   s u m ( a . i m p o r t o )   i m p o r t o _ v a r 
 
                                     f r o m   s i a c _ r e p _ v a r _ e n t r a t e   a 
 
                                     w h e r e   a . e n t e _ p r o p r i e t a r i o   = p _ e n t e _ p r o p _ i d 
 
                                     a n d   a . t i p o l o g i a = T i p o I m p C o m p   - -   ' ' S T A ' ' 
 
                                     a n d   a . p e r i o d o _ a n n o = a n n o C a p I m p 1 
 
                                     a n d   a . u t e n t e = u s e r _ t a b l e 
 
                                     g r o u p   b y     a . e l e m _ i d ) ,     
 
   v a r i a z _ s t a n z _ a n n o 2   a s   ( s e l e c t   a . e l e m _ i d ,   s u m ( a . i m p o r t o )   i m p o r t o _ v a r 
 
                                     f r o m   s i a c _ r e p _ v a r _ e n t r a t e   a 
 
                                     w h e r e   a . e n t e _ p r o p r i e t a r i o   = p _ e n t e _ p r o p _ i d 
 
                                     a n d   a . t i p o l o g i a = T i p o I m p C o m p   - -   ' ' S T A ' ' 
 
                                     a n d   a . p e r i o d o _ a n n o = a n n o C a p I m p 2 
 
                                     a n d   a . u t e n t e = u s e r _ t a b l e 
 
                                     g r o u p   b y     a . e l e m _ i d ) ,                                                                             
 
   v a r i a z _ c a s s a   a s   ( s e l e c t   a . e l e m _ i d ,   s u m ( a . i m p o r t o )   i m p o r t o _ v a r 
 
                                     f r o m   s i a c _ r e p _ v a r _ e n t r a t e   a 
 
                                     w h e r e   a . e n t e _ p r o p r i e t a r i o   = p _ e n t e _ p r o p _ i d 
 
                                     a n d   a . t i p o l o g i a = t i p o I m p C a s s a   - -   ' ' S C A ' ' 
 
                                     a n d   a . u t e n t e = u s e r _ t a b l e 
 
                                     g r o u p   b y     a . e l e m _ i d ) ,     
 
   v a r i a z _ r e s i d u i   a s   ( s e l e c t   a . e l e m _ i d ,   s u m ( a . i m p o r t o )   i m p o r t o _ v a r 
 
                                     f r o m   s i a c _ r e p _ v a r _ e n t r a t e   a 
 
                                     w h e r e   a . e n t e _ p r o p r i e t a r i o   = p _ e n t e _ p r o p _ i d 
 
                                     a n d   a . t i p o l o g i a = T i p o I m p r e s i d u i   - -   ' ' S T R ' ' 
 
                                     a n d   a . u t e n t e = u s e r _ t a b l e 
 
                                     g r o u p   b y     a . e l e m _ i d )                   
 
 S E L E C T   p _ a n n o : : v a r c h a r   b i l _ a n n o , 
 
 	 ' ' : : v a r c h a r   t i t o l o e _ t i p o _ c o d e , 
 
         s t r u t t u r a . c l a s s i f _ t i p o _ d e s c 1 : : v a r c h a r   t i t o l o e _ t i p o _ d e s c , 
 
 	 s t r u t t u r a . t i t o l o _ c o d e : : v a r c h a r   t i t o l o e _ c o d e , 
 
         s t r u t t u r a . t i t o l o _ d e s c : : v a r c h a r   t i t o l o e _ d e s c , 
 
         ' ' : : v a r c h a r   t i p o l o g i a _ t i p o _ c o d e , 
 
         s t r u t t u r a . c l a s s i f _ t i p o _ d e s c 2 : : v a r c h a r   t i p o l o g i a _ t i p o _ d e s c , 
 
         s t r u t t u r a . t i p o l o g i a _ c o d e : : v a r c h a r   t i p o l o g i a _ c o d e , 
 
         s t r u t t u r a . t i p o l o g i a _ d e s c : : v a r c h a r   t i p o l o g i a _ d e s c , 
 
         ' ' : : v a r c h a r   c a t e g o r i a _ t i p o _ c o d e , 
 
         s t r u t t u r a . c l a s s i f _ t i p o _ d e s c 3 : : v a r c h a r   c a t e g o r i a _ t i p o _ d e s c ,         
 
         s t r u t t u r a . c a t e g o r i a _ c o d e : : v a r c h a r   c a t e g o r i a _ c o d e , 
 
         s t r u t t u r a . c a t e g o r i a _ d e s c : : v a r c h a r   c a t e g o r i a _ d e s c ,               
 
         c a p i t o l i . e l e m _ c o d e : : v a r c h a r   b i l _ e l e _ c o d e , 
 
         c a p i t o l i . e l e m _ d e s c : : v a r c h a r   b i l _ e l e _ d e s c , 
 
         C O A L E S C E ( c a p i t o l i . e l e m _ c o d e 2 , ' ' ) : : v a r c h a r   b i l _ e l e _ c o d e 2 , 
 
         C O A L E S C E ( c a p i t o l i . e l e m _ d e s c 2 , ' ' ) : : v a r c h a r   b i l _ e l e _ d e s c 2 , 
 
         c a p i t o l i . e l e m _ i d : : i n t e g e r     b i l _ e l e _ i d , 
 
         c a p i t o l i . e l e m _ i d _ p a d r e : : i n t e g e r     b i l _ e l e _ i d _ p a d r e , 
 
           ( C O A L E S C E ( i m p _ c a s s a _ a n n o . i m p o r t o , 0 )   +   C O A L E S C E ( v a r i a z _ c a s s a . i m p o r t o _ v a r , 0 ) ) 
 
           	 : : n u m e r i c   s t a n z i a m e n t o _ p r e v _ c a s s a _ a n n o ,                 
 
         ( C O A L E S C E ( i m p _ c o m p _ a n n o . i m p o r t o , 0 )   +   C O A L E S C E ( v a r i a z _ s t a n z _ a n n o . i m p o r t o _ v a r , 0 ) ) 
 
         	 : : n u m e r i c   s t a n z i a m e n t o _ p r e v _ a n n o , 
 
         ( C O A L E S C E ( i m p _ c o m p _ a n n o 1 . i m p o r t o , 0 )   +   C O A L E S C E ( v a r i a z _ s t a n z _ a n n o 1 . i m p o r t o _ v a r , 0 ) ) 
 
         	 : : n u m e r i c   s t a n z i a m e n t o _ p r e v _ a n n o 1 , 
 
         ( C O A L E S C E ( i m p _ c o m p _ a n n o 2 . i m p o r t o , 0 )   +   C O A L E S C E ( v a r i a z _ s t a n z _ a n n o 2 . i m p o r t o _ v a r , 0 ) ) 
 
         	 : : n u m e r i c   s t a n z i a m e n t o _ p r e v _ a n n o 2 , 
 
 	 ( C O A L E S C E ( i m p _ r e s i d u i _ a n n o . i m p o r t o , 0 )   +   C O A L E S C E ( v a r i a z _ r e s i d u i . i m p o r t o _ v a r , 0 ) ) 
 
         	 : : n u m e r i c   r e s i d u i _ p r e s u n t i , 
 
         C O A L E S C E ( i m p _ s t a n z _ r e s i d u i _ a n n o . i m p o r t o , 0 ) : : n u m e r i c   p r e v i s i o n i _ a n n o _ p r e c ,                 
 
         C O A L E S C E ( c a p i t o l i . n u m _ c a p _ o l d , ' ' ) : : v a r c h a r   n u m _ c a p _ o l d , 
 
         C O A L E S C E ( c a p i t o l i . n u m _ a r t _ o l d , ' ' ) : : v a r c h a r   n u m _ a r t _ o l d , 
 
         C O A L E S C E ( c a p i t o l i . c a p i t o l o _ u p b , ' ' ) : : v a r c h a r   u p b , 
 
         ' ' : : v a r c h a r   d i s p l a y _ e r r o r 
 
 f r o m   s t r u t t u r a 
 
 	 l e f t   j o i n   c a p i t o l i 
 
         	 o n   s t r u t t u r a . c a t e g o r i a _ i d   =   c a p i t o l i . c a t e g o r i a _ i d         
 
       	 l e f t   j o i n   i m p _ c o m p _ a n n o 
 
       	 	 o n   i m p _ c o m p _ a n n o . e l e m _ i d   =   c a p i t o l i . e l e m _ i d 
 
         l e f t   j o i n   i m p _ c o m p _ a n n o 1 
 
                         o n   i m p _ c o m p _ a n n o 1 . e l e m _ i d   =   c a p i t o l i . e l e m _ i d 
 
         l e f t   j o i n   i m p _ c o m p _ a n n o 2 
 
                         o n   i m p _ c o m p _ a n n o 2 . e l e m _ i d   =   c a p i t o l i . e l e m _ i d 
 
         l e f t   j o i n   i m p _ r e s i d u i _ a n n o 
 
                         o n   i m p _ r e s i d u i _ a n n o . e l e m _ i d   =   c a p i t o l i . e l e m _ i d 
 
         l e f t   j o i n   i m p _ c a s s a _ a n n o 
 
                         o n   i m p _ c a s s a _ a n n o . e l e m _ i d   =   c a p i t o l i . e l e m _ i d         
 
         l e f t   j o i n   i m p _ s t a n z _ r e s i d u i _ a n n o 
 
                         o n   i m p _ s t a n z _ r e s i d u i _ a n n o . e l e m _ i d   =   c a p i t o l i . e l e m _ i d     
 
         l e f t   j o i n   v a r i a z _ s t a n z _ a n n o 
 
         	 	 o n   v a r i a z _ s t a n z _ a n n o . e l e m _ i d   =   c a p i t o l i . e l e m _ i d     
 
         l e f t   j o i n   v a r i a z _ s t a n z _ a n n o 1 
 
         	 	 o n   v a r i a z _ s t a n z _ a n n o 1 . e l e m _ i d   =   c a p i t o l i . e l e m _ i d     
 
         l e f t   j o i n   v a r i a z _ s t a n z _ a n n o 2 
 
         	 	 o n   v a r i a z _ s t a n z _ a n n o 2 . e l e m _ i d   =   c a p i t o l i . e l e m _ i d                                                     
 
 	 l e f t   j o i n   v a r i a z _ c a s s a 
 
         	 	 o n   v a r i a z _ c a s s a . e l e m _ i d   =   c a p i t o l i . e l e m _ i d                           
 
 	 l e f t   j o i n   v a r i a z _ r e s i d u i 
 
         	 	 o n   v a r i a z _ r e s i d u i . e l e m _ i d   =   c a p i t o l i . e l e m _ i d 
 
 w h e r e   c a p i t o l i . e l e m _ c o d e   I S   N O T   N U L L     ; 
 
 
 
 d e l e t e   f r o m 	 s i a c _ r e p _ v a r _ e n t r a t e 	 w h e r e   u t e n t e = u s e r _ t a b l e ;     
 
                   
 
 r a i s e   n o t i c e   ' f i n e   O K ' ; 
 
 e x c e p t i o n 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   ' n e s s u n   c a p i t o l o   t r o v a t o   r e s t i t u i s c e   r e c   s o l o   p e r   s t r u t t u r a '   ; 
 
 	 	 r e t u r n ; 
 
         w h e n   s y n t a x _ e r r o r   T H E N 
 
         	 d i s p l a y _ e r r o r = ' E R R O R E   D I   S I N T A S S I   N E I   P A R A M E T R I :   ' | |   S Q L E R R M | |   '   -   V e r i f i c a r e   s e   s o n o   s t a t i   i n s e r i t i   c a r a t t e r i   a l f a b e t i c i   o l t r e   l a   v i r g o l a . ' ; 
 
         	 r e t u r n   n e x t ; 
 
         	 r e t u r n ; 
 
         w h e n   i n v a l i d _ t e x t _ r e p r e s e n t a t i o n   T H E N 
 
         	 d i s p l a y _ e r r o r = ' E R R O R E   D I   S I N T A S S I   N E I   P A R A M E T R I :   ' | |   S Q L E R R M | |   '   -   V e r i f i c a r e   s e   s o n o   s t a t i   i n s e r i t i   c a r a t t e r i   a l f a b e t i c i   o l t r e   l a   v i r g o l a . ' ; 
 
         	 r e t u r n   n e x t ; 
 
         	 r e t u r n ;                                   
 
 	 w h e n   o t h e r s     T H E N 
 
                 R T N _ M E S S A G G I O : = ' c a p i t o l o   a l t r o   e r r o r e ' ; 
 
   	 	 R A I S E   E X C E P T I O N   ' %   E r r o r e   :   % - % . ' , R T N _ M E S S A G G I O , S Q L S T A T E , s u b s t r i n g ( S Q L E R R M   f r o m   1   f o r   5 0 0 ) ; 
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
 P A R A L L E L   U N S A F E 
 
 C O S T   1 0 0   R O W S   1 0 0 0 ; 
 
 
 
 A L T E R   F U N C T I O N   s i a c . " B I L R 2 5 3 _ p e g _ e n t r a t e _ g e s t i o n e _ v a r i a z "   ( p _ e n t e _ p r o p _ i d   i n t e g e r ,   p _ a n n o   v a r c h a r ,   p _ e l e _ v a r i a z i o n i   v a r c h a r ,   p _ n u m e r o _ d e l i b e r a   i n t e g e r ,   p _ a n n o _ d e l i b e r a   v a r c h a r ,   p _ t i p o _ d e l i b e r a   v a r c h a r ) 
 
     O W N E R   T O   s i a c ; 