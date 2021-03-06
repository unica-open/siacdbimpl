/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ s i a c _ b k o _ c a r i c a m e n t o _ p d c e _ c o n t o 
 
 ( 
 
     a n n o B i l a n c i o                                         i n t e g e r , 
 
     e n t e P r o p r i e t a r i o I d                             i n t e g e r , 
 
     a m b i t o C o d e                                             v a r c h a r , 
 
     l o g i n O p e r a z i o n e                                   v a r c h a r , 
 
     d a t a E l a b o r a z i o n e                                 t i m e s t a m p , 
 
     o u t   c o d i c e r i s u l t a t o                           i n t e g e r , 
 
     o u t   m e s s a g g i o r i s u l t a t o                     v a r c h a r 
 
 ) 
 
 R E T U R N S   r e c o r d   A S 
 
 $ b o d y $ 
 
 D E C L A R E 
 
 
 
 	 s t r M e s s a g g i o   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 	 s t r M e s s a g g i o F i n a l e   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 
 
         c o d R e s u l t   i n t e g e r : = n u l l ; 
 
 
 
         d a t e I n i z V a l   t i m e s t a m p : = n u l l ; 
 
 B E G I N 
 
 
 
 	 s t r M e s s a g g i o F i n a l e : = ' I n s e r i m e n t o   c o n t i   P D C _ E C O N   d i   g e n e r a l e   a m b i t o C o d e = ' | | a m b i t o C o d e | | ' . ' ; 
 
 
 
         c o d i c e R i s u l t a t o : = 0 ; 
 
         m e s s a g g i o R i s u l t a t o : = ' ' ; 
 
 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   c o n t i   d a   c r e a r e   i n   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o . ' ; 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o 
 
         w h e r e   b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . a m b i t o = a m b i t o C o d e 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   C o n t i   n o n   p r e s e n t i . ' ; 
 
         e n d   i f ; 
 
 
 
         d a t e I n i z V a l : = ( a n n o B i l a n c i o : : v a r c h a r | | ' - 0 1 - 0 1 ' ) : : t i m e s t a m p ; 
 
 
 
 	 c o d R e s u l t : = n u l l ; 
 
 	 - -   s i a c _ t _ c l a s s   B . 1 3 . a 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o d i c e   d i   b i l a n c i o   B . 1 3 . a   [ s i a c _ t _ c l a s s ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ t _ c l a s s 
 
         ( 
 
             c l a s s i f _ c o d e , 
 
             c l a s s i f _ d e s c , 
 
             c l a s s i f _ t i p o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t 
 
           ' a ' , 
 
           ' P e r s o n a l e ' , 
 
           t i p o . c l a s s i f _ t i p o _ i d , 
 
           d a t e I n i z V a l , 
 
           l o g i n O p e r a z i o n e , 
 
           t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ v _ d w h _ c o d i f i c h e _ e c o n p a t r   d w h , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o , 
 
                   s i a c _ r _ c l a s s _ f a m _ t r e e   r , s i a c _ t _ c l a s s _ f a m _ t r e e   t r e e ,   s i a c _ d _ c l a s s _ f a m   f a m 
 
         w h e r e   d w h . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       d w h . c o d i c e _ c o d i f i c a _ a l b e r o   =   ' B . 1 3 ' 
 
         a n d       c . c l a s s i f _ i d = d w h . c l a s s i f _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ c o d e   n o t   l i k e   ' % G S A ' 
 
         a n d       r . c l a s s i f _ i d = c . c l a s s i f _ i d 
 
         a n d       t r e e . c l a s s i f _ f a m _ t r e e _ i d = r . c l a s s i f _ f a m _ t r e e _ i d 
 
         a n d       f a m . c l a s s i f _ f a m _ i d = t r e e . c l a s s i f _ f a m _ i d 
 
 / *         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1 
 
         f r o m   s i a c _ t _ c l a s s   c 1 
 
         w h e r e   c 1 . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c 1 . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
         a n d       c 1 . c l a s s i f _ c o d e = ' a ' 
 
         a n d       c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         ) * / 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         r e t u r n i n g   c l a s s i f _ i d   i n t o   c o d R e s u l t ; 
 
 	 r a i s e   n o t i c e   ' s t r M e s s a g g i o = %   % ' , s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
   	 - -   s i a c _ r _ c l a s s _ f a m _ t r e e   B . 1 3 . a 
 
 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o d i c e   d i   b i l a n c i o   B . 1 3 . a   [ s i a c _ r _ c l a s s _ f a m _ t r e e ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ r _ c l a s s _ f a m _ t r e e 
 
         ( 
 
             c l a s s i f _ f a m _ t r e e _ i d , 
 
             c l a s s i f _ i d , 
 
             c l a s s i f _ i d _ p a d r e , 
 
             o r d i n e , 
 
             l i v e l l o , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   t r e e . c l a s s i f _ f a m _ t r e e _ i d , 
 
                       c n e w . c l a s s i f _ i d , 
 
                       c . c l a s s i f _ i d , 
 
                       r . o r d i n e | | ' . ' | | c n e w . c l a s s i f _ c o d e , 
 
                       r . l i v e l l o + 1 , 
 
                       d a t e I n i z V a l , 
 
                       l o g i n O p e r a z i o n e , 
 
                       t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ v _ d w h _ c o d i f i c h e _ e c o n p a t r   d w h , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o , 
 
                   s i a c _ r _ c l a s s _ f a m _ t r e e   r , s i a c _ t _ c l a s s _ f a m _ t r e e   t r e e ,   s i a c _ d _ c l a s s _ f a m   f a m , 
 
                   s i a c _ t _ c l a s s   c n e w 
 
         w h e r e   d w h . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       d w h . c o d i c e _ c o d i f i c a _ a l b e r o   =   ' B . 1 3 ' 
 
         a n d       c . c l a s s i f _ i d = d w h . c l a s s i f _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ c o d e   n o t   l i k e   ' % G S A ' 
 
         a n d       r . c l a s s i f _ i d = c . c l a s s i f _ i d 
 
         a n d       t r e e . c l a s s i f _ f a m _ t r e e _ i d = r . c l a s s i f _ f a m _ t r e e _ i d 
 
         a n d       f a m . c l a s s i f _ f a m _ i d = t r e e . c l a s s i f _ f a m _ i d 
 
         a n d       c n e w . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c n e w . l o g i n _ o p e r a z i o n e   = l o g i n O p e r a z i o n e 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c l a s s _ f a m _ t r e e   r 1 
 
         w h e r e   r 1 . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r 1 . c l a s s i f _ i d = c n e w . c l a s s i f _ i d 
 
         a n d       r 1 . c l a s s i f _ i d _ p a d r e = c . c l a s s i f _ i d 
 
         a n d       r 1 . c l a s s i f _ f a m _ t r e e _ i d = t r e e . c l a s s i f _ f a m _ t r e e _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         r e t u r n i n g   c l a s s i f _ c l a s s i f _ f a m _ t r e e _ i d   i n t o   c o d R e s u l t ; 
 
 	 r a i s e   n o t i c e   ' s t r M e s s a g g i o = %   % ' , s t r M e s s a g g i o , c o d R e s u l t ; 
 
 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
 	 - -   s i a c _ t _ p d c e _ c o n t o 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   l i v e l l o   V   [ s i a c _ t _ p d c e _ c o n t o ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ t _ p d c e _ c o n t o 
 
         ( 
 
             p d c e _ c o n t o _ c o d e , 
 
             p d c e _ c o n t o _ d e s c , 
 
             p d c e _ c o n t o _ i d _ p a d r e , 
 
             l i v e l l o , 
 
             o r d i n e , 
 
             p d c e _ f a m _ t r e e _ i d , 
 
             p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             e n t e _ p r o p r i e t a r i o _ i d , 
 
             l o g i n _ o p e r a z i o n e , 
 
             l o g i n _ c r e a z i o n e 
 
         ) 
 
         s e l e c t 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             b k o . p d c e _ c o n t o _ d e s c , 
 
             c o n t o P a d r e . p d c e _ c o n t o _ i d , 
 
             b k o . l i v e l l o , 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             t r e e . p d c e _ f a m _ t r e e _ i d , 
 
             t i p o . p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o . a m b i t o _ i d , 
 
             d a t e I n i z V a l , 
 
             t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ ' | | b k o . c a r i c a _ p d c e _ c o n t o _ i d : : v a r c h a r , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
                   s i a c _ t _ p d c e _ f a m _ t r e e   t r e e , s i a c _ d _ p d c e _ f a m   f a m , 
 
                   s i a c _ d _ a m b i t o   a m b i t o , 
 
                   s i a c _ d _ p d c e _ c o n t o _ t i p o   t i p o , 
 
                   s i a c _ t _ p d c e _ c o n t o   c o n t o P a d r e 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       f a m . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       f a m . p d c e _ f a m _ c o d e = b k o . c l a s s e _ c o n t o 
 
         a n d       t r e e . p d c e _ f a m _ i d = f a m . p d c e _ f a m _ i d 
 
         a n d       t i p o . p d c e _ c t _ t i p o _ c o d e = b k o . t i p o _ c o n t o 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       b k o . l i v e l l o = 5 
 
         a n d       c o n t o P a d r e . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o P a d r e . l i v e l l o = b k o . l i v e l l o - 1 
 
         a n d       c o n t o P a d r e . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ c o n t o _ c o d e   = 
 
                     S U B S T R I N G ( b k o . p d c e _ c o n t o _ c o d e   f r o m   1   f o r   l e n g t h ( b k o . p d c e _ c o n t o _ c o d e ) -   p o s i t i o n ( ' . '   i n   r e v e r s e ( b k o . p d c e _ c o n t o _ c o d e ) ) ) 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . l i v e l l o = 5 
 
         a n d       c o n t o . p d c e _ c t _ t i p o _ i d = t i p o . p d c e _ c t _ t i p o _ i d 
 
         a n d       c o n t o . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c o n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' C o n t i   l i v e l l o   V   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
 	 - -   s i a c _ t _ p d c e _ c o n t o 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   l i v e l l o   V I   [ s i a c _ t _ p d c e _ c o n t o ] . ' ; 
 
       	 i n s e r t   i n t o   s i a c _ t _ p d c e _ c o n t o 
 
         ( 
 
             p d c e _ c o n t o _ c o d e , 
 
             p d c e _ c o n t o _ d e s c , 
 
             p d c e _ c o n t o _ i d _ p a d r e , 
 
             l i v e l l o , 
 
             o r d i n e , 
 
             p d c e _ f a m _ t r e e _ i d , 
 
             p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             e n t e _ p r o p r i e t a r i o _ i d , 
 
             l o g i n _ o p e r a z i o n e , 
 
             l o g i n _ c r e a z i o n e 
 
         ) 
 
         s e l e c t 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             b k o . p d c e _ c o n t o _ d e s c , 
 
             c o n t o P a d r e . p d c e _ c o n t o _ i d , 
 
             b k o . l i v e l l o , 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             t r e e . p d c e _ f a m _ t r e e _ i d , 
 
             t i p o . p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o . a m b i t o _ i d , 
 
             d a t e I n i z V a l , 
 
             t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ ' | | b k o . c a r i c a _ p d c e _ c o n t o _ i d : : v a r c h a r , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
                   s i a c _ t _ p d c e _ f a m _ t r e e   t r e e , s i a c _ d _ p d c e _ f a m   f a m , 
 
                   s i a c _ d _ a m b i t o   a m b i t o , 
 
                   s i a c _ d _ p d c e _ c o n t o _ t i p o   t i p o , 
 
                   s i a c _ t _ p d c e _ c o n t o   c o n t o P a d r e 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       f a m . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       f a m . p d c e _ f a m _ c o d e = b k o . c l a s s e _ c o n t o 
 
         a n d       t r e e . p d c e _ f a m _ i d = f a m . p d c e _ f a m _ i d 
 
         a n d       t i p o . p d c e _ c t _ t i p o _ c o d e = b k o . t i p o _ c o n t o 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       b k o . l i v e l l o = 6 
 
         a n d       c o n t o P a d r e . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o P a d r e . l i v e l l o = b k o . l i v e l l o - 1 
 
         a n d       c o n t o P a d r e . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ c o n t o _ c o d e   = 
 
                     S U B S T R I N G ( b k o . p d c e _ c o n t o _ c o d e   f r o m   1   f o r   l e n g t h ( b k o . p d c e _ c o n t o _ c o d e ) -   p o s i t i o n ( ' . '   i n   r e v e r s e ( b k o . p d c e _ c o n t o _ c o d e ) ) ) 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . l i v e l l o = 6 
 
         a n d       c o n t o . p d c e _ c t _ t i p o _ i d = t i p o . p d c e _ c t _ t i p o _ i d 
 
         a n d       c o n t o . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c o n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' C o n t i   l i v e l l o   V I   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
 	 - -   s i a c _ t _ p d c e _ c o n t o 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   l i v e l l o   V I I   [ s i a c _ t _ p d c e _ c o n t o ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ t _ p d c e _ c o n t o 
 
         ( 
 
             p d c e _ c o n t o _ c o d e , 
 
             p d c e _ c o n t o _ d e s c , 
 
             p d c e _ c o n t o _ i d _ p a d r e , 
 
             l i v e l l o , 
 
             o r d i n e , 
 
             p d c e _ f a m _ t r e e _ i d , 
 
             p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             e n t e _ p r o p r i e t a r i o _ i d , 
 
             l o g i n _ o p e r a z i o n e , 
 
             l o g i n _ c r e a z i o n e 
 
         ) 
 
         s e l e c t 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             b k o . p d c e _ c o n t o _ d e s c , 
 
             c o n t o P a d r e . p d c e _ c o n t o _ i d , 
 
             b k o . l i v e l l o , 
 
             b k o . p d c e _ c o n t o _ c o d e , 
 
             t r e e . p d c e _ f a m _ t r e e _ i d , 
 
             t i p o . p d c e _ c t _ t i p o _ i d , 
 
             a m b i t o . a m b i t o _ i d , 
 
             d a t e I n i z V a l , 
 
             t i p o . e n t e _ p r o p r i e t a r i o _ i d , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ ' | | b k o . c a r i c a _ p d c e _ c o n t o _ i d : : v a r c h a r , 
 
             b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
                   s i a c _ t _ p d c e _ f a m _ t r e e   t r e e , s i a c _ d _ p d c e _ f a m   f a m , 
 
                   s i a c _ d _ a m b i t o   a m b i t o , 
 
                   s i a c _ d _ p d c e _ c o n t o _ t i p o   t i p o , 
 
                   s i a c _ t _ p d c e _ c o n t o   c o n t o P a d r e 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       f a m . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       f a m . p d c e _ f a m _ c o d e = b k o . c l a s s e _ c o n t o 
 
         a n d       t r e e . p d c e _ f a m _ i d = f a m . p d c e _ f a m _ i d 
 
         a n d       t i p o . p d c e _ c t _ t i p o _ c o d e = b k o . t i p o _ c o n t o 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       b k o . l i v e l l o = 7 
 
         a n d       c o n t o P a d r e . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o P a d r e . l i v e l l o = b k o . l i v e l l o - 1 
 
         a n d       c o n t o P a d r e . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o P a d r e . p d c e _ c o n t o _ c o d e   = 
 
                     S U B S T R I N G ( b k o . p d c e _ c o n t o _ c o d e   f r o m   1   f o r   l e n g t h ( b k o . p d c e _ c o n t o _ c o d e ) -   p o s i t i o n ( ' . '   i n   r e v e r s e ( b k o . p d c e _ c o n t o _ c o d e ) ) ) 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . l i v e l l o = 7 
 
         a n d       c o n t o . p d c e _ c t _ t i p o _ i d = t i p o . p d c e _ c t _ t i p o _ i d 
 
         a n d       c o n t o . p d c e _ f a m _ t r e e _ i d = t r e e . p d c e _ f a m _ t r e e _ i d 
 
         a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c o n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' C o n t i   l i v e l l o   V I I   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   a t t r i b u t i   p d c e _ c o n t o _ f o g l i a   [ s i a c _ r _ p d c e _ c o n t o _ a t t r ] . ' ; 
 
 
 
         - -   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         - -   p d c e _ c o n t o _ f o g l i a 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 a t t r _ i d , 
 
                 b o o l e a n , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       a t t r . a t t r _ i d , 
 
                       ' S ' , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ t _ a t t r   a t t r , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a t t r . a t t r _ c o d e = ' p d c e _ c o n t o _ f o g l i a ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       c o a l e s c e ( b k o . c o n t o _ f o g l i a , ' ' ) = ' S ' 
 
 - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' A t t r i b u t i   p d c e _ c o n t o _ f o g l i a   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   a t t r i b u t i   p d c e _ c o n t o _ d i _ l e g g e   [ s i a c _ r _ p d c e _ c o n t o _ a t t r ] . ' ; 
 
 
 
         - -   p d c e _ c o n t o _ d i _ l e g g e 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 a t t r _ i d , 
 
                 b o o l e a n , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       a t t r . a t t r _ i d , 
 
                       ' S ' , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ t _ a t t r   a t t r , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a t t r . a t t r _ c o d e = ' p d c e _ c o n t o _ d i _ l e g g e ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       c o a l e s c e ( b k o . c o n t o _ d i _ l e g g e , ' ' ) = ' S ' 
 
 - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' A t t r i b u t i   p d c e _ c o n t o _ d i _ l e g g e   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   a t t r i b u t i   p d c e _ a m m o r t a m e n t o   [ s i a c _ r _ p d c e _ c o n t o _ a t t r ] . ' ; 
 
 
 
         - -   p d c e _ a m m o r t a m e n t o 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 a t t r _ i d , 
 
                 b o o l e a n , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       a t t r . a t t r _ i d , 
 
                       ' S ' , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ t _ a t t r   a t t r , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a t t r . a t t r _ c o d e = ' p d c e _ a m m o r t a m e n t o ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       c o a l e s c e ( b k o . a m m o r t a m e n t o , ' ' ) = ' S ' 
 
 - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' A t t r i b u t i   p d c e _ a m m o r t a m e n t o   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   a t t r i b u t i   p d c e _ c o n t o _ a t t i v o   [ s i a c _ r _ p d c e _ c o n t o _ a t t r ] . ' ; 
 
         - -   p d c e _ c o n t o _ a t t i v o 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 a t t r _ i d , 
 
                 b o o l e a n , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       a t t r . a t t r _ i d , 
 
                       ' S ' , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ t _ a t t r   a t t r , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a t t r . a t t r _ c o d e = ' p d c e _ c o n t o _ a t t i v o ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       c o a l e s c e ( b k o . c o n t o _ a t t i v o , ' ' ) = ' S ' 
 
 - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' A t t r i b u t i   p d c e _ c o n t o _ a t t i v o   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   a t t r i b u t i   p d c e _ c o n t o _ s e g n o _ n e g a t i v o   [ s i a c _ r _ p d c e _ c o n t o _ a t t r ] . ' ; 
 
         - -   p d c e _ c o n t o _ s e g n o _ n e g a t i v o 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ a t t r 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 a t t r _ i d , 
 
                 b o o l e a n , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       a t t r . a t t r _ i d , 
 
                       ' S ' , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ t _ a t t r   a t t r , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a t t r . a t t r _ c o d e = ' p d c e _ c o n t o _ s e g n o _ n e g a t i v o ' 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = a t t r . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       c o a l e s c e ( b k o . c o n t o _ s e g n o _ n e g a t i v o , ' ' ) = ' S ' 
 
 - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' A t t r i b u t i   p d c e _ c o n t o _ s e g n o _ n e g a t i v o   i n s e r i t i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c o n t i   -   c o d i f i c a _ b i l   [ s i a c _ r _ p d c e _ c o n t o _ c l a s s ] . ' ; 
 
         - -   s i a c _ r _ p d c e _ c o n t o _ c l a s s 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ c l a s s 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 c l a s s i f _ i d , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       d w h . c l a s s i f _ i d , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       c o n t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ v _ d w h _ c o d i f i c h e _ e c o n p a t r   d w h ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o , 
 
                   s i a c _ t _ p d c e _ c o n t o   c o n t o ,   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = a m b i t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' I ' 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
 - - -         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' @ % ' 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c e _ c o n t o _ c o d e 
 
 
 
         a n d       b k o . c a r i c a _ p d c e _ c o n t o _ i d = S U B S T R I N G ( c o n t o . l o g i n _ o p e r a z i o n e ,   P O S I T I O N ( ' @ '   i n   c o n t o . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       c o a l e s c e ( b k o . c o d i f i c a _ b i l , ' ' ) ! = ' ' 
 
         a n d       d w h . e n t e _ p r o p r i e t a r i o _ i d = c o n t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       d w h . c o d i c e _ c o d i f i c a _ a l b e r o = b k o . c o d i f i c a _ b i l 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' C o d i f i c h e   d i   b i l a n c i o     p d c e _ c o n t o   i n s e r i t e = % ' , c o d R e s u l t ; 
 
 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o     c o n t i   e s i s t e n t i   -   d e s c r i z i o n e     [ s i a c _ t _ p d c e _ c o n t o ] . ' ; 
 
         u p d a t e     s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
 	 s e t           p d c e _ c o n t o _ d e s c = b k o . p d c e _ c o n t o _ d e s c , 
 
         	         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                 	 l o g i n _ o p e r a z i o n e = c o n t o . l o g i n _ o p e r a z i o n e | | ' - ' | | b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
         	   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o ,   s i a c _ d _ a m b i t o   a m b i t o 
 
 	 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' A ' 
 
         a n d       b k o . p d c e _ c o n t o _ c o d e = c o n t o . p d c e _ c o n t o _ c o d e 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o     c o n t i   e s i s t e n t i   -   c o d i f _ b i l   -   c h i u s u r a     [ s i a c _ r _ p d c e _ c o n t o _ c l a s s ] . ' ; 
 
         u p d a t e   s i a c _ r _ p d c e _ c o n t o _ c l a s s   r c 
 
         s e t           d a t a _ c a n c e l l a z i o n e = c l o c k _ t i m e s t a m p ( ) , 
 
                         v a l i d i t a _ f i n e = c l o c k _ t i m e s t a m p ( ) , 
 
                         l o g i n _ o p e r a z i o n e = r c . l o g i n _ o p e r a z i o n e | | ' - ' | | b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ d _ c l a s s _ t i p o   t i p o , s i a c _ t _ c l a s s   c , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o ,   s i a c _ d _ a m b i t o   a m b i t o   ,   s i a c _ t _ p d c e _ c o n t o   c o n t o , 
 
                   s i a c _ v _ d w h _ c o d i f i c h e _ e c o n p a t r   d w h 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ c o d e   i n 
 
         ( 
 
         ' S P A _ C O D B I L ' , 
 
         ' S P P _ C O D B I L ' , 
 
         ' C E _ C O D B I L ' , 
 
         ' C O _ C O D B I L ' 
 
         ) 
 
         a n d       c . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' A ' 
 
         a n d       b k o . p d c e _ c o n t o _ c o d e = c o n t o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o a l e s c e ( b k o . c o d i f i c a _ b i l , ' ' ) ! = ' ' 
 
         a n d       d w h . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       d w h . c o d i c e _ c o d i f i c a _ a l b e r o = b k o . c o d i f i c a _ b i l 
 
         a n d       r c . c l a s s i f _ i d = c . c l a s s i f _ i d 
 
         a n d       r c . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o     c o n t i   e s i s t e n t i   -   c o d i f _ b i l   -   i n s e r i m e n t o     [ s i a c _ r _ p d c e _ c o n t o _ c l a s s ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ r _ p d c e _ c o n t o _ c l a s s 
 
         ( 
 
                 p d c e _ c o n t o _ i d , 
 
                 c l a s s i f _ i d , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   c o n t o . p d c e _ c o n t o _ i d , 
 
                       d w h . c l a s s i f _ i d , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       c o n t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , 
 
                   s i a c _ b k o _ t _ c a r i c a m e n t o _ p d c e _ c o n t o   b k o ,   s i a c _ d _ a m b i t o   a m b i t o   ,   s i a c _ t _ p d c e _ c o n t o   c o n t o , 
 
                   s i a c _ v _ d w h _ c o d i f i c h e _ e c o n p a t r   d w h 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . a m b i t o = a m b i t o . a m b i t o _ c o d e 
 
         a n d       b k o . t i p o _ o p e r a z i o n e = ' A ' 
 
         a n d       b k o . p d c e _ c o n t o _ c o d e = c o n t o . p d c e _ c o n t o _ c o d e 
 
         a n d       c o a l e s c e ( b k o . c o d i f i c a _ b i l , ' ' ) ! = ' ' 
 
         a n d       d w h . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       d w h . c o d i c e _ c o d i f i c a _ a l b e r o = b k o . c o d i f i c a _ b i l 
 
         a n d       b k o . c a r i c a t o = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
       	 r a i s e   n o t i c e   ' C o d i f i c h e   d i   b i l a n c i o     p d c e _ c o n t o   i n s e r i t e = % ' , c o d R e s u l t ; 
 
 
 
         m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | '   E l a b o r a z i o n e   t e r m i n a t a . ' ; 
 
 
 
         r a i s e   n o t i c e   ' % ' , m e s s a g g i o R i s u l t a t o ; 
 
 
 
         r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E :     ' | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' )   ; 
 
               	 c o d i c e R i s u l t a t o : = - 1 ; 
 
 
 
 	 	 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   N O _ D A T A _ F O U N D   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   N e s s u n   d a t o   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   D B : ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
                 r e t u r n ; 
 
 
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
 
 
 
 
 
 
 
 C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ s i a c _ b k o _ c a r i c a m e n t o _ c a u s a l i 
 
 ( 
 
     a n n o B i l a n c i o                                         i n t e g e r , 
 
     e n t e P r o p r i e t a r i o I d                             i n t e g e r , 
 
     a m b i t o C o d e                                             v a r c h a r , 
 
     l o g i n O p e r a z i o n e                                   v a r c h a r , 
 
     d a t a E l a b o r a z i o n e                                 t i m e s t a m p , 
 
     o u t   c o d i c e r i s u l t a t o                           i n t e g e r , 
 
     o u t   m e s s a g g i o r i s u l t a t o                     v a r c h a r 
 
 ) 
 
 R E T U R N S   r e c o r d   A S 
 
 $ b o d y $ 
 
 D E C L A R E 
 
 
 
 	 s t r M e s s a g g i o   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 	 s t r M e s s a g g i o F i n a l e   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 
 
         c o d R e s u l t   i n t e g e r : = n u l l ; 
 
         n u m e r o C a u s a l i   i n t e g e r : = n u l l ; 
 
         d a t e I n i z V a l   t i m e s t a m p : = n u l l ; 
 
 B E G I N 
 
 
 
 	 s t r M e s s a g g i o F i n a l e : = ' I n s e r i m e n t o   c a u s a l e   d i   g e n e r a l e   a m b i t o C o d e = ' | | a m b i t o C o d e | | ' . ' ; 
 
 
 
         c o d i c e R i s u l t a t o : = 0 ; 
 
         m e s s a g g i o R i s u l t a t o : = ' ' ; 
 
 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   c a u s a l i   d a   c r e a r e   i n   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i . ' ; 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
         w h e r e   b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . a m b i t o = a m b i t o C o d e 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   C a u s a l i   n o n   p r e s e n t i . ' ; 
 
         e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' P u l i z i a   b l a n c k   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i . ' ; 
 
         u p d a t e   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o 
 
         s e t         p d c _ f i n = l t r i m ( r t r i m ( b k o . p d c _ f i n ) ) , 
 
                       c o d i c e _ c a u s a l e = l t r i m ( r t r i m ( b k o . c o d i c e _ c a u s a l e ) ) , 
 
                       d e s c r i z i o n e _ c a u s a l e = l t r i m ( r t r i m ( b k o . d e s c r i z i o n e _ c a u s a l e ) ) , 
 
                       p d c _ e c o n _ p a t r = l t r i m ( r t r i m ( b k o . p d c _ e c o n _ p a t r ) ) , 
 
                       s e g n o = l t r i m ( r t r i m ( b k o . s e g n o ) ) , 
 
                       c o n t o _ i v a = l t r i m ( r t r i m ( b k o . c o n t o _ i v a ) ) , 
 
                       l i v e l l i = l t r i m ( r t r i m ( b k o . l i v e l l i ) ) , 
 
                       t i p o _ c o n t o = l t r i m ( r t r i m ( b k o . t i p o _ c o n t o ) ) , 
 
                       t i p o _ i m p o r t o = l t r i m ( r t r i m ( b k o . t i p o _ i m p o r t o ) ) , 
 
                       u t i l i z z o _ c o n t o = l t r i m ( r t r i m ( b k o . u t i l i z z o _ c o n t o ) ) , 
 
                       u t i l i z z o _ i m p o r t o = l t r i m ( r t r i m ( b k o . u t i l i z z o _ i m p o r t o ) ) , 
 
                       c a u s a l e _ d e f a u l t = l t r i m ( r t r i m ( b k o . c a u s a l e _ d e f a u l t ) ) 
 
         w h e r e   b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . a m b i t o = a m b i t o C o d e 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 s t r M e s s a g g i o : = ' P u l i z i a   b l a n c k   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o . ' ; 
 
 	 u p d a t e   s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o 
 
 	 s e t         p d c _ f i n = l t r i m ( r t r i m ( b k o . p d c _ f i n ) ) , 
 
         	       c o d i c e _ c a u s a l e = l t r i m ( r t r i m ( b k o . c o d i c e _ c a u s a l e ) ) , 
 
 	 	       t i p o _ e v e n t o = l t r i m ( r t r i m ( b k o . t i p o _ e v e n t o ) ) , 
 
 	 	       e v e n t o = l t r i m ( r t r i m ( b k o . e v e n t o ) ) 
 
         w h e r e   b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . a m b i t o = a m b i t o C o d e 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         d a t e I n i z V a l : = ( a n n o B i l a n c i o : : v a r c h a r | | ' - 0 1 - 0 1 ' ) : : t i m e s t a m p ; 
 
 
 
         - -   s i a c _ t _ c a u s a l e _ e p 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   [ s i a c _ t _ c a u s a l e _ e p ] . ' ; 
 
         i n s e r t   i n t o   s i a c _ t _ c a u s a l e _ e p 
 
         ( 
 
             c a u s a l e _ e p _ c o d e , 
 
             c a u s a l e _ e p _ d e s c , 
 
             c a u s a l e _ e p _ t i p o _ i d , 
 
             a m b i t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             l o g i n _ c r e a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t   b k o . c o d i c e _ c a u s a l e , 
 
                       b k o . d e s c r i z i o n e _ c a u s a l e , 
 
                       t i p o . c a u s a l e _ e p _ t i p o _ i d , 
 
                       a m b i t o . a m b i t o _ i d , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' @ ' | | b k o . p d c _ f i n , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u , 
 
                       t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o , s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ d _ c a u s a l e _ e p _ t i p o   t i p o , 
 
                   s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o . c a u s a l e _ e p _ t i p o _ c o d e = b k o . c a u s a l e _ t i p o 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
   - -       a n d       b k o . e u = ' U ' 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ t _ c a u s a l e _ e p   e p 
 
         w h e r e   e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       e p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       e p . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) ; 
 
 	 G E T   D I A G N O S T I C S   n u m e r o C a u s a l i   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( n u m e r o C a u s a l i , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
 
 
         r a i s e   n o t i c e   ' n u m e r o C a u s a l i = % ' , n u m e r o C a u s a l i ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i     -   s t a t o   [ s i a c _ r _ c a u s a l e _ e p _ s t a t o ] . ' ; 
 
         - -   s i a c _ r _ c a u s a l e _ e p _ s t a t o 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ s t a t o 
 
         ( 
 
                 c a u s a l e _ e p _ i d , 
 
                 c a u s a l e _ e p _ s t a t o _ i d , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   e p . c a u s a l e _ e p _ i d , 
 
                       s t a t o . c a u s a l e _ e p _ s t a t o _ i d , 
 
                       d a t e I n i z V a l , 
 
                       e p . l o g i n _ o p e r a z i o n e , 
 
                       s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ d _ c a u s a l e _ e p _ s t a t o   s t a t o   , s i a c _ t _ c a u s a l e _ e p   e p ,   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       s t a t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       s t a t o . c a u s a l e _ e p _ s t a t o _ c o d e = ' V ' 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' ; 
 
         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % ' ; 
 
 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o S t a t o C a u s a l i = % ' , c o d R e s u l t ; 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i     -   P d c F i n   [ s i a c _ r _ c a u s a l e _ e p _ c l a s s ] . ' ; 
 
 
 
         - -   s i a c _ r _ c a u s a l e _ e p _ c l a s s 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ c l a s s 
 
         ( 
 
                 c a u s a l e _ e p _ i d , 
 
                 c l a s s i f _ i d , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   e p . c a u s a l e _ e p _ i d , 
 
                       c . c l a s s i f _ i d , 
 
                       d a t e I n i z V a l , 
 
                       e p . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ c a u s a l e _ e p   e p ,   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ t _ c l a s s   c , s i a c _ d _ c l a s s _ t i p o   t i p o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d   = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       t i p o . c l a s s i f _ t i p o _ c o d e = ' P D C _ V ' 
 
         a n d       c . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' 
 
         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % ' 
 
         a n d       c . c l a s s i f _ c o d e = s u b s t r i n g ( e p . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   e p . l o g i n _ o p e r a z i o n e ) + 1 ) 
 
         a n d       c . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o P d c F i n C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   p d c C o n t o E c o n   -   P d c F i n   [ s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o ] . ' ; 
 
         - -   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o 
 
         ( 
 
             c a u s a l e _ e p _ i d , 
 
             p d c e _ c o n t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       e p . c a u s a l e _ e p _ i d , 
 
                       c o n t o . p d c e _ c o n t o _ i d , 
 
                       d a t e I n i z V a l , 
 
 - -                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | b k o . e u | | ' @ ' | | b k o . c a r i c a _ c a u _ i d : : v a r c h a r , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u , 
 
                       c o n t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ c a u s a l e _ e p   e p ,   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o , 
 
                   s i a c _ t _ p d c e _ c o n t o   c o n t o , s i a c _ d _ a m b i t o   a m b i t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' 
 
         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c _ e c o n _ p a t r 
 
         a n d       c o n t o . a m b i t o _ i d = e p . a m b i t o _ i d 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r 1 
 
         w h e r e   r 1 . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r 1 . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
         a n d       r 1 . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
 - -         a n d       b k o . e u = ' U ' 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c o n t o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o C o n t i C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
         - -   s e g n o 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   p d c C o n t o E c o n   -   S E G N O     [ s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r ] . ' ; 
 
 	 i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r ,   s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ d _ a m b i t o   a m b i t o , s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 	 a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c _ e c o n _ p a t r 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u - - | | ' % ' 
 
         a n d       r . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
         a n d       r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 - -         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . s e g n o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 - -         a n d       b k o . e u = ' U ' 
 
 	 a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o C o n t i S E G N O C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   p d c C o n t o E c o n   -   T I P O   I M P O R T O     [ s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r ] . ' ; 
 
         - -   t i p o _ i m p o r t o 
 
       / *   i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . t i p o _ i m p o r t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
     - -     a n d       b k o . e u = ' U ' 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; * / 
 
 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r ,   s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ d _ a m b i t o   a m b i t o , s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 	 a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c _ e c o n _ p a t r 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u - - | | ' % ' 
 
         a n d       r . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
         a n d       r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 - -         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . t i p o _ i m p o r t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 - -         a n d       b k o . e u = ' U ' 
 
 	 a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
 
 
         r a i s e   n o t i c e   ' n u m e r o C o n t i T I P O I M P O R T O C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
         - -   u t i l i z z o _ c o n t o 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   p d c C o n t o E c o n   -   U T I L I Z Z O   C O N T O     [ s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r ] . ' ; 
 
         / * i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . u t i l i z z o _ c o n t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 - -         a n d       b k o . e u = ' U ' 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; * / 
 
 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r ,   s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ d _ a m b i t o   a m b i t o , s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 	 a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c _ e c o n _ p a t r 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u - - | | ' % ' 
 
         a n d       r . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
         a n d       r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 - -         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . u t i l i z z o _ c o n t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 - -         a n d       b k o . e u = ' U ' 
 
 	 a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o C o n t i U T I L I Z Z O C O N T O C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
         - -   u t i l i z z o _ i m p o r t o 
 
         c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   p d c C o n t o E c o n   -   U T I L I Z Z O   I M P O R T O     [ s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r ] . ' ; 
 
         / * i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 - -         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' % U % ' 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . u t i l i z z o _ i m p o r t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
     - -     a n d       b k o . e u = ' U ' 
 
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; * / 
 
 
 
         i n s e r t   i n t o   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r 
 
         ( 
 
             c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
             o p e r _ e p _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d , 
 
                       o p e r . o p e r _ e p _ i d , 
 
                       d a t e I n i z V a l , 
 
                       r . l o g i n _ o p e r a z i o n e , 
 
                       e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e ,   s i a c _ b k o _ t _ c a r i c a m e n t o _ c a u s a l i   b k o   ,   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o   r , 
 
                   s i a c _ d _ o p e r a z i o n e _ e p   o p e r ,   s i a c _ t _ c a u s a l e _ e p   e p , s i a c _ d _ a m b i t o   a m b i t o , s i a c _ t _ p d c e _ c o n t o   c o n t o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       b k o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
 	 a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
 
         a n d       e p . c a u s a l e _ e p _ c o d e = b k o . c o d i c e _ c a u s a l e 
 
         a n d       a m b i t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       a m b i t o . a m b i t o _ c o d e = b k o . a m b i t o 
 
         a n d       e p . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       c o n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       c o n t o . p d c e _ c o n t o _ c o d e = b k o . p d c _ e c o n _ p a t r 
 
         a n d       c o n t o . a m b i t o _ i d = a m b i t o . a m b i t o _ i d 
 
         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       r . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u - - | | ' % ' 
 
         a n d       r . c a u s a l e _ e p _ i d = e p . c a u s a l e _ e p _ i d 
 
         a n d       r . p d c e _ c o n t o _ i d = c o n t o . p d c e _ c o n t o _ i d 
 
 - -         a n d       b k o . c a r i c a _ c a u _ i d = s u b s t r i n g ( r . l o g i n _ o p e r a z i o n e ,   p o s i t i o n ( ' @ '   i n   r . l o g i n _ o p e r a z i o n e ) + 1 ) : : i n t e g e r 
 
         a n d       o p e r . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       o p e r . o p e r _ e p _ c o d e = u p p e r ( b k o . u t i l i z z o _ i m p o r t o ) 
 
         a n d       b k o . c a r i c a t a = f a l s e 
 
 - -         a n d       b k o . e u = ' U ' 
 
 	 a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ c a u s a l e _ e p _ p d c e _ c o n t o _ o p e r   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ p d c e _ c o n t o _ i d = r . c a u s a l e _ e p _ p d c e _ c o n t o _ i d 
 
         a n d       r 1 . o p e r _ e p _ i d = o p e r . o p e r _ e p _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0     t h e n 
 
         	 r a i s e   e x c e p t i o n   '   I n s e r i m e n t o   n o n   e f f e t t u a t o . ' ; 
 
         e n d   i f ; 
 
         r a i s e   n o t i c e   ' n u m e r o C o n t i U T I L I Z Z O I M P O R T O C a u s a l i = % ' , c o d R e s u l t ; 
 
 
 
 	 c o d R e s u l t : = n u l l ; 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   c a u s a l i   -   e v e n t o       [ s i a c _ r _ c a u s a l e _ e v e n t o ] . ' ; 
 
         - -   s i a c _ r _ e v e n t o _ c a u s a l e 
 
         i n s e r t   i n t o   s i a c _ r _ e v e n t o _ c a u s a l e 
 
         ( 
 
             c a u s a l e _ e p _ i d , 
 
             e v e n t o _ i d , 
 
             v a l i d i t a _ i n i z i o , 
 
             l o g i n _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       e p . c a u s a l e _ e p _ i d , 
 
                       e v e n t o . e v e n t o _ i d , 
 
                       d a t e I n i z V a l , 
 
                       b k o . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e , 
 
                       e p . e n t e _ p r o p r i e t a r i o _ i d 
 
         f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e , s i a c _ b k o _ t _ c a u s a l e _ e v e n t o   b k o , s i a c _ t _ c a u s a l e _ e p   e p , 
 
                   s i a c _ d _ e v e n t o   e v e n t o , s i a c _ d _ e v e n t o _ t i p o   t i p o 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       e p . e n t e _ p r o p r i e t a r i o _ i d = e n t e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e p . l o g i n _ o p e r a z i o n e   l i k e   ' % ' | | l o g i n O p e r a z i o n e | | ' - ' | | b k o . e u | | ' % ' 
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
         a n d       n o t   e x i s t s 
 
         ( 
 
         s e l e c t   1   f r o m   s i a c _ r _ e v e n t o _ c a u s a l e   r 1 
 
         w h e r e   r 1 . c a u s a l e _ e p _ i d   =   e p . c a u s a l e _ e p _ i d 
 
         a n d       r 1 . e v e n t o _ i d = e v e n t o . e v e n t o _ i d 
 
         a n d       r 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
       - -   a n d       b k o . e u = ' U ' 
 
         a n d       b k o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       b k o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
         G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
         r a i s e   n o t i c e   ' n u m e r o C a u s a l i E v e n t o = % ' , c o d R e s u l t ; 
 
 
 
         m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | '   I n s e r i t e   ' | | n u m e r o C a u s a l i : : v a r c h a r | | '   c a u s a l i . ' ; 
 
 
 
         r a i s e   n o t i c e   ' % ' , m e s s a g g i o R i s u l t a t o ; 
 
 
 
         r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E :     ' | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' )   ; 
 
               	 c o d i c e R i s u l t a t o : = - 1 ; 
 
 
 
 	 	 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   N O _ D A T A _ F O U N D   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   N e s s u n   d a t o   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   D B : ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
                 r e t u r n ; 
 
 
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