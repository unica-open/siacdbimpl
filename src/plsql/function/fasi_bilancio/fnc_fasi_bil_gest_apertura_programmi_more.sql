/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ m o r e   ( 
 
     a n n o b i l a n c i o   i n t e g e r , 
 
     e n t e p r o p r i e t a r i o i d   i n t e g e r , 
 
     t i p o a p e r t u r a   v a r c h a r , 
 
     l o g i n o p e r a z i o n e   v a r c h a r , 
 
     d a t a e l a b o r a z i o n e   t i m e s t a m p , 
 
     o u t   f a s e b i l e l a b i d r e t   i n t e g e r , 
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
     D E C L A R E 
 
       s t r M e s s a g g i o               	 	 	 V A R C H A R ( 1 5 0 0 ) 	 : = ' ' ; 
 
       s t r M e s s a g g i o f i n a l e   	 	 	 V A R C H A R ( 1 5 0 0 ) 	 : = ' ' ; 
 
       c o d R e s u l t                             	 	 I N T E G E R     	 	 : = N U L L ; 
 
       d a t a I n i z i o V a l   	 	 	 	 t i m e s t a m p 	 	 : = N U L L ; 
 
       f a s e B i l E l a b I d   	 	                 i n t e g e r : = n u l l ; 
 
       b i l a n c i o I d                                       i n t e g e r : = n u l l ; 
 
       p e r i o d o I d                                         i n t e g e r : = n u l l ; 
 
 
 
       f a s e O p                                               v a r c h a r ( 5 0 ) : = n u l l ; 
 
       s t r R e c   r e c o r d ; 
 
 
 
       A P E _ G E S T _ P R O G R A M M I         	         C O N S T A N T   v a r c h a r : = ' A P E _ G E S T _ P R O G R A M M I ' ; 
 
       P _ F A S E 	 	 	 	 	 	 C O N S T A N T   v a r c h a r : = ' P ' ; 
 
       G _ F A S E 	 	 	 	 	         C O N S T A N T   v a r c h a r : = ' G ' ; 
 
     B E G I N 
 
 
 
       m e s s a g g i o R i s u l t a t o : = ' ' ; 
 
       c o d i c e r i s u l t a t o : = 0 ; 
 
       f a s e B i l E l a b I d R e t : = 0 ; 
 
       d a t a I n i z i o V a l : =   c l o c k _ t i m e s t a m p ( ) ; 
 
 
 
       s t r m e s s a g g i o f i n a l e : = ' A p e r t u r a   P r o g r a m m i - C r o n o p r o g r a m m i   d i   t i p o   ' | | t i p o A p e r t u r a | | '   p e r   a n n o B i l a n c i o = ' | | a n n o B i l a n c i o : : v a r c h a r | | ' . ' ; 
 
 
 
       s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   f a s e   e l a b o r a z i o n e   ' | | A P E _ G E S T _ P R O G R A M M I | | '   I N   C O R S O . ' ; 
 
       s e l e c t   1   i n t o   c o d R e s u l t 
 
       f r o m   f a s e _ b i l _ t _ e l a b o r a z i o n e   f a s e ,   f a s e _ b i l _ d _ e l a b o r a z i o n e _ t i p o   t i p o 
 
       w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       t i p o . f a s e _ b i l _ e l a b _ t i p o _ c o d e = A P E _ G E S T _ P R O G R A M M I 
 
       a n d       f a s e . f a s e _ b i l _ e l a b _ t i p o _ i d = t i p o . f a s e _ b i l _ e l a b _ t i p o _ i d 
 
       a n d       f a s e . f a s e _ b i l _ e l a b _ e s i t o   l i k e   ' I N % ' 
 
       a n d       f a s e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       f a s e . v a l i d i t a _ f i n e   i s   n u l l 
 
       a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
       i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
       	 r a i s e   e x c e p t i o n   '   E s i s t e n z a   f a s e   i n   c o r s o . ' ; 
 
       e n d   i f ; 
 
 
 
 
 
         - -   i n s e r i m e n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   f a s e   e l a b o r a z i o n e   [ f a s e _ b i l _ t _ e l a b o r a z i o n e ] . ' ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
         ( f a s e _ b i l _ e l a b _ e s i t o ,   f a s e _ b i l _ e l a b _ e s i t o _ m s g , 
 
           f a s e _ b i l _ e l a b _ t i p o _ i d , 
 
           e n t e _ p r o p r i e t a r i o _ i d , v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ) 
 
         ( s e l e c t   ' I N ' , ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | '   I N   C O R S O . ' , 
 
                         t i p o . f a s e _ b i l _ e l a b _ t i p o _ i d , e n t e P r o p r i e t a r i o I d ,   d a t a I n i z i o V a l ,   l o g i n O p e r a z i o n e 
 
           f r o m   f a s e _ b i l _ d _ e l a b o r a z i o n e _ t i p o   t i p o 
 
           w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d       t i p o . f a s e _ b i l _ e l a b _ t i p o _ c o d e = A P E _ G E S T _ P R O G R A M M I 
 
           a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l ) 
 
           r e t u r n i n g   f a s e _ b i l _ e l a b _ i d   i n t o   f a s e B i l E l a b I d ; 
 
 
 
           i f   f a s e B i l E l a b I d   i s   n u l l   t h e n 
 
           	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
           e n d   i f ; 
 
 
 
 	   s t r M e s s a g g i o : = ' I n s e r i m e n t o   L O G . ' ; 
 
   	   c o d R e s u l t : = n u l l ; 
 
 	   i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
           ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
             v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
           ) 
 
           v a l u e s 
 
           ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | '   I N I Z I O . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
           r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
           i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
           e n d   i f ; 
 
 
 
           s t r M e s s a g g i o : = ' L e t t u r a   b i l a n c i o I d   e   p e r i o d o I d     p e r   a n n o B i l a n c i o = ' | | a n n o B i l a n c i o : : v a r c h a r | | ' . ' ; 
 
           s e l e c t   b i l . b i l _ i d   ,   p e r . p e r i o d o _ i d   i n t o   s t r i c t   b i l a n c i o I d ,   p e r i o d o I d 
 
           f r o m   s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r 
 
           w h e r e   b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           a n d       p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
           a n d       p e r . a n n o : : I N T E G E R = a n n o B i l a n c i o 
 
           a n d       b i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       p e r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 	   s t r M e s s a g g i o : = ' V e r i f i c a   f a s e   d i   b i l a n c i o   d i   c o r r e n t e . ' ; 
 
 	   s e l e c t   f a s e . f a s e _ o p e r a t i v a _ c o d e   i n t o   f a s e O p 
 
           f r o m   s i a c _ r _ b i l _ f a s e _ o p e r a t i v a   r ,   s i a c _ d _ f a s e _ o p e r a t i v a   f a s e 
 
           w h e r e   r . b i l _ i d = b i l a n c i o I d 
 
           a n d       f a s e . f a s e _ o p e r a t i v a _ i d = r . f a s e _ o p e r a t i v a _ i d 
 
           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
           i f   f a s e O p   i s   n u l l   o r   f a s e O p   n o t   i n   ( P _ F A S E , G _ F A S E )   t h e n 
 
             	 r a i s e   e x c e p t i o n   '   I l   b i l a n c i o   d e v e   e s s e r e   i n   f a s e   %   o   % . ' , P _ F A S E , G _ F A S E ; 
 
           e n d   i f ; 
 
 
 
           / * s t r M e s s a g g i o : = ' V e r i f i c a   c o e r e n z a   t i p o   d i   a p e r t u r a   p r o g r a m m i - f a s e   d i   b i l a n c i o   d i   c o r r e n t e . ' ; 
 
 	   i f   t i p o A p e r t u r a ! = f a s e O p   t h e n 
 
           	 r a i s e   e x c e p t i o n   '   T i p o   d i   a p e r t u r a   %   n o n   c o n s e n t i t a   i n   f a s e   d i   b i l a n c i o   % . ' ,   t i p o A p e r t u r a , f a s e O p ; 
 
           e n d   i f ; * / 
 
 
 
   	   s t r M e s s a g g i o : = ' I n i z i o   P o p o l a   p r o g r a m m i - c r o n o p   d a   e l a b o r a r e . ' ; 
 
           s e l e c t   *   i n t o   s t r R e c 
 
           f r o m   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ p o p o l a _ m o r e 
 
           ( 
 
             f a s e B i l E l a b I d , 
 
             e n t e p r o p r i e t a r i o i d , 
 
             a n n o b i l a n c i o , 
 
             t i p o A p e r t u r a , 
 
             l o g i n o p e r a z i o n e , 
 
 	     d a t a e l a b o r a z i o n e 
 
           ) ; 
 
           i f   s t r R e c . c o d i c e R i s u l t a t o ! = 0   t h e n 
 
                 s t r M e s s a g g i o : = s t r R e c . m e s s a g g i o R i s u l t a t o ; 
 
                 c o d i c e R i s u l t a t o : = s t r R e c . c o d i c e R i s u l t a t o ; 
 
           e n d   i f ; 
 
 
 
           i f   c o d i c e R i s u l t a t o = 0   t h e n 
 
 	           s t r M e s s a g g i o : = ' I n i z i o   E l a b o r a   p r o g r a m m i - c r o n o p . ' ; 
 
         	   s e l e c t   *   i n t o   s t r R e c 
 
 	           f r o m   f n c _ f a s i _ b i l _ g e s t _ a p e r t u r a _ p r o g r a m m i _ e l a b o r a 
 
         	   ( 
 
 	             f a s e B i l E l a b I d , 
 
         	     e n t e p r o p r i e t a r i o i d , 
 
 	             a n n o b i l a n c i o , 
 
                     t i p o A p e r t u r a , 
 
                     l o g i n o p e r a z i o n e , 
 
                     d a t a e l a b o r a z i o n e 
 
                   ) ; 
 
                   i f   s t r R e c . c o d i c e R i s u l t a t o ! = 0   t h e n 
 
                         s t r M e s s a g g i o : = s t r R e c . m e s s a g g i o R i s u l t a t o ; 
 
                         c o d i c e R i s u l t a t o : = s t r R e c . c o d i c e R i s u l t a t o ; 
 
                   e n d   i f ; 
 
 
 
           e n d   i f ; 
 
 
 
 
 
           i f   c o d i c e R i s u l t a t o = 0   a n d   f a s e B i l E l a b I d   i s   n o t   n u l l   t h e n 
 
 	       s t r M e s s a g g i o : = '   C h i u s u r a   f a s e _ b i l _ t _ e l a b o r a z i o n e   O K . ' ; 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
 	       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	   	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
 	       e n d   i f ; 
 
 
 
               u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
               s e t   f a s e _ b i l _ e l a b _ e s i t o = ' O K ' , 
 
                       f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | ' T E R M I N A T A   C O N   S U C C E S S O . ' 
 
               w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | '   F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
 	       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	   	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
 	       e n d   i f ; 
 
 
 
 	   e l s e 
 
             i f   c o d i c e R i s u l t a t o ! = 0   a n d   f a s e B i l E l a b I d   i s   n o t   n u l l   t h e n 
 
 	       s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C h i u s u r a   f a s e _ b i l _ t _ e l a b o r a z i o n e   K O . ' ; 
 
               i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
 	       ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
                 v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
 	       ) 
 
 	       v a l u e s 
 
               ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
 	       r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
 	       i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	   	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
 	       e n d   i f ; 
 
 
 
               u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
               s e t   f a s e _ b i l _ e l a b _ e s i t o = ' K O ' , 
 
                       f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ P R O G R A M M I | | ' T E R M I N A T A   C O N   E R R O R E . ' | | u p p e r   ( s t r M e s s a g g i o ) 
 
               w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
             e n d   i f ; 
 
 
 
           e n d   i f ; 
 
 	   i f     c o d i c e R i s u l t a t o = 0   t h e n 
 
 	     	   m e s s a g g i o R i s u l t a t o   : =   s t r M e s s a g g i o F i n a l e | | '   O p e r a z i o n e   t e r m i n a t a   c o r r e t t a m e n t e ' ; 
 
 	   e l s e 
 
     	     	   m e s s a g g i o R i s u l t a t o   : =   s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
           e n d   i f ; 
 
 
 
 	   R E T U R N ; 
 
 E X C E P T I O N 
 
     W H E N   r a i s e _ e x c e p t i o n   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' E R R O R E :   .   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     W H E N   n o _ d a t a _ f o u n d   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' N e s s u n   e l e m e n t o   t r o v a t o .   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     W H E N   O T H E R S   T H E N 
 
         R A I S E   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r m e s s a g g i o f i n a l e , s t r m e s s a g g i o , S Q L S T A T E ,   s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 ) ; 
 
         m e s s a g g i o r i s u l t a t o : = s t r m e s s a g g i o f i n a l e | | s t r m e s s a g g i o | | ' E r r o r e   O T H E R S   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   F R O M   1   F O R   1 5 0 0 )   ; 
 
         c o d i c e r i s u l t a t o : = - 1 ; 
 
         R E T U R N ; 
 
     E N D ; 
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