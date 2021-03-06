/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
��C R E A T E   O R   R E P L A C E   F U N C T I O N   f n c _ m i f _ o r d i n a t i v o _ s p e s a _ s p l u s   ( 
 
     e n t e p r o p r i e t a r i o i d   i n t e g e r , 
 
     n o m e e n t e   v a r c h a r , 
 
     a n n o b i l a n c i o   v a r c h a r , 
 
     l o g i n o p e r a z i o n e   v a r c h a r , 
 
     d a t a e l a b o r a z i o n e   t i m e s t a m p , 
 
     m i f o r d r i t r a s m e l a b i d   i n t e g e r , 
 
     o u t   f l u s s o e l a b m i f d i s t o i l i d   i n t e g e r , 
 
     o u t   f l u s s o e l a b m i f i d   i n t e g e r , 
 
     o u t   n u m e r o o r d i n a t i v i t r a s m   i n t e g e r , 
 
     o u t   n o m e f i l e m i f   v a r c h a r , 
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
 
 
 
 
   s t r M e s s a g g i o   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
   s t r M e s s a g g i o F i n a l e   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
   s t r M e s s a g g i o S c a r t o   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
   s t r E x e c S q l   V A R C H A R ( 1 5 0 0 ) : = ' ' ; 
 
 
 
   m i f O r d i n a t i v o I d R e c   r e c o r d ; 
 
 
 
   m i f F l u s s o O r d i n a t i v o R e c     m i f _ t _ o r d i n a t i v o _ s p e s a % r o w t y p e ; 
 
 
 
 
 
   m i f F l u s s o E l a b M i f A r r   f l u s s o E l a b M i f R e c T y p e [ ] ; 
 
 
 
 
 
 
 
   m i f C o u n t R e c   i n t e g e r : = 1 ; 
 
   m i f C o u n t T m p R e c   i n t e g e r : = 1 ; 
 
   m i f A F l u s s o E l a b T y p e R e c     f l u s s o E l a b M i f R e c T y p e ; 
 
   f l u s s o E l a b M i f E l a b R e c     f l u s s o E l a b M i f R e c T y p e ; 
 
   m i f E l a b R e c   r e c o r d ; 
 
 
 
   a t t o A m m R e c   r e c o r d ; 
 
   e n t e O i l R e c   r e c o r d ; 
 
   e n t e P r o p r i e t a r i o R e c   r e c o r d ; 
 
   s o g g e t t o R e c   r e c o r d ; 
 
   s o g g e t t o S e d e R e c   r e c o r d ; 
 
   s o g g e t t o Q u i e t R e c   r e c o r d ; 
 
   s o g g e t t o Q u i e t R i f R e c   r e c o r d ; 
 
   M D P R e c   r e c o r d ; 
 
   c o d A c c r e R e c   r e c o r d ; 
 
   b i l E l e m R e c   r e c o r d ; 
 
   i n d i r i z z o R e c   r e c o r d ; 
 
   o r d S o s t R e c   r e c o r d ; 
 
 
 
 
 
   t i p o P a g a m R e c   r e c o r d ; 
 
   r i t e n u t a R e c   r e c o r d ; 
 
   r i c e v u t a R e c   r e c o r d ; 
 
   q u o t e O r d i n a t i v o R e c   r e c o r d ; 
 
   o r d R e c   r e c o r d ; 
 
 
 
 
 
   i s I n d i r i z z o B e n e f   b o o l e a n : = f a l s e ; 
 
   i s I n d i r i z z o B e n Q u i e t   b o o l e a n : = f a l s e ; 
 
 
 
   f l u s s o E l a b M i f V a l o r e   v a r c h a r   ( 1 0 0 0 ) : = n u l l ; 
 
   f l u s s o E l a b M i f V a l o r e D e s c   v a r c h a r   ( 1 0 0 0 ) : = n u l l ; 
 
 
 
   o r d N u m e r o   n u m e r i c : = n u l l ; 
 
   o r d A n n o     i n t e g e r : = n u l l ; 
 
   a t t o A m m T i p o S p r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a t t o A m m T i p o A l l   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a t t o A m m T i p o A l l A l l   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
   a t t o A m m S t r T i p o R a g     v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a t t o A m m T i p o A l l R a g   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
 
 
   t i p o M D P C b i   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o M D P C s i   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o M D P C o     v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o M D P C C P   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o M D P C B     v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o P a e s e C B   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a v v i s o T i p o M D P C o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e C g e     v a r c h a r ( 5 0 ) : = n u l l ; 
 
   s i o p e D e f       v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d R e s u l t       i n t e g e r : = n u l l ; 
 
 
 
   i n d i r i z z o E n t e   v a r c h a r ( 5 0 0 ) : = n u l l ; 
 
   l o c a l i t a E n t e   v a r c h a r ( 5 0 0 ) : = n u l l ; 
 
   s o g g e t t o E n t e I d   I N T E G E R : = n u l l ; 
 
   s o g g e t t o R i f I d   i n t e g e r : = n u l l ; 
 
   s o g g e t t o S e d e S e c I d   i n t e g e r : = n u l l ; 
 
   s o g g e t t o Q u i e t I d   i n t e g e r : = n u l l ; 
 
   s o g g e t t o Q u i e t R i f I d   i n t e g e r : = n u l l ; 
 
   a c c r e d i t o G r u p p o C o d e   v a r c h a r ( 1 5 ) : = n u l l ; 
 
 
 
 
 
 
 
 
 
   f l u s s o E l a b M i f L o g I d     i n t e g e r   : = n u l l ; 
 
   f l u s s o E l a b M i f T i p o I d   i n t e g e r   : = n u l l ; 
 
   f l u s s o E l a b M i f T i p o N o m e F i l e   v a r c h a r ( 5 0 0 ) : = n u l l ; 
 
   f l u s s o E l a b M i f T i p o D e c   B O O L E A N : = f a l s e ; 
 
   f l u s s o E l a b M i f O i l I d   i n t e g e r   : = n u l l ; 
 
   f l u s s o E l a b M i f D i s t O i l R e t I d   i n t e g e r : = n u l l ; 
 
   m i f O r d S p e s a I d   i n t e g e r : = n u l l ; 
 
 
 
   d a t a I n i z i o V a l   t i m e s t a m p   : = a n n o B i l a n c i o | | ' - 0 1 - 0 1 ' ; 
 
   d a t a F i n e V a l   t i m e s t a m p   : = a n n o B i l a n c i o | | ' - 1 2 - 3 1 ' ; 
 
 
 
 
 
   o r d I m p o r t o   n u m e r i c   : = 0 ; 
 
 
 
 
 
   o r d T i p o C o d e I d   i n t e g e r   : = n u l l ; 
 
   o r d S t a t o C o d e I I d     i n t e g e r   : = n u l l ; 
 
   o r d S t a t o C o d e A I d     i n t e g e r   : = n u l l ; 
 
 
 
   c l a s s C d r T i p o I d   I N T E G E R : = n u l l ; 
 
   c l a s s C d c T i p o I d   I N T E G E R : = n u l l ; 
 
   o r d D e t T s T i p o I d   i n t e g e r   : = n u l l ; 
 
 
 
   o r d S e d e S e c R e l a z T i p o I d   i n t e g e r : = n u l l ; 
 
   o r d R e l a z C o d e T i p o I d   i n t e g e r   : = n u l l ; 
 
   o r d C s i R e l a z T i p o I d     i n t e g e r : = n u l l ; 
 
 
 
   n o t e O r d A t t r I d   i n t e g e r : = n u l l ; 
 
 
 
   m o v g e s t T s T i p o S u b I d   i n t e g e r : = n u l l ; 
 
 
 
 
 
   f a m T i t S p e M a c r o A g g r C o d e I d   i n t e g e r : = n u l l ; 
 
   t i t o l o U s c i t a C o d e T i p o I d   i n t e g e r   : = n u l l ; 
 
   p r o g r a m m a C o d e T i p o I d   i n t e g e r   : = n u l l ; 
 
   p r o g r a m m a C o d e T i p o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   f a m M i s s P r o g r C o d e   V A R C H A R ( 5 0 ) : = n u l l ; 
 
   f a m M i s s P r o g r C o d e I d   i n t e g e r : = n u l l ; 
 
   p r o g r a m m a I d   i n t e g e r   : = n u l l ; 
 
   t i t o l o U s c i t a I d   i n t e g e r : = n u l l ; 
 
 
 
 
 
 
 
   i s P a e s e S e p a   i n t e g e r : = n u l l ; 
 
   o r d C o d i c e B o l l o     v a r c h a r ( 1 0 ) : = n u l l ; 
 
   o r d C o d i c e B o l l o D e s c   v a r c h a r ( 5 0 0 ) : = n u l l ; 
 
   o r d D a t a S c a d e n z a   t i m e s t a m p : = n u l l ; 
 
 
 
   o r d C s i R e l a z T i p o   v a r c h a r ( 2 0 ) : = n u l l ; 
 
   o r d C s i C O T i p o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
 
 
   a m b i t o F i n I d   i n t e g e r : = n u l l ; 
 
   a n a g r a f i c a B e n e f C B I   v a r c h a r ( 5 0 0 ) : = n u l l ; 
 
 
 
   i s D e f A n n o R e d i s u o     v a r c h a r ( 5 ) : = n u l l ; 
 
 
 
 
 
   - -   r i t e n u t e 
 
   t i p o R e l a z R i t O r d   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   t i p o R e l a z S p r O r d   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   t i p o R e l a z S u b O r d   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   t i p o R i t e n u t a   v a r c h a r ( 1 0 ) : = ' R ' ; 
 
   p r o g r R i t e n u t a     v a r c h a r ( 1 0 ) : = n u l l ; 
 
   i s R i t e n u t a A t t i v o   b o o l e a n : = f a l s e ; 
 
   t i p o O n e r e I r p e f I d   i n t e g e r : = n u l l ; 
 
   t i p o O n e r e I n p s I d   i n t e g e r : = n u l l ; 
 
   t i p o O n e r e I r p e f   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   t i p o O n e r e I n p s   v a r c h a r ( 1 0 ) : = n u l l ; 
 
 
 
   t i p o O n e r e I r p e g I d   i n t e g e r : = n u l l ; 
 
   t i p o O n e r e I r p e g   v a r c h a r ( 1 0 ) : = n u l l ; 
 
 
 
   c o d i c e U E C o d e T i p o   V A R C H A R ( 5 0 ) : = n u l l ; 
 
   c o d i c e U E C o d e T i p o I d   i n t e g e r : = n u l l ; 
 
   c o d i c e C o f o g C o d e T i p o     V A R C H A R ( 5 0 ) : = n u l l ; 
 
   c o d i c e C o f o g C o d e T i p o I d   i n t e g e r : = n u l l ; 
 
   s i o p e C o d e T i p o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   s i o p e C o d e T i p o I d   i n t e g e r   : = n u l l ; 
 
   e v e n t o T i p o C o d e I d   i n t e g e r : = n u l l ; 
 
   c o l l E v e n t o C o d e I d   i n t e g e r : = n u l l ; 
 
 
 
   c l a s s i f T i p o C o d e F r a z         v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c l a s s i f T i p o C o d e F r a z V a l   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c l a s s i f T i p o C o d e F r a z I d       i n t e g e r : = n u l l ; 
 
 
 
   t i p o C l a s s F r u t t i f e r o   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o S t r   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o S t r A l t r o   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   t i p o C l a s s F r u t t i f e r o I d   i n t e g e r : = n u l l ; 
 
   v a l F r u t t i f e r o I d     i n t e g e r : = n u l l ; 
 
 
 
   c l a s s V i n c o l a t o C o d e       v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   c l a s s V i n c o l a t o C o d e I d   I N T E G E R : = n u l l ; 
 
   v a l F r u t t i f e r o C l a s s C o d e       v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o C l a s s C o d e I d   I N T E G E R : = n u l l ; 
 
   v a l F r u t t i f e r o C l a s s C o d e S I   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o C o d e S I   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o C l a s s C o d e N O   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   v a l F r u t t i f e r o C o d e N O   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
 
 
   c i g C a u s A t t r I d   I N T E G E R : = n u l l ; 
 
   c u p C a u s A t t r I d   I N T E G E R : = n u l l ; 
 
   c i g C a u s A t t r       v a r c h a r ( 1 0 ) : = n u l l ; 
 
   c u p C a u s A t t r       v a r c h a r ( 1 0 ) : = n u l l ; 
 
 
 
 
 
   c o d i c e P a e s e I T   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e A c c r e C B   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e A c c r e C O   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e A c c r e R E G   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e S e p a           v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e E x t r a S e p a   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e G F B     v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
   s e p a C r e d i t T r a n s f e r   b o o l e a n : = f a l s e ; 
 
   a c c r e d i t o G r u p p o S e p a T r   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   S e p a T r   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   p a e s e S e p a T r   v a r c h a r ( 1 0 ) : = n u l l ; 
 
 
 
 
 
   n u m e r o D o c s   v a r c h a r ( 1 0 ) : = n u l l ; 
 
   t i p o D o c s   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o D o c s C o m m   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t i p o G r u p p o D o c s   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
   t i p o E s e r c i z i o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   s t a t o B e n e f i c i a r i o   b o o l e a n   : = f a l s e ; 
 
   b a v v i o F r a z A t t r   b o o l e a n   : = f a l s e ; 
 
   d a t a A v v i o F r a z A t t r   t i m e s t a m p : = n u l l ; 
 
   a t t r f r a z i o n a b i l e   V A R C H A R ( 5 0 ) : = n u l l ; 
 
 
 
   d a t a A v v i o S i o p e N e w   V A R C H A R ( 5 0 ) : = n u l l ; 
 
   b A v v i o S i o p e N e w       b o o l e a n : = f a l s e ; 
 
 
 
 
 
   t i p o P a g a m P o s t A   V A R C H A R ( 1 0 0 ) : = n u l l ; 
 
   t i p o P a g a m P o s t B   V A R C H A R ( 1 0 0 ) : = n u l l ; 
 
 
 
   c u p A t t r C o d e I d   I N T E G E R : = n u l l ; 
 
   c u p A t t r C o d e       v a r c h a r ( 1 0 ) : = n u l l ; 
 
   c i g A t t r C o d e I d   I N T E G E R : = n u l l ; 
 
   c i g A t t r C o d e       v a r c h a r ( 1 0 ) : = n u l l ; 
 
   r i c o r r e n t e C o d e T i p o   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   r i c o r r e n t e C o d e T i p o I d   i n t e g e r : = n u l l ; 
 
 
 
   c o d i c e B o l l o P l u s E s e n t e   b o o l e a n : = f a l s e ; 
 
   c o d i c e B o l l o P l u s D e s c       v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
 
 
   s t a t o D e l e g a t o C r e d E f f   b o o l e a n   : = f a l s e ; 
 
 
 
   c o m P c c A t t r I d   i n t e g e r : = n u l l ; 
 
   p c c O p e r a z T i p o I d   i n t e g e r : = n u l l ; 
 
 
 
 
 
   - -   T r a n s a z i o n e   e l e m e n t a r e 
 
   p r o g r a m m a T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e F i n V T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e E c o n P a t T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o f o g T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   t r a n s a z i o n e U e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   s i o p e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c u p T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   r i c o r r e n t e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a s l T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   p r o g r R e g U n i t T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
   c o d i c e F i n V T i p o T b r I d   i n t e g e r : = n u l l ; 
 
   c u p A t t r I d   i n t e g e r : = n u l l ; 
 
   r i c o r r e n t e T i p o T b r I d   i n t e g e r : = n u l l ; 
 
   a s l T i p o T b r I d   i n t e g e r : = n u l l ; 
 
   p r o g r R e g U n i t T i p o T b r I d   i n t e g e r : = n u l l ; 
 
 
 
   c o d i c e F i n V C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o n t o E c o n C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o f o g C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c o d i c e U e C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   s i o p e C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   c u p A t t r T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   r i c o r r e n t e C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
   a s l C o d e T b r     v a r c h a r ( 5 0 ) : = n u l l ; 
 
   p r o g r R e g U n i t C o d e T b r   v a r c h a r ( 5 0 ) : = n u l l ; 
 
 
 
 
 
 
 
   i s G e s t i o n e Q u o t e O K   b o o l e a n : = f a l s e ; 
 
   i s G e s t i o n e F a t t u r e   b o o l e a n : = f a l s e ; 
 
   i s R i c e v u t a A t t i v o   b o o l e a n : = f a l s e ; 
 
   i s T r a n s E l e m A t t i v a   b o o l e a n : = f a l s e ; 
 
   i s M D P C o   b o o l e a n : = f a l s e ; 
 
   i s O r d P i a z z a t u r a   b o o l e a n : = f a l s e ; 
 
 
 
   d o c A n a l o g i c o         v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   t i t o l o C o r r e n t e       v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   d e s c r i T i t o l o C o r r e n t e   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   t i t o l o C a p i t a l e       v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   d e s c r i T i t o l o C a p i t a l e   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
 
 
   - -   2 0 . 0 2 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 8 4 9 
 
   d e f N a t u r a P a g     v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
 
 
   a t t r C o d e D a t a S c a d   v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
   t i t o l o C a p     v a r c h a r ( 1 0 0 ) : = n u l l ; 
 
 
 
   i s O r d C o m m e r c i a l e   b o o l e a n : = f a l s e ; 
 
   - -   2 0 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 8 
 
   t i p o P d c I V A   V A R C H A R ( 1 0 0 ) : = n u l l ; 
 
   c o d e P d c I V A   V A R C H A R ( 1 0 0 ) : = n u l l ; 
 
 
 
   - -   0 9 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0 
 
   i s P a g o P A   b o o l e a n : = f a l s e ; 
 
 
 
   N V L _ S T R                               C O N S T A N T   V A R C H A R : = ' ' ; 
 
 
 
 
 
   O R D _ T I P O _ C O D E _ P     C O N S T A N T     v a r c h a r   : = ' P ' ; 
 
   O R D _ S T A T O _ C O D E _ I   C O N S T A N T     v a r c h a r   : = ' I ' ; 
 
   O R D _ S T A T O _ C O D E _ A   C O N S T A N T     v a r c h a r   : = ' A ' ; 
 
   O R D _ R E L A Z _ C O D E _ S O S     C O N S T A N T     v a r c h a r   : = ' S O S _ O R D ' ; 
 
   O R D _ T I P O _ A   C O N S T A N T     v a r c h a r   : = ' A ' ; 
 
 
 
   O R D _ R E L A Z _ S E D E _ S E C   C O N S T A N T     v a r c h a r   : = ' S E D E _ S E C O N D A R I A ' ; 
 
   A M B I T O _ F I N   C O N S T A N T     v a r c h a r   : = ' A M B I T O _ F I N ' ; 
 
 
 
   N O T E _ O R D _ A T T R   C O N S T A N T     v a r c h a r   : = ' N O T E _ O R D I N A T I V O ' ; 
 
 
 
   C D C   C O N S T A N T   v a r c h a r : = ' C D C ' ; 
 
   C D R   C O N S T A N T   v a r c h a r : = ' C D R ' ; 
 
 
 
 
 
   P R O G R A M M A                               C O N S T A N T   v a r c h a r : = ' P R O G R A M M A ' ; 
 
   T I T O L O _ S P E S A                         C O N S T A N T   v a r c h a r : = ' T I T O L O _ S P E S A ' ; 
 
   F A M _ T I T _ S P E _ M A C R O A G G R E G   C O N S T A N T   v a r c h a r : = ' S p e s a   -   T i t o l i M a c r o a g g r e g a t i ' ; 
 
 
 
   F U N Z I O N E _ C O D E _ I   C O N S T A N T     v a r c h a r   : = ' I N S E R I M E N T O ' ;   - -   i n s e r i m e n t i 
 
   F U N Z I O N E _ C O D E _ S   C O N S T A N T     v a r c h a r   : = ' S O S T I T U Z I O N E ' ;   - -   s o s t i t u z i o n i   s e n z a   t r a s m i s s i o n e 
 
   F U N Z I O N E _ C O D E _ N   C O N S T A N T     v a r c h a r   : = ' A N N U L L O ' ;   - -   a n n u l l a m e n t i   p r i m a   d i   t r a s m i s s i o n e 
 
 
 
   F U N Z I O N E _ C O D E _ A   C O N S T A N T     v a r c h a r   : = ' A N N U L L O ' ;   - -   a n n u l l a m e n t i   d o p o   t r a s m i s s i o n e 
 
   F U N Z I O N E _ C O D E _ V B   C O N S T A N T     v a r c h a r   : = ' V A R I A Z I O N E ' ;   - -   s p o s t a m e n t i   d o p o   t r a s m i s s i o n e 
 
 
 
 
 
   O R D _ T S _ D E T _ T I P O _ A   C O N S T A N T   v a r c h a r : = ' A ' ; 
 
   M O V G E S T _ T S _ T I P O _ S     C O N S T A N T   v a r c h a r : = ' S ' ; 
 
 
 
   S P A C E _ A S C I I   C O N S T A N T   i n t e g e r : = 3 2 ; 
 
   V T _ A S C I I   C O N S T A N T   i n t e g e r : = 1 3 ; 
 
   B S _ A S C I I   C O N S T A N T   i n t e g e r : = 1 0 ; 
 
 
 
   N U M _ S E T T E   C O N S T A N T   i n t e g e r : = 7 ; 
 
   N U M _ D O D I C I   C O N S T A N T   i n t e g e r : = 1 2 ; 
 
   Z E R O _ P A D   C O N S T A N T     v a r c h a r   : = ' 0 ' ; 
 
 
 
   E L A B _ M I F _ E S I T O _ I N   C O N S T A N T     v a r c h a r   : = ' I N ' ; 
 
   M A N D M I F _ T I P O     C O N S T A N T     v a r c h a r   : = ' M A N D M I F _ S P L U S ' ; 
 
 
 
 
 
   C O M _ P C C _ A T T R     C O N S T A N T     v a r c h a r   : = ' f l a g C o m u n i c a P C C ' ; 
 
   P C C _ O P E R A Z _ C P A G     C O N S T A N T   v a r c h a r : = ' C P ' ; 
 
 
 
   S E P A R A T O R E           C O N S T A N T     v a r c h a r   : = ' | ' ; 
 
 
 
 
 
 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ A B I _ B T             C O N S T A N T   i n t e g e r : = 1 ;     - -   c o d i c e _ A B I _ B T 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ E N T E _ I P A         C O N S T A N T   i n t e g e r : = 4 ;     - -   c o d i c e _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ D E S C _ E N T E               C O N S T A N T   i n t e g e r : = 5 ;     - -   d e s c r i z i o n e _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ I S T A T _ E N T E     C O N S T A N T   i n t e g e r : = 6 ;     - -   c o d i c e _ i s t a t _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D F I S C _ E N T E         C O N S T A N T   i n t e g e r : = 7 ;     - -   c o d i c e _ f i s c a l e _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D T R A M I T E _ E N T E   C O N S T A N T   i n t e g e r : = 8 ;     - -   c o d i c e _ t r a m i t e _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D T R A M I T E _ B T       C O N S T A N T   i n t e g e r : = 9 ;     - -   c o d i c e _ t r a m i t e _ b t 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ E N T E _ B T           C O N S T A N T   i n t e g e r : = 1 0 ;   - -   c o d i c e _ e n t e _ b t 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ R I F E R I M E N T O _ E N T E   C O N S T A N T   i n t e g e r : = 1 1 ;   - -   r i f e r i m e n t o _ e n t e 
 
   F L U S S O _ M I F _ E L A B _ T E S T _ E S E R C I Z I O               C O N S T A N T   i n t e g e r : = 1 2 ;   - -   r i f e r i m e n t o _ e n t e 
 
 
 
   F L U S S O _ M I F _ E L A B _ I N I Z I O _ O R D           C O N S T A N T   i n t e g e r : = 1 3 ;     - -   t i p o _ o p e r a z i o n e 
 
 
 
   F L U S S O _ M I F _ E L A B _ F A T T U R E                 C O N S T A N T   i n t e g e r : = 5 3 ;     - -   f a t t u r a _ s i o p e _ c o d i c e _ i p a _ e n t e _ s i o p e 
 
   F L U S S O _ M I F _ E L A B _ F A T T _ C O D F I S C       C O N S T A N T   i n t e g e r : = 5 8 ;     - -   f a t t u r a _ s i o p e _ c o d i c e _ f i s c a l e _ e m i t t e n t e _ s i o p e 
 
   F L U S S O _ M I F _ E L A B _ F A T T _ D A T A S C A D _ P A G   C O N S T A N T   i n t e g e r : = 6 2 ;   - -   d a t a _ s c a d e n z a _ p a g a m _ s i o p e 
 
   F L U S S O _ M I F _ E L A B _ F A T T _ N A T U R A _ P A G   C O N S T A N T   i n t e g e r : = 6 4 ;   - -   n a t u r a _ s p e s a _ s i o p e 
 
   F L U S S O _ M I F _ E L A B _ N U M _ S O S P E S O         C O N S T A N T   i n t e g e r : = 1 2 2 ;   - -   n u m e r o _ p r o v v i s o r i o 
 
   F L U S S O _ M I F _ E L A B _ R I T E N U T A               C O N S T A N T   i n t e g e r : = 1 2 4 ;   - -   i m p o r t o _ r i t e n u t a 
 
   F L U S S O _ M I F _ E L A B _ R I T E N U T A _ P R G       C O N S T A N T   i n t e g e r : = 1 2 6 ;   - -   p r o g r e s s i v o _ v e r s a n t e 
 
 
 
 
 
   R E G M O V F I N _ S T A T O _ A                             C O N S T A N T   v a r c h a r : = ' A ' ; 
 
   S E G N O _ E C O N O M I C O 	 	 	 	 C O N S T A N T   v a r c h a r : = ' D a r e ' ; 
 
 
 
 
 
 
 
 B E G I N 
 
 
 
 	 n u m e r o O r d i n a t i v i T r a s m : = 0 ; 
 
         c o d i c e R i s u l t a t o : = 0 ; 
 
         m e s s a g g i o R i s u l t a t o : = ' ' ; 
 
 	 f l u s s o E l a b M i f I d : = n u l l ; 
 
         n o m e F i l e M i f : = n u l l ; 
 
 
 
         f l u s s o E l a b M i f D i s t O i l I d : = n u l l ; 
 
 
 
 	 s t r M e s s a g g i o F i n a l e : = ' I n v i o   o r d i n a t i v i   d i   s p e s a   S I O P E   P L U S . ' ; 
 
 
 
 
 
         - -   e n t e O i l R e c 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   e n t e   O I L     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         s e l e c t   *   i n t o   s t r i c t   e n t e O i l R e c 
 
         f r o m   s i a c _ t _ e n t e _ o i l   e n t e 
 
         w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       e n t e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       e n t e . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         i f   e n t e O i l R e c   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   r e p e r i m e n t o   d a t i ' ; 
 
         e n d   i f ; 
 
 
 
         i f   e n t e O i l R e c . e n t e _ o i l _ s i o p e _ p l u s = f a l s e   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   S I O P E   P L U S   n o n   a t t i v o   p e r   l ' ' e n t e . ' ; 
 
         e n d   i f ; 
 
 
 
         - -   i n s e r i m e n t o   r e c o r d   i n   t a b e l l a   m i f _ t _ f l u s s o _ e l a b o r a t o 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   m i f _ t _ f l u s s o _ e l a b o r a t o   t i p o   f l u s s o = ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
         i n s e r t   i n t o   m i f _ t _ f l u s s o _ e l a b o r a t o 
 
         ( f l u s s o _ e l a b _ m i f _ d a t a   , 
 
           f l u s s o _ e l a b _ m i f _ e s i t o , 
 
           f l u s s o _ e l a b _ m i f _ e s i t o _ m s g , 
 
           f l u s s o _ e l a b _ m i f _ f i l e _ n o m e , 
 
           f l u s s o _ e l a b _ m i f _ t i p o _ i d , 
 
           f l u s s o _ e l a b _ m i f _ i d _ f l u s s o _ o i l ,   - -   d a   c a l c o l a r e   s u   t a b   p r o g r e s s i v i 
 
           f l u s s o _ e l a b _ m i f _ c o d i c e _ f l u s s o _ o i l ,   - -   d a   c a l c o l a r e   s u   t a b   p r o g r e s s i v i 
 
           v a l i d i t a _ i n i z i o , 
 
           e n t e _ p r o p r i e t a r i o _ i d , 
 
           l o g i n _ o p e r a z i o n e ) 
 
           ( s e l e c t   d a t a E l a b o r a z i o n e , 
 
                           E L A B _ M I F _ E S I T O _ I N , 
 
                           ' E l a b o r a z i o n e   i n   c o r s o   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O , 
 
             	 	   t i p o . f l u s s o _ e l a b _ m i f _ n o m e _ f i l e , 
 
           	 	   t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d , 
 
           	 	   n u l l , - - f l u s s o E l a b M i f O i l I d ,   - -   d a   c a l c o l a r e   s u   t a b   p r o g r e s s i v i 
 
                           n u l l ,   - -   f l u s s o E l a b M i f D i s t O i l I d   - -   d a   c a l c o l a r e   s u   t a b   p r o g r e s s i v i 
 
         	 	   d a t a E l a b o r a z i o n e , 
 
           	 	   e n t e P r o p r i e t a r i o I d , 
 
             	 	   l o g i n O p e r a z i o n e 
 
             f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
             w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = M A N D M I F _ T I P O 
 
             a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
           ) 
 
           r e t u r n i n g   f l u s s o _ e l a b _ m i f _ i d   i n t o   f l u s s o E l a b M i f L o g I d ; - -   v a l o r e   d a   r e s t i t u i r e 
 
 
 
             r a i s e   n o t i c e   ' f l u s s o E l a b M i f L o g I d   % ' , f l u s s o E l a b M i f L o g I d ; 
 
 
 
           i f   f l u s s o E l a b M i f L o g I d   i s   n u l l   t h e n 
 
               R A I S E   E X C E P T I O N   '   E r r o r e   g e n e r i c o   i n   i n s e r i m e n t o   % . ' , M A N D M I F _ T I P O ; 
 
           e n d   i f ; 
 
 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   e l a b o r a z i o n i   i n   c o r s o   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	 c o d R e s u l t : = n u l l ; 
 
         s e l e c t   d i s t i n c t   1   i n t o   c o d R e s u l t 
 
         f r o m   m i f _ t _ f l u s s o _ e l a b o r a t o   e l a b ,     m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
         w h e r e     e l a b . f l u s s o _ e l a b _ m i f _ i d ! = f l u s s o E l a b M i f L o g I d 
 
         a n d         e l a b . f l u s s o _ e l a b _ m i f _ e s i t o = E L A B _ M I F _ E S I T O _ I N 
 
         a n d         e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d         e l a b . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d         t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d = e l a b . f l u s s o _ e l a b _ m i f _ t i p o _ i d 
 
         a n d         t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = M A N D M I F _ T I P O 
 
         a n d         t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d         t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d         t i p o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
         	 R A I S E   E X C E P T I O N   '   V e r i f i c a r e   s i t u a z i o n i   e s i s t e n t i . ' ; 
 
         e n d   i f ; 
 
 
 
         - -   v e r i f i c o   s e   l a   t a b e l l a   d e g l i   i d   c o n t i e n e   d a t i   i n   t a l   c a s o   e l a b o r a z i o n i   p r e c e d e n t i   s o n o   a n d a t e   m a l e 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         s e l e c t   d i s t i n c t   1   i n t o   c o d R e s u l t 
 
         f r o m   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m i f 
 
         w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d ; 
 
 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
             R A I S E   E X C E P T I O N   '   D a t i   p r e s e n t i   v e r i f i c a r n e   i l   c o n t e n u t o   e d   e f f e t t u a r e   p u l i z i a   p r i m a   d i   r i e s e g u i r e . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
         - -   r e c u p e r o   i n d e n t i f i c a t i v i   t i p i   c o d i c e   v a r i 
 
 	 b e g i n 
 
 
 
                 - -   o r d T i p o C o d e I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   o r d i n a t i v o   t i p o   C o d e   I d   ' | | O R D _ T I P O _ C O D E _ P | | ' . ' ; 
 
                 s e l e c t   o r d _ t i p o . o r d _ t i p o _ i d   i n t o   s t r i c t   o r d T i p o C o d e I d 
 
                 f r o m   s i a c _ d _ o r d i n a t i v o _ t i p o   o r d _ t i p o 
 
                 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       o r d _ t i p o . o r d _ t i p o _ c o d e = O R D _ T I P O _ C O D E _ P 
 
                 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
       	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 	 	 - -   o r d S t a t o C o d e I I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   o r d i n a t i v o   s t a t o   C o d e   I d   ' | | O R D _ S T A T O _ C O D E _ I | | ' . ' ; 
 
                 s e l e c t   o r d _ t i p o . o r d _ s t a t o _ i d   i n t o   s t r i c t   o r d S t a t o C o d e I I d 
 
                 f r o m   s i a c _ d _ o r d i n a t i v o _ s t a t o   o r d _ t i p o 
 
                 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       o r d _ t i p o . o r d _ s t a t o _ c o d e = O R D _ S T A T O _ C O D E _ I 
 
                 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                 - -   o r d S t a t o C o d e A I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   o r d i n a t i v o   s t a t o   C o d e   I d   ' | | O R D _ S T A T O _ C O D E _ A | | ' . ' ; 
 
                 s e l e c t   o r d _ t i p o . o r d _ s t a t o _ i d   i n t o   s t r i c t   o r d S t a t o C o d e A I d 
 
                 f r o m   s i a c _ d _ o r d i n a t i v o _ s t a t o   o r d _ t i p o 
 
                 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       o r d _ t i p o . o r d _ s t a t o _ c o d e = O R D _ S T A T O _ C O D E _ A 
 
                 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
 	 	 - -   c l a s s C d r T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   c l a s s i f   I d   p e r   t i p o   s a c = ' | | C D R | | ' . ' ; 
 
                 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   c l a s s C d r T i p o I d 
 
                 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = C D R 
 
                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
                 - -   c l a s s C d c T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   c l a s s i f   I d   p e r   t i p o   s a c = ' | | C D C | | ' . ' ; 
 
                 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   c l a s s C d r T i p o I d 
 
                 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = C D C 
 
                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
 	 	 - -   o r d D e t T s T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   t i p o   i m p o r t o   o r d i n a t i v o     C o d e   I d   ' | | O R D _ T S _ D E T _ T I P O _ A | | ' . ' ; 
 
                 s e l e c t   o r d _ t i p o . o r d _ t s _ d e t _ t i p o _ i d   i n t o   s t r i c t   o r d D e t T s T i p o I d 
 
                 f r o m   s i a c _ d _ o r d i n a t i v o _ t s _ d e t _ t i p o   o r d _ t i p o 
 
                 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       o r d _ t i p o . o r d _ t s _ d e t _ t i p o _ c o d e = O R D _ T S _ D E T _ T I P O _ A 
 
                 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                 - -   o r d S e d e S e c R e l a z T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   r e l a z i o n e   s e d e   s e c o n d a r i a     C o d e   I d   ' | | O R D _ R E L A Z _ S E D E _ S E C | | ' . ' ; 
 
                 s e l e c t   o r d _ t i p o . r e l a z _ t i p o _ i d   i n t o   s t r i c t   o r d S e d e S e c R e l a z T i p o I d 
 
                 f r o m   s i a c _ d _ r e l a z _ t i p o   o r d _ t i p o 
 
                 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       o r d _ t i p o . r e l a z _ t i p o _ c o d e = O R D _ R E L A Z _ S E D E _ S E C 
 
                 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
 	 	 - -   o r d R e l a z C o d e T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   r e l a z i o n e       C o d e   I d   ' | | O R D _ R E L A Z _ C O D E _ S O S | | ' . ' ; 
 
 	 	 s e l e c t   o r d _ t i p o . r e l a z _ t i p o _ i d   i n t o   s t r i c t   o r d R e l a z C o d e T i p o I d 
 
         	 f r o m   s i a c _ d _ r e l a z _ t i p o   o r d _ t i p o 
 
 	 	 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 a n d       o r d _ t i p o . r e l a z _ t i p o _ c o d e = O R D _ R E L A Z _ C O D E _ S O S 
 
 	 	 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                 - -   m o v g e s t T s T i p o S u b I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   m o v g e s t _ t s _ t i p o     ' | | M O V G E S T _ T S _ T I P O _ S | | ' . ' ; 
 
 	 	 s e l e c t   o r d _ t i p o . m o v g e s t _ t s _ t i p o _ i d   i n t o   s t r i c t   m o v g e s t T s T i p o S u b I d 
 
         	 f r o m   s i a c _ d _ m o v g e s t _ t s _ t i p o   o r d _ t i p o 
 
 	 	 w h e r e   o r d _ t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 a n d       o r d _ t i p o . m o v g e s t _ t s _ t i p o _ c o d e = M O V G E S T _ T S _ T I P O _ S 
 
 	 	 a n d       o r d _ t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ t i p o . v a l i d i t a _ i n i z i o ) 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( o r d _ t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
         	 - -   p r o g r a m m a C o d e T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   p r o g r a m m a _ c o d e _ t i p o _ i d     ' | | P R O G R A M M A | | ' . ' ; 
 
 	 	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   p r o g r a m m a C o d e T i p o I d 
 
         	 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
 	 	 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = P R O G R A M M A 
 
 	 	 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , v a l i d i t a _ i n i z i o ) 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 	 	 - -   f a m T i t S p e M a c r o A g g r C o d e I d 
 
 	 	 - -   F A M _ T I T _ S P E _ M A C R O A G G R E G = ' S p e s a   -   T i t o l i M a c r o a g g r e g a t i ' 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   f a m _ t i t _ s p e _ m a c r o g g r e g a t i _ c o d e _ t i p o _ i d     ' | | F A M _ T I T _ S P E _ M A C R O A G G R E G | | ' . ' ; 
 
 	 	 s e l e c t   f a m . c l a s s i f _ f a m _ t r e e _ i d   i n t o   s t r i c t   f a m T i t S p e M a c r o A g g r C o d e I d 
 
                 f r o m   s i a c _ t _ c l a s s _ f a m _ t r e e   f a m 
 
                 w h e r e   f a m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       f a m . c l a s s _ f a m _ c o d e = F A M _ T I T _ S P E _ M A C R O A G G R E G 
 
                 a n d       f a m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , f a m . v a l i d i t a _ i n i z i o ) 
 
 	 	 a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( f a m . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
         	 - -   t i t o l o U s c i t a C o d e T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   t i t o l o _ s p e s a _ c o d e _ t i p o _ i d     ' | | T I T O L O _ S P E S A | | ' . ' ; 
 
 	 	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   t i t o l o U s c i t a C o d e T i p o I d 
 
         	 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
 	 	 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = T I T O L O _ S P E S A 
 
 	 	 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , v a l i d i t a _ i n i z i o ) 
 
 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 	 	 - -   n o t e O r d A t t r I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   n o t e O r d A t t r I d   p e r   a t t r i b u t o = ' | | N O T E _ O R D _ A T T R | | ' . ' ; 
 
 	 	 s e l e c t   a t t r . a t t r _ i d   i n t o   s t r i c t     n o t e O r d A t t r I d 
 
                 f r o m   s i a c _ t _ a t t r   a t t r 
 
                 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       a t t r . a t t r _ c o d e = N O T E _ O R D _ A T T R 
 
                 a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , a t t r . v a l i d i t a _ i n i z i o ) 
 
   	   	 a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( a t t r . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                 - -   a m b i t o F i n I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   a m b i t o     C o d e   I d   ' | | A M B I T O _ F I N | | ' . ' ; 
 
                 s e l e c t   a . a m b i t o _ i d   i n t o   s t r i c t   a m b i t o F i n I d 
 
                 f r o m   s i a c _ d _ a m b i t o   a 
 
                 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       	 	 a n d       a . a m b i t o _ c o d e = A M B I T O _ F I N 
 
                 a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 - -   f l u s s o E l a b M i f T i p o I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   t i p o   f l u s s o   M I F     C o d e   I d   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 s e l e c t   t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ i d ,   t i p o . f l u s s o _ e l a b _ m i f _ n o m e _ f i l e ,   t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ d e c 
 
                               i n t o   s t r i c t   f l u s s o E l a b M i f T i p o I d , f l u s s o E l a b M i f T i p o N o m e F i l e ,   f l u s s o E l a b M i f T i p o D e c 
 
                 f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o _ t i p o   t i p o 
 
                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       	 	 a n d       t i p o . f l u s s o _ e l a b _ m i f _ t i p o _ c o d e = M A N D M I F _ T I P O 
 
                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 - -   r a i s e   n o t i c e   ' f l u s s o E l a b M i f T i p o I d   % ' , f l u s s o E l a b M i f T i p o I d ; 
 
                 - -   m i f F l u s s o E l a b T y p e R e c 
 
 
 
 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   f l u s s o   s t r u t t u r a   M I F     p e r   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 f o r   m i f E l a b R e c   I N 
 
                 ( s e l e c t   m . * 
 
                   f r o m   m i f _ d _ f l u s s o _ e l a b o r a t o   m 
 
                   w h e r e   m . f l u s s o _ e l a b _ m i f _ t i p o _ i d = f l u s s o E l a b M i f T i p o I d 
 
                   a n d       m . f l u s s o _ e l a b _ m i f _ e l a b = t r u e 
 
                   o r d e r   b y   m . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b 
 
                 ) 
 
                 l o o p 
 
                 	 m i f A F l u s s o E l a b T y p e R e c . f l u s s o E l a b M i f I d   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ i d ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o E l a b M i f A t t i v o   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ a t t i v o ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o E l a b M i f D e f   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ d e f a u l t ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o E l a b M i f E l a b   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ e l a b ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o E l a b M i f P a r a m   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ p a r a m ; 
 
 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o _ e l a b _ m i f _ o r d i n e   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ o r d i n e ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o _ e l a b _ m i f _ c o d e   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c o d e ; 
 
                         m i f A F l u s s o E l a b T y p e R e c . f l u s s o _ e l a b _ m i f _ c a m p o   : = m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o ; 
 
 
 
                         m i f F l u s s o E l a b M i f A r r [ m i f E l a b R e c . f l u s s o _ e l a b _ m i f _ o r d i n e _ e l a b ] : = m i f A F l u s s o E l a b T y p e R e c ; 
 
 
 
                 e n d   l o o p ; 
 
 
 
 
 
 
 
 	 	 - -   G e s t i o n e   r e g i s t r o P c c   p e r   e n t i   c h e   n o n   g e s t i s c o n o   q u i t a n z e 
 
                 - -   N o t a   :   c a p i r e   s e   n e c e s s a r i o   g e s t i r e   P C C 
 
 	 	 / * i f   e n t e O i l R e c . e n t e _ o i l _ q u i e t _ o r d = f a l s e   t h e n 
 
 
 
     	 	 	 - -   c o m P c c A t t r I d 
 
 	                 s t r M e s s a g g i o : = ' L e t t u r a   c o m P c c A t t r I d   p e r   a t t r i b u t o = ' | | C O M _ P C C _ A T T R | | ' . ' ; 
 
 	 	 	 s e l e c t   a t t r . a t t r _ i d   i n t o   s t r i c t     c o m P c c A t t r I d 
 
 	                 f r o m   s i a c _ t _ a t t r   a t t r 
 
 	                 w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	                 a n d       a t t r . a t t r _ c o d e = C O M _ P C C _ A T T R 
 
 	                 a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , a t t r . v a l i d i t a _ i n i z i o ) 
 
       	   	         a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( a t t r . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
                         s t r M e s s a g g i o : = ' L e t t u r a   I d   t i p o   o p e r a z i n e   P C C = ' | | P C C _ O P E R A Z _ C P A G | | ' . ' ; 
 
 	 	 	 s e l e c t   p c c . p c c o p _ t i p o _ i d   i n t o   s t r i c t   p c c O p e r a z T i p o I d 
 
 	 	         f r o m   s i a c _ d _ p c c _ o p e r a z i o n e _ t i p o   p c c 
 
 	 	         w h e r e   p c c . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	         a n d       p c c . p c c o p _ t i p o _ c o d e = P C C _ O P E R A Z _ C P A G ; 
 
 
 
 
 
                 e n d   i f ; * / 
 
 
 
                 - -   e n t e P r o p r i e t a r i o R e c 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   e n t e   p r o p r i e t a r i o   p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 s e l e c t   *   i n t o   s t r i c t   e n t e P r o p r i e t a r i o R e c 
 
                 f r o m   s i a c _ t _ e n t e _ p r o p r i e t a r i o   e n t e 
 
                 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	         a n d       e n t e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       e n t e . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 - -   s o g g e t t o E n t e I d 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   i n d i r i z z o   e n t e   p r o p r i e t a r i o   [ s i a c _ r _ s o g g e t t o _ e n t e _ p r o p r i e t a r i o ]   p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 s e l e c t   e n t e . s o g g e t t o _ i d   i n t o   s o g g e t t o E n t e I d 
 
                 f r o m   s i a c _ r _ s o g g e t t o _ e n t e _ p r o p r i e t a r i o   e n t e 
 
                 w h e r e   e n t e . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       e n t e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       e n t e . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 i f   s o g g e t t o E n t e I d   i s   n o t   n u l l   t h e n 
 
                         s t r M e s s a g g i o : = ' L e t t u r a   i n d i r i z z o   e n t e   p r o p r i e t a r i o   [ s i a c _ t _ i n d i r i z z o _ s o g g e t t o ]   p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 	 s e l e c t   v i a T i p o . v i a _ t i p o _ c o d e | | '   ' | | i n d i r . t o p o n i m o | | '   ' | | i n d i r . n u m e r o _ c i v i c o , 
 
                 	 	       c o m . c o m u n e _ d e s c 
 
                                       i n t o   i n d i r i z z o E n t e , l o c a l i t a E n t e 
 
                         f r o m   s i a c _ t _ i n d i r i z z o _ s o g g e t t o   i n d i r , 
 
                                   s i a c _ t _ c o m u n e   c o m , 
 
                                   s i a c _ d _ v i a _ t i p o   v i a T i p o 
 
                         w h e r e   i n d i r . s o g g e t t o _ i d = s o g g e t t o E n t e I d 
 
                         a n d       i n d i r . p r i n c i p a l e = ' S ' 
 
                         a n d       i n d i r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       i n d i r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       c o m . c o m u n e _ i d = i n d i r . c o m u n e _ i d 
 
                         a n d       c o m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       c o m . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       v i a T i p o . v i a _ t i p o _ i d = i n d i r . v i a _ t i p o _ i d 
 
                         a n d       v i a T i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	       	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , v i a T i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( v i a T i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) 
 
                         o r d e r   b y   i n d i r . i n d i r i z z o _ i d ; 
 
                 e n d   i f ; 
 
 
 
                 - -   C a l c o l o   p r o g r e s s i v o   " d i s t i n t a "   p e r   f l u s s o   M A N D M I F 
 
 	         - -   c a l c o l o   s u   p r o g r e s s i v i   d i   f l u s s o E l a b M i f D i s t O i l I d   f l u s s o O I L   u n i v o c o   p e r   t i p o   f l u s s o 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ ' | | M A N D M I F _ T I P O | | ' _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 c o d R e s u l t : = n u l l ; 
 
                 s e l e c t   p r o g . p r o g _ v a l u e   i n t o   f l u s s o E l a b M i f D i s t O i l R e t I d   - -   2 5 . 0 5 . 2 0 1 6   S o f i a   -   J I R A - 3 6 1 9 
 
                 f r o m   s i a c _ t _ p r o g r e s s i v o   p r o g 
 
                 w h e r e   p r o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       p r o g . p r o g _ k e y = ' o i l _ ' | | M A N D M I F _ T I P O | | ' _ ' | | a n n o B i l a n c i o 
 
                 a n d       p r o g . a m b i t o _ i d = a m b i t o F i n I d 
 
                 a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 i f   f l u s s o E l a b M i f D i s t O i l R e t I d   i s   n u l l   t h e n   - -   2 5 . 0 5 . 2 0 1 6   S o f i a   -   J I R A - 3 6 1 9 
 
 	 	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ o u t _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 	 i n s e r t   i n t o   s i a c _ t _ p r o g r e s s i v o 
 
                         ( p r o g _ k e y , 
 
                           p r o g _ v a l u e , 
 
 	 	 	   a m b i t o _ i d , 
 
 	 	           v a l i d i t a _ i n i z i o , 
 
 	 	 	   e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	   l o g i n _ o p e r a z i o n e 
 
                         ) 
 
                         v a l u e s 
 
                         ( ' o i l _ ' | | M A N D M I F _ T I P O | | ' _ ' | | a n n o B i l a n c i o , 1 , a m b i t o F i n I d , n o w ( ) , e n t e P r o p r i e t a r i o I d , l o g i n O p e r a z i o n e ) 
 
                         r e t u r n i n g   p r o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 R A I S E   E X C E P T I O N   '   P r o g r e s s i v o   n o n   i n s e r i t o . ' ; 
 
                         e l s e 
 
                         	 f l u s s o E l a b M i f D i s t O i l R e t I d : = 0 ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f D i s t O i l R e t I d   i s   n o t   n u l l   t h e n 
 
 	                 f l u s s o E l a b M i f D i s t O i l R e t I d : = f l u s s o E l a b M i f D i s t O i l R e t I d + 1 ; 
 
                 e n d   i f ; 
 
 
 
 	         - -   c a l c o l o   s u   p r o g r e s s i v o   d i   f l u s s o E l a b M i f O i l I d   f l u s s o O I L   u n i v o c o 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ o u t _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 c o d R e s u l t : = n u l l ; 
 
                 s e l e c t   p r o g . p r o g _ v a l u e   i n t o   f l u s s o E l a b M i f O i l I d 
 
                 f r o m   s i a c _ t _ p r o g r e s s i v o   p r o g 
 
                 w h e r e   p r o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       p r o g . p r o g _ k e y = ' o i l _ o u t _ ' | | a n n o B i l a n c i o 
 
                 a n d       p r o g . a m b i t o _ i d = a m b i t o F i n I d 
 
                 a n d       p r o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       p r o g . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 i f   f l u s s o E l a b M i f O i l I d   i s   n u l l   t h e n 
 
 	 	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ o u t _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 	 i n s e r t   i n t o   s i a c _ t _ p r o g r e s s i v o 
 
                         ( p r o g _ k e y , 
 
                           p r o g _ v a l u e , 
 
 	 	 	   a m b i t o _ i d , 
 
 	 	           v a l i d i t a _ i n i z i o , 
 
 	 	 	   e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	 	   l o g i n _ o p e r a z i o n e 
 
                         ) 
 
                         v a l u e s 
 
                         ( ' o i l _ o u t _ ' | | a n n o B i l a n c i o , 1 , a m b i t o F i n I d , n o w ( ) , e n t e P r o p r i e t a r i o I d , l o g i n O p e r a z i o n e ) 
 
                         r e t u r n i n g   p r o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 R A I S E   E X C E P T I O N   '   P r o g r e s s i v o   n o n   i n s e r i t o . ' ; 
 
                         e l s e 
 
                         	 f l u s s o E l a b M i f O i l I d : = 0 ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f O i l I d   i s   n o t   n u l l   t h e n 
 
 	                 f l u s s o E l a b M i f O i l I d : = f l u s s o E l a b M i f O i l I d + 1 ; 
 
                 e n d   i f ; 
 
 
 
                 e x c e p t i o n 
 
 	 	 w h e n   n o _ d a t a _ f o u n d   t h e n 
 
 	 	 	 R A I S E   E X C E P T I O N   '   N o n   p r e s e n t e   i n   a r c h i v i o ' ; 
 
                 w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                         R A I S E   E X C E P T I O N   '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o . ' ; 
 
 	 	 w h e n   o t h e r s     T H E N 
 
 	 	 	 R A I S E   E X C E P T I O N   '   % - % . ' , S Q L S T A T E , s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) ; 
 
         e n d ; 
 
 
 
 
 
 
 
 
 
         - - -   p o p o l a m e n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
 
 
 
 
         - -   o r d i n a t i v i   e m e s s i   o   e m e s s i / s p o s t a t i   n o n   a n c o r a   m a i   t r a s m e s s i   c o d i c e _ f u n z i o n e = ' I '   - -   I N S E R I M E N T O 
 
         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . C o d i c e   f u n z i o n e = ' | | F U N Z I O N E _ C O D E _ I | | ' . ' ; 
 
 
 
         i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
         ( m i f _ o r d _ o r d _ i d ,   m i f _ o r d _ c o d i c e _ f u n z i o n e ,   m i f _ o r d _ b i l _ i d ,   m i f _ o r d _ p e r i o d o _ i d , m i f _ o r d _ a n n o _ b i l , 
 
           m i f _ o r d _ o r d _ a n n o , m i f _ o r d _ o r d _ n u m e r o , m i f _ o r d _ d a t a _ e m i s s i o n e , m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           m i f _ o r d _ s o g g e t t o _ i d ,   m i f _ o r d _ m o d p a g _ i d , 
 
           m i f _ o r d _ s u b o r d _ i d   , m i f _ o r d _ e l e m _ i d ,   m i f _ o r d _ m o v g e s t _ i d ,   m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
           m i f _ o r d _ l i q _ i d ,   m i f _ o r d _ a t t o _ a m m _ i d ,   m i f _ o r d _ c o n t o t e s _ i d , m i f _ o r d _ d i s t _ i d , 
 
           m i f _ o r d _ c o d b o l l o _ i d , m i f _ o r d _ c o m m _ t i p o _ i d , m i f _ o r d _ n o t e t e s _ i d , m i f _ o r d _ d e s c , 
 
           m i f _ o r d _ c a s t _ c a s s a , m i f _ o r d _ c a s t _ c o m p e t e n z a , m i f _ o r d _ c a s t _ e m e s s i , 
 
           m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d , m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
           m i f _ o r d _ l o g i n _ c r e a z i o n e , m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
           e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ) 
 
         ( 
 
           w i t h 
 
           r i t r a s m   a s 
 
           ( s e l e c t   r . m i f _ o r d _ i d ,   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d 
 
 	     f r o m   m i f _ t _ o r d i n a t i v o _ r i t r a s m e s s o   r 
 
 	     w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l 
 
 	     a n d       r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d 
 
 	     a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) , 
 
           o r d i n a t i v i   a s 
 
           ( 
 
             s e l e c t   o r d . o r d _ i d   m i f _ o r d _ o r d _ i d ,   F U N Z I O N E _ C O D E _ I   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
                           b i l . b i l _ i d   m i f _ o r d _ b i l _ i d , p e r . p e r i o d o _ i d   m i f _ o r d _ p e r i o d o _ i d , p e r . a n n o : : i n t e g e r   m i f _ o r d _ a n n o _ b i l , 
 
                           o r d . o r d _ a n n o   m i f _ o r d _ o r d _ a n n o , o r d . o r d _ n u m e r o   m i f _ o r d _ o r d _ n u m e r o , 
 
                           e x t r a c t ( ' y e a r '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) | | ' - ' | | 
 
                           l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                           l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' )   m i f _ o r d _ d a t a _ e m i s s i o n e   ,   0   m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
                           0   m i f _ o r d _ s o g g e t t o _ i d , 0   m i f _ o r d _ m o d p a g _ i d , 0   m i f _ o r d _ s u b o r d _ i d ,   e l e m . e l e m _ i d   m i f _ o r d _ e l e m _ i d , 
 
                           0   m i f _ o r d _ m o v g e s t _ i d , 0   m i f _ o r d _ m o v g e s t _ t s _ i d , 0   m i f _ o r d _ l i q _ i d , 0   m i f _ o r d _ a t t o _ a m m _ i d , 
 
                           o r d . c o n t o t e s _ i d   m i f _ o r d _ c o n t o t e s _ i d , o r d . d i s t _ i d   m i f _ o r d _ d i s t _ i d , o r d . c o d b o l l o _ i d   m i f _ o r d _ c o d b o l l o _ i d , 
 
                           o r d . c o m m _ t i p o _ i d   m i f _ o r d _ c o m m _ t i p o _ i d , o r d . n o t e t e s _ i d   m i f _ o r d _ n o t e t e s _ i d ,   o r d . o r d _ d e s c   m i f _ o r d _ d e s c , 
 
                           o r d . o r d _ c a s t _ c a s s a   m i f _ o r d _ c a s t _ c a s s a , o r d . o r d _ c a s t _ c o m p e t e n z a   m i f _ o r d _ c a s t _ c o m p e t e n z a , o r d . o r d _ c a s t _ e m e s s i   m i f _ o r d _ c a s t _ e m e s s i , 
 
                           o r d . s i o p e _ t i p o _ d e b i t o _ i d , o r d . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                           o r d . l o g i n _ c r e a z i o n e   m i f _ o r d _ l o g i n _ c r e a z i o n e , o r d . l o g i n _ m o d i f i c a   m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                           e n t e P r o p r i e t a r i o I d   e n t e _ p r o p r i e t a r i o _ i d , l o g i n O p e r a z i o n e   l o g i n _ o p e r a z i o n e 
 
             f r o m   s i a c _ t _ o r d i n a t i v o   o r d , s i a c _ r _ o r d i n a t i v o _ s t a t o   o r d _ s t a t o , s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r , s i a c _ r _ o r d i n a t i v o _ b i l _ e l e m   e l e m 
 
             w h e r e     b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d     p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
                 a n d     p e r . a n n o : : i n t e g e r   < = a n n o B i l a n c i o : : i n t e g e r 
 
                 a n d     o r d . b i l _ i d = b i l . b i l _ i d 
 
                 a n d     o r d . o r d _ t i p o _ i d = o r d T i p o C o d e I d 
 
                 a n d     o r d _ s t a t o . o r d _ i d = o r d . o r d _ i d 
 
                 a n d     o r d _ s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ s t a t o . v a l i d i t a _ i n i z i o ) 
 
     	         a n d     o r d _ s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                 a n d     o r d _ s t a t o . o r d _ s t a t o _ i d = o r d S t a t o C o d e I I d 
 
                 a n d     o r d . o r d _ t r a s m _ o i l _ d a t a   i s   n u l l 
 
                 a n d     o r d . o r d _ e m i s s i o n e _ d a t a < = d a t a E l a b o r a z i o n e 
 
 - -     0 6 . 0 7 . 2 0 1 8   S o f i a   j i r a   s i a c - 6 3 0 7 
 
 - -     s c o m m e n t a t o   p e r   s i a c - 6 1 7 5 
 
                 a n d     o r d . o r d _ d a _ t r a s m e t t e r e = t r u e   - -   1 9 . 0 6 . 2 0 1 7   S o f i a   s i a c - 6 1 7 5 
 
                 a n d     e l e m . o r d _ i d = o r d . o r d _ i d 
 
                 a n d     e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d     n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ o r d i n a t i v o   r o r d 
 
                                                     w h e r e   r o r d . o r d _ i d _ a = o r d . o r d _ i d 
 
                                                     a n d       r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                     a n d       r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	                             a n d       r o r d . r e l a z _ t i p o _ i d = o r d R e l a z C o d e T i p o I d ) 
 
               ) 
 
               s e l e c t     o . m i f _ o r d _ o r d _ i d ,   o . m i f _ o r d _ c o d i c e _ f u n z i o n e ,   o . m i f _ o r d _ b i l _ i d ,   o . m i f _ o r d _ p e r i o d o _ i d , o . m i f _ o r d _ a n n o _ b i l , 
 
 	 	               o . m i f _ o r d _ o r d _ a n n o , o . m i f _ o r d _ o r d _ n u m e r o , o . m i f _ o r d _ d a t a _ e m i s s i o n e , o . m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           	 	       o . m i f _ o r d _ s o g g e t t o _ i d ,   o . m i f _ o r d _ m o d p a g _ i d , 
 
                               o . m i f _ o r d _ s u b o r d _ i d   , o . m i f _ o r d _ e l e m _ i d ,   o . m i f _ o r d _ m o v g e s t _ i d ,   o . m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
                               o . m i f _ o r d _ l i q _ i d ,   o . m i f _ o r d _ a t t o _ a m m _ i d ,   o . m i f _ o r d _ c o n t o t e s _ i d , o . m i f _ o r d _ d i s t _ i d , 
 
                               o . m i f _ o r d _ c o d b o l l o _ i d , o . m i f _ o r d _ c o m m _ t i p o _ i d , o . m i f _ o r d _ n o t e t e s _ i d , o . m i f _ o r d _ d e s c , 
 
                               o . m i f _ o r d _ c a s t _ c a s s a , o . m i f _ o r d _ c a s t _ c o m p e t e n z a , o . m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o . s i o p e _ t i p o _ d e b i t o _ i d , o . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o . m i f _ o r d _ l o g i n _ c r e a z i o n e , o . m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               o . e n t e _ p r o p r i e t a r i o _ i d   ,   o . l o g i n _ o p e r a z i o n e 
 
               f r o m   o r d i n a t i v i   o 
 
 	       w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) 
 
               ) ; 
 
 
 
 
 
             - -   o r d i n a t i v i   e m e s s i   o   e m e s s i / s p o s t a t i   n o n   a n c o r a   m a i   t r a s m e s s i ,   s o s t i t u z i o n e   d i   a l t r o   o r d i n a t i v o   c o d i c e _ f u n z i o n e = ' S '   - -   ' S O S P E N S I O N E ' 
 
             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . C o d i c e   f u n z i o n e = ' | | F U N Z I O N E _ C O D E _ S | | ' . ' ; 
 
 
 
             i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
 	     ( m i f _ o r d _ o r d _ i d ,   m i f _ o r d _ c o d i c e _ f u n z i o n e ,   m i f _ o r d _ b i l _ i d ,   m i f _ o r d _ p e r i o d o _ i d , m i f _ o r d _ a n n o _ b i l , 
 
               m i f _ o r d _ o r d _ a n n o , m i f _ o r d _ o r d _ n u m e r o , m i f _ o r d _ d a t a _ e m i s s i o n e , m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
   	       m i f _ o r d _ s o g g e t t o _ i d ,   m i f _ o r d _ m o d p a g _ i d , 
 
   	       m i f _ o r d _ s u b o r d _ i d   , m i f _ o r d _ e l e m _ i d ,   m i f _ o r d _ m o v g e s t _ i d ,   m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
   	       m i f _ o r d _ l i q _ i d ,   m i f _ o r d _ a t t o _ a m m _ i d ,   m i f _ o r d _ c o n t o t e s _ i d ,   m i f _ o r d _ d i s t _ i d , 
 
               m i f _ o r d _ c o d b o l l o _ i d , m i f _ o r d _ c o m m _ t i p o _ i d , m i f _ o r d _ n o t e t e s _ i d , m i f _ o r d _ d e s c , 
 
               m i f _ o r d _ c a s t _ c a s s a , m i f _ o r d _ c a s t _ c o m p e t e n z a , m i f _ o r d _ c a s t _ e m e s s i , 
 
               m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d , m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
               m i f _ o r d _ l o g i n _ c r e a z i o n e , m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
               e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ) 
 
 	     ( 
 
               w i t h 
 
               r i t r a s m   a s 
 
               ( s e l e c t   r . m i f _ o r d _ i d ,   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d 
 
 	         f r o m   m i f _ t _ o r d i n a t i v o _ r i t r a s m e s s o   r 
 
 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l 
 
 	         a n d       r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d 
 
 	         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) , 
 
               o r d i n a t i v i   a s 
 
               ( s e l e c t   o r d . o r d _ i d   m i f _ o r d _ o r d _ i d ,   F U N Z I O N E _ C O D E _ S   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
                               b i l . b i l _ i d   m i f _ o r d _ b i l _ i d , p e r . p e r i o d o _ i d   m i f _ o r d _ p e r i o d o _ i d , p e r . a n n o : : i n t e g e r   m i f _ o r d _ a n n o _ b i l , 
 
                               o r d . o r d _ a n n o   m i f _ o r d _ o r d _ a n n o , o r d . o r d _ n u m e r o   m i f _ o r d _ o r d _ n u m e r o , 
 
                               e x t r a c t ( ' y e a r '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' )   m i f _ o r d _ d a t a _ e m i s s i o n e , 
 
                               0   m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
                               0   m i f _ o r d _ s o g g e t t o _ i d   , 0   m i f _ o r d _ m o d p a g _ i d , 0   m i f _ o r d _ s u b o r d _ i d , 
 
                               e l e m . e l e m _ i d   m i f _ o r d _ e l e m _ i d , 
 
                               0   m i f _ o r d _ m o v g e s t _ i d , 0   m i f _ o r d _ m o v g e s t _ t s _ i d , 0   m i f _ o r d _ l i q _ i d , 0   m i f _ o r d _ a t t o _ a m m _ i d , 
 
                               o r d . c o n t o t e s _ i d   m i f _ o r d _ c o n t o t e s _ i d , o r d . d i s t _ i d   m i f _ o r d _ d i s t _ i d , o r d . c o d b o l l o _ i d   m i f _ o r d _ c o d b o l l o _ i d , 
 
                               o r d . c o m m _ t i p o _ i d   m i f _ o r d _ c o m m _ t i p o _ i d , o r d . n o t e t e s _ i d   m i f _ o r d _ n o t e t e s _ i d , 
 
                               o r d . o r d _ d e s c   m i f _ o r d _ d e s c , 
 
                               o r d . o r d _ c a s t _ c a s s a   m i f _ o r d _ c a s t _ c a s s a , o r d . o r d _ c a s t _ c o m p e t e n z a   m i f _ o r d _ c a s t _ c o m p e t e n z a , o r d . o r d _ c a s t _ e m e s s i   m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o r d . s i o p e _ t i p o _ d e b i t o _ i d , o r d . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o r d . l o g i n _ c r e a z i o n e   m i f _ o r d _ l o g i n _ c r e a z i o n e ,   o r d . l o g i n _ m o d i f i c a   m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               e n t e P r o p r i e t a r i o I d   e n t e _ p r o p r i e t a r i o _ i d , l o g i n O p e r a z i o n e   l o g i n _ o p e r a z i o n e 
 
     	         f r o m   s i a c _ t _ o r d i n a t i v o   o r d , s i a c _ r _ o r d i n a t i v o _ s t a t o   o r d _ s t a t o , 
 
                           s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r , 
 
                           s i a c _ r _ o r d i n a t i v o _ b i l _ e l e m   e l e m , s i a c _ r _ o r d i n a t i v o   r o r d 
 
     	         w h e r e     b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       	 	     a n d     p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
         	     a n d     p e r . a n n o : : i n t e g e r   < = a n n o B i l a n c i o : : i n t e g e r 
 
             	     a n d     o r d . b i l _ i d = b i l . b i l _ i d 
 
           	     a n d     o r d . o r d _ t i p o _ i d = o r d T i p o C o d e I d 
 
         	     a n d     o r d _ s t a t o . o r d _ i d = o r d . o r d _ i d 
 
         	     a n d     o r d _ s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	       	     a n d     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ s t a t o . v a l i d i t a _ i n i z i o ) 
 
     	             a n d     o r d _ s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
         	     a n d     o r d _ s t a t o . o r d _ s t a t o _ i d = o r d S t a t o C o d e I I d 
 
 	             a n d     o r d . o r d _ t r a s m _ o i l _ d a t a   i s   n u l l 
 
         	     a n d     o r d . o r d _ e m i s s i o n e _ d a t a < = d a t a E l a b o r a z i o n e 
 
 - -     0 6 . 0 7 . 2 0 1 8   S o f i a   j i r a   s i a c - 6 3 0 7 
 
 - -     s c o m m e n t a t o   p e r   s i a c - 6 1 7 5 
 
                     a n d     o r d . o r d _ d a _ t r a s m e t t e r e = t r u e   - -   1 9 . 0 6 . 2 0 1 7   S o f i a   s i a c - 6 1 7 5 
 
         	     a n d     e l e m . o r d _ i d = o r d . o r d _ i d 
 
         	     a n d     e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d     e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d     r o r d . o r d _ i d _ a = o r d . o r d _ i d 
 
                     a n d     r o r d . r e l a z _ t i p o _ i d = o r d R e l a z C o d e T i p o I d 
 
                     a n d     r o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d     r o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 s e l e c t     o . m i f _ o r d _ o r d _ i d ,   o . m i f _ o r d _ c o d i c e _ f u n z i o n e ,   o . m i f _ o r d _ b i l _ i d ,   o . m i f _ o r d _ p e r i o d o _ i d , o . m i f _ o r d _ a n n o _ b i l , 
 
 	 	               o . m i f _ o r d _ o r d _ a n n o , o . m i f _ o r d _ o r d _ n u m e r o , o . m i f _ o r d _ d a t a _ e m i s s i o n e , o . m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           	 	       o . m i f _ o r d _ s o g g e t t o _ i d ,   o . m i f _ o r d _ m o d p a g _ i d , 
 
                               o . m i f _ o r d _ s u b o r d _ i d   , o . m i f _ o r d _ e l e m _ i d ,   o . m i f _ o r d _ m o v g e s t _ i d ,   o . m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
                               o . m i f _ o r d _ l i q _ i d ,   o . m i f _ o r d _ a t t o _ a m m _ i d ,   o . m i f _ o r d _ c o n t o t e s _ i d , o . m i f _ o r d _ d i s t _ i d , 
 
                               o . m i f _ o r d _ c o d b o l l o _ i d , o . m i f _ o r d _ c o m m _ t i p o _ i d , o . m i f _ o r d _ n o t e t e s _ i d , o . m i f _ o r d _ d e s c , 
 
                               o . m i f _ o r d _ c a s t _ c a s s a , o . m i f _ o r d _ c a s t _ c o m p e t e n z a , o . m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o . s i o p e _ t i p o _ d e b i t o _ i d , o . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o . m i f _ o r d _ l o g i n _ c r e a z i o n e , o . m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               o . e n t e _ p r o p r i e t a r i o _ i d ,   o . l o g i n _ o p e r a z i o n e 
 
                 f r o m   o r d i n a t i v i   o 
 
 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	       o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                             ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) 
 
             ) ; 
 
 
 
             - -   o r d i n a t i v i   e m e s s i   e   a n n u l l a t i   m a i   t r a s m e s s i   c o d i c e _ f u n z i o n e = ' N '   - -   A N N U L L O 
 
             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . C o d i c e   f u n z i o n e = ' | | F U N Z I O N E _ C O D E _ N | | ' . ' ; 
 
 
 
 	     i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
 	     ( m i f _ o r d _ o r d _ i d ,   m i f _ o r d _ c o d i c e _ f u n z i o n e ,   m i f _ o r d _ b i l _ i d ,   m i f _ o r d _ p e r i o d o _ i d , m i f _ o r d _ a n n o _ b i l , 
 
               m i f _ o r d _ o r d _ a n n o , m i f _ o r d _ o r d _ n u m e r o , m i f _ o r d _ d a t a _ e m i s s i o n e , m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
 	       m i f _ o r d _ s o g g e t t o _ i d ,   m i f _ o r d _ m o d p a g _ i d , 
 
 	       m i f _ o r d _ s u b o r d _ i d   , m i f _ o r d _ e l e m _ i d ,   m i f _ o r d _ m o v g e s t _ i d ,   m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
   	       m i f _ o r d _ l i q _ i d ,   m i f _ o r d _ a t t o _ a m m _ i d ,   m i f _ o r d _ c o n t o t e s _ i d , m i f _ o r d _ d i s t _ i d , 
 
               m i f _ o r d _ c o d b o l l o _ i d , m i f _ o r d _ c o m m _ t i p o _ i d , m i f _ o r d _ n o t e t e s _ i d , m i f _ o r d _ d e s c , 
 
               m i f _ o r d _ c a s t _ c a s s a , m i f _ o r d _ c a s t _ c o m p e t e n z a , m i f _ o r d _ c a s t _ e m e s s i , 
 
               m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d , m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
               m i f _ o r d _ l o g i n _ c r e a z i o n e , m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
               e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ) 
 
 	     ( 
 
               w i t h 
 
               r i t r a s m   a s 
 
               ( s e l e c t   r . m i f _ o r d _ i d ,   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d 
 
 	         f r o m   m i f _ t _ o r d i n a t i v o _ r i t r a s m e s s o   r 
 
 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l 
 
 	         a n d       r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d 
 
 	         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) , 
 
               o r d i n a t i v i   a s 
 
               ( s e l e c t   o r d . o r d _ i d   m i f _ o r d _ o r d _ i d ,   F U N Z I O N E _ C O D E _ N   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
                               b i l . b i l _ i d   m i f _ o r d _ b i l _ i d , p e r . p e r i o d o _ i d   m i f _ o r d _ p e r i o d o _ i d , p e r . a n n o : : i n t e g e r   m i f _ o r d _ a n n o _ b i l , 
 
             	   	       o r d . o r d _ a n n o   m i f _ o r d _ o r d _ a n n o , o r d . o r d _ n u m e r o   m i f _ o r d _ o r d _ n u m e r o , 
 
                               e x t r a c t ( ' y e a r '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' )   m i f _ o r d _ d a t a _ e m i s s i o n e , 
 
                               0   m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
                               0   m i f _ o r d _ s o g g e t t o _ i d , 0   m i f _ o r d _ m o d p a g _ i d , 0   m i f _ o r d _ s u b o r d _ i d , 
 
                               e l e m . e l e m _ i d   m i f _ o r d _ e l e m _ i d , 
 
                               0   m i f _ o r d _ m o v g e s t _ i d , 0   m i f _ o r d _ m o v g e s t _ t s _ i d , 0   m i f _ o r d _ l i q _ i d , 0   m i f _ o r d _ a t t o _ a m m _ i d , 
 
                               o r d . c o n t o t e s _ i d   m i f _ o r d _ c o n t o t e s _ i d , o r d . d i s t _ i d   m i f _ o r d _ d i s t _ i d , 
 
                               o r d . c o d b o l l o _ i d   m i f _ o r d _ c o d b o l l o _ i d , o r d . c o m m _ t i p o _ i d   m i f _ o r d _ c o m m _ t i p o _ i d , 
 
                               o r d . n o t e t e s _ i d   m i f _ o r d _ n o t e t e s _ i d , o r d . o r d _ d e s c   m i f _ o r d _ d e s c , 
 
                               o r d . o r d _ c a s t _ c a s s a   m i f _ o r d _ c a s t _ c a s s a , o r d . o r d _ c a s t _ c o m p e t e n z a   m i f _ o r d _ c a s t _ c o m p e t e n z a , o r d . o r d _ c a s t _ e m e s s i   m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o r d . s i o p e _ t i p o _ d e b i t o _ i d , o r d . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o r d . l o g i n _ c r e a z i o n e   m i f _ o r d _ l o g i n _ c r e a z i o n e , o r d . l o g i n _ m o d i f i c a   m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               e n t e P r o p r i e t a r i o I d   e n t e _ p r o p r i e t a r i o _ i d , l o g i n O p e r a z i o n e   l o g i n _ o p e r a z i o n e 
 
     	         f r o m   s i a c _ t _ o r d i n a t i v o   o r d ,   s i a c _ r _ o r d i n a t i v o _ s t a t o   o r d _ s t a t o , 
 
                           s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r , 
 
                           s i a c _ r _ o r d i n a t i v o _ b i l _ e l e m   e l e m 
 
                 w h e r e     b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                   a n d     p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
                   a n d     p e r . a n n o : : i n t e g e r   < = a n n o B i l a n c i o : : i n t e g e r 
 
                   a n d     o r d . b i l _ i d = b i l . b i l _ i d 
 
                   a n d     o r d . o r d _ t i p o _ i d = o r d T i p o C o d e I d 
 
                   a n d     o r d _ s t a t o . o r d _ i d = o r d . o r d _ i d 
 
                   a n d     o r d _ s t a t o . v a l i d i t a _ i n i z i o < = d a t a E l a b o r a z i o n e   - -   q u e s t a   e ' '   l a   d a t a   d i   a n n u l l a m e n t o 
 
                   a n d     o r d . o r d _ e m i s s i o n e _ d a t a < = d a t a E l a b o r a z i o n e 
 
                   a n d     o r d _ s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ s t a t o . v a l i d i t a _ i n i z i o ) 
 
     	           a n d     o r d _ s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                   a n d     o r d _ s t a t o . o r d _ s t a t o _ i d = o r d S t a t o C o d e A I d 
 
                   a n d     o r d . o r d _ t r a s m _ o i l _ d a t a   i s   n u l l 
 
 - -     0 6 . 0 7 . 2 0 1 8   S o f i a   j i r a   s i a c - 6 3 0 7 
 
 - -     s c o m m e n t a t o   p e r   s i a c - 6 1 7 5 
 
                   a n d     o r d . o r d _ d a _ t r a s m e t t e r e = t r u e   - -   1 9 . 0 6 . 2 0 1 7   S o f i a   s i a c - 6 1 7 5 
 
                   a n d     e l e m . o r d _ i d = o r d . o r d _ i d 
 
                   a n d     e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d     e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
               ) , 
 
               - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9 
 
               o r d S o s   a s 
 
               ( 
 
                     s e l e c t   r o r d . o r d _ i d _ d a ,   r o r d . o r d _ i d _ a 
 
                     f r o m   s i a c _ r _ o r d i n a t i v o   r O r d 
 
                     w h e r e   r O r d . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       r O r d . r e l a z _ t i p o _ i d = o r d R e l a z C o d e T i p o I d 
 
                     a n d       r O r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r O r d . v a l i d i t a _ f i n e   i s   n u l l 
 
               ) , 
 
               - -   1 6 . 0 4 . 2 0 1 8   S o f i a   s i a c - 6 0 6 7 
 
               e n t e O i l   a s 
 
               ( 
 
               s e l e c t   f a l s e   e s c l A n n u l l 
 
               f r o m   s i a c _ t _ e n t e _ o i l   o i l 
 
               w h e r e   o i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
               a n d       o i l . e n t e _ o i l _ i n v i o _ e s c l _ a n n u l l i = f a l s e 
 
               ) 
 
               s e l e c t     o . m i f _ o r d _ o r d _ i d ,   o . m i f _ o r d _ c o d i c e _ f u n z i o n e ,   o . m i f _ o r d _ b i l _ i d ,   o . m i f _ o r d _ p e r i o d o _ i d , o . m i f _ o r d _ a n n o _ b i l , 
 
 	 	               o . m i f _ o r d _ o r d _ a n n o , o . m i f _ o r d _ o r d _ n u m e r o , o . m i f _ o r d _ d a t a _ e m i s s i o n e , o . m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           	 	       o . m i f _ o r d _ s o g g e t t o _ i d ,   o . m i f _ o r d _ m o d p a g _ i d , 
 
                               o . m i f _ o r d _ s u b o r d _ i d   , o . m i f _ o r d _ e l e m _ i d ,   o . m i f _ o r d _ m o v g e s t _ i d ,   o . m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
                               o . m i f _ o r d _ l i q _ i d ,   o . m i f _ o r d _ a t t o _ a m m _ i d ,   o . m i f _ o r d _ c o n t o t e s _ i d , o . m i f _ o r d _ d i s t _ i d , 
 
                               o . m i f _ o r d _ c o d b o l l o _ i d , o . m i f _ o r d _ c o m m _ t i p o _ i d , o . m i f _ o r d _ n o t e t e s _ i d , o . m i f _ o r d _ d e s c , 
 
                               o . m i f _ o r d _ c a s t _ c a s s a , o . m i f _ o r d _ c a s t _ c o m p e t e n z a , o . m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o . s i o p e _ t i p o _ d e b i t o _ i d , o . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o . m i f _ o r d _ l o g i n _ c r e a z i o n e , o . m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               o . e n t e _ p r o p r i e t a r i o _ i d   ,   o . l o g i n _ o p e r a z i o n e 
 
               f r o m   o r d i n a t i v i   o ,   e n t e O i l     - -   1 6 . 0 4 . 2 0 1 8   S o f i a   s i a c - 6 0 6 7 
 
 / * 	       w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) * / 
 
 	       w h e r e 
 
                 - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9 
 
                 (   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) 
 
                 ) 
 
                 a n d     e n t e O i l . e s c l A n n u l l = f a l s e   - -   1 6 . 0 4 . 2 0 1 8   S o f i a   s i a c - 6 0 6 7 
 
                 - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9   :   d e v o n o   e s s e r e   e s c l u d i   o r d i n a t i v i 
 
                 - -   s o s t i t u i t i   e   s o s t i t u t i 
 
                 a n d 
 
                 n o t   e x i s t s 
 
                 ( s e l e c t   1   f r o m   o r d S o s   w h e r e   o r d S o s . o r d _ i d _ d a = o . m i f _ o r d _ o r d _ i d ) 
 
                 a n d 
 
                 n o t   e x i s t s 
 
                 ( s e l e c t   1   f r o m   o r d S o s   w h e r e   o r d S o s . o r d _ i d _ a = o . m i f _ o r d _ o r d _ i d ) 
 
 	       ) ; 
 
 
 
             - -   o r d i n a t i v i   e m e s s i   t r a m e s s i   e   p o i   a n n u l l a t i ,   a n c h e   d o p o   s p o s t a m e n t o     c o d i c e _ f u n z i o n e = ' A '   - -   A N N U L L O 
 
             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . C o d i c e   f u n z i o n e = ' | | F U N Z I O N E _ C O D E _ A | | ' . ' ; 
 
 
 
             i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
             ( m i f _ o r d _ o r d _ i d ,   m i f _ o r d _ c o d i c e _ f u n z i o n e ,   m i f _ o r d _ b i l _ i d ,   m i f _ o r d _ p e r i o d o _ i d , m i f _ o r d _ a n n o _ b i l , 
 
               m i f _ o r d _ o r d _ a n n o , m i f _ o r d _ o r d _ n u m e r o , m i f _ o r d _ d a t a _ e m i s s i o n e , m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
               m i f _ o r d _ s o g g e t t o _ i d ,   m i f _ o r d _ m o d p a g _ i d , 
 
               m i f _ o r d _ s u b o r d _ i d   , m i f _ o r d _ e l e m _ i d ,   m i f _ o r d _ m o v g e s t _ i d ,   m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
               m i f _ o r d _ l i q _ i d ,   m i f _ o r d _ a t t o _ a m m _ i d , m i f _ o r d _ c o n t o t e s _ i d , m i f _ o r d _ d i s t _ i d , 
 
               m i f _ o r d _ c o d b o l l o _ i d , m i f _ o r d _ c o m m _ t i p o _ i d , m i f _ o r d _ n o t e t e s _ i d , m i f _ o r d _ d e s c , 
 
               m i f _ o r d _ c a s t _ c a s s a , m i f _ o r d _ c a s t _ c o m p e t e n z a , m i f _ o r d _ c a s t _ e m e s s i , 
 
               m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d , m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
               m i f _ o r d _ l o g i n _ c r e a z i o n e , m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
               e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ) 
 
             ( 
 
               w i t h 
 
               r i t r a s m   a s 
 
               ( s e l e c t   r . m i f _ o r d _ i d ,   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d 
 
 	         f r o m   m i f _ t _ o r d i n a t i v o _ r i t r a s m e s s o   r 
 
 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l 
 
 	         a n d       r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d 
 
 	         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) , 
 
               o r d i n a t i v i   a s 
 
               ( s e l e c t   o r d . o r d _ i d   m i f _ o r d _ o r d _ i d ,   F U N Z I O N E _ C O D E _ A   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
                               b i l . b i l _ i d   m i f _ o r d _ b i l _ i d , p e r . p e r i o d o _ i d   m i f _ o r d _ p e r i o d o _ i d , p e r . a n n o : : i n t e g e r   m i f _ o r d _ a n n o _ b i l , 
 
                               o r d . o r d _ a n n o   m i f _ o r d _ o r d _ a n n o , o r d . o r d _ n u m e r o   m i f _ o r d _ o r d _ n u m e r o , 
 
                               e x t r a c t ( ' y e a r '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' )   m i f _ o r d _ d a t a _ e m i s s i o n e , 
 
                               0   m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
                               0   m i f _ o r d _ s o g g e t t o _ i d , 0   m i f _ o r d _ m o d p a g _ i d , 0   m i f _ o r d _ s u b o r d _ i d , 
 
                               e l e m . e l e m _ i d   m i f _ o r d _ e l e m _ i d , 
 
                               0   m i f _ o r d _ m o v g e s t _ i d , 0   m i f _ o r d _ m o v g e s t _ t s _ i d , 0   m i f _ o r d _ l i q _ i d , 0   m i f _ o r d _ a t t o _ a m m _ i d , 
 
                               o r d . c o n t o t e s _ i d   m i f _ o r d _ c o n t o t e s _ i d , o r d . d i s t _ i d   m i f _ o r d _ d i s t _ i d , o r d . c o d b o l l o _ i d   m i f _ o r d _ c o d b o l l o _ i d , 
 
                               o r d . c o m m _ t i p o _ i d   m i f _ o r d _ c o m m _ t i p o _ i d , 
 
                               o r d . n o t e t e s _ i d   m i f _ o r d _ n o t e t e s _ i d , o r d . o r d _ d e s c   m i f _ o r d _ d e s c , 
 
                               o r d . o r d _ c a s t _ c a s s a   m i f _ o r d _ c a s t _ c a s s a , o r d . o r d _ c a s t _ c o m p e t e n z a   m i f _ o r d _ c a s t _ c o m p e t e n z a , o r d . o r d _ c a s t _ e m e s s i   m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o r d . s i o p e _ t i p o _ d e b i t o _ i d , o r d . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o r d . l o g i n _ c r e a z i o n e   m i f _ o r d _ l o g i n _ c r e a z i o n e , o r d . l o g i n _ m o d i f i c a   m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               e n t e P r o p r i e t a r i o I d   e n t e _ p r o p r i e t a r i o _ i d , l o g i n O p e r a z i o n e   l o g i n _ o p e r a z i o n e 
 
                 f r o m   s i a c _ t _ o r d i n a t i v o   o r d , s i a c _ r _ o r d i n a t i v o _ s t a t o   o r d _ s t a t o , 
 
                           s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r , 
 
                           s i a c _ r _ o r d i n a t i v o _ b i l _ e l e m   e l e m 
 
                 w h e r e     b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d     p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
                     a n d     p e r . a n n o : : i n t e g e r   < = a n n o B i l a n c i o : : i n t e g e r 
 
                     a n d     o r d . b i l _ i d = b i l . b i l _ i d 
 
                     a n d     o r d . o r d _ t i p o _ i d = o r d T i p o C o d e I d 
 
       	 	     a n d     o r d _ s t a t o . o r d _ i d = o r d . o r d _ i d 
 
     	 	     a n d     o r d . o r d _ e m i s s i o n e _ d a t a < = d a t a E l a b o r a z i o n e 
 
                     a n d     o r d _ s t a t o . v a l i d i t a _ i n i z i o < = d a t a E l a b o r a z i o n e     - -   q u e s t a   e ' '   l a   d a t a   d i   a n n u l l a m e n t o 
 
     	 	     a n d     o r d . o r d _ t r a s m _ o i l _ d a t a   i s   n o t   n u l l 
 
   	 	     a n d     o r d . o r d _ t r a s m _ o i l _ d a t a < o r d _ s t a t o . v a l i d i t a _ i n i z i o 
 
                     a n d     o r d _ s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , o r d _ s t a t o . v a l i d i t a _ i n i z i o ) 
 
     	             a n d     o r d _ s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d     o r d _ s t a t o . o r d _ s t a t o _ i d = o r d S t a t o C o d e A I d 
 
 - -                     a n d     (   o r d . o r d _ s p o s t a m e n t o _ d a t a   i s   n u l l   o r   o r d . o r d _ s p o s t a m e n t o _ d a t a < o r d _ s t a t o . v a l i d i t a _ i n i z i o ) 
 
                     a n d     (   o r d . o r d _ s p o s t a m e n t o _ d a t a   i s   n u l l   o r   d a t e _ t r u n c ( ' D A Y ' , o r d . o r d _ s p o s t a m e n t o _ d a t a ) < = d a t e _ t r u n c ( ' D A Y ' , o r d _ s t a t o . v a l i d i t a _ i n i z i o ) )   - -   3 0 . 0 7 . 2 0 1 9   S o f i a   s i a c - 6 9 5 0 
 
 - -     0 6 . 0 7 . 2 0 1 8   S o f i a   j i r a   s i a c - 6 3 0 7 
 
 - -     s c o m m e n t a t o   p e r   s i a c - 6 1 7 5 
 
                     a n d     o r d . o r d _ d a _ t r a s m e t t e r e = t r u e   - -   1 9 . 0 6 . 2 0 1 7   S o f i a   s i a c - 6 1 7 5 
 
                     a n d     e l e m . o r d _ i d = o r d . o r d _ i d 
 
                     a n d     e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d     e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) , 
 
                 - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9 
 
                 o r d S o s   a s 
 
                 ( 
 
                     s e l e c t   r o r d . o r d _ i d _ d a ,   r o r d . o r d _ i d _ a 
 
                     f r o m   s i a c _ r _ o r d i n a t i v o   r O r d 
 
                     w h e r e   r O r d . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       r O r d . r e l a z _ t i p o _ i d = o r d R e l a z C o d e T i p o I d 
 
                     a n d       r O r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r O r d . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
                 s e l e c t   o . m i f _ o r d _ o r d _ i d ,   o . m i f _ o r d _ c o d i c e _ f u n z i o n e ,   o . m i f _ o r d _ b i l _ i d ,   o . m i f _ o r d _ p e r i o d o _ i d , o . m i f _ o r d _ a n n o _ b i l , 
 
 	 	               o . m i f _ o r d _ o r d _ a n n o , o . m i f _ o r d _ o r d _ n u m e r o , o . m i f _ o r d _ d a t a _ e m i s s i o n e , o . m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           	 	       o . m i f _ o r d _ s o g g e t t o _ i d ,   o . m i f _ o r d _ m o d p a g _ i d , 
 
                               o . m i f _ o r d _ s u b o r d _ i d   , o . m i f _ o r d _ e l e m _ i d ,   o . m i f _ o r d _ m o v g e s t _ i d ,   o . m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
                               o . m i f _ o r d _ l i q _ i d ,   o . m i f _ o r d _ a t t o _ a m m _ i d ,   o . m i f _ o r d _ c o n t o t e s _ i d , o . m i f _ o r d _ d i s t _ i d , 
 
                               o . m i f _ o r d _ c o d b o l l o _ i d , o . m i f _ o r d _ c o m m _ t i p o _ i d , o . m i f _ o r d _ n o t e t e s _ i d , o . m i f _ o r d _ d e s c , 
 
                               o . m i f _ o r d _ c a s t _ c a s s a , o . m i f _ o r d _ c a s t _ c o m p e t e n z a , o . m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o . s i o p e _ t i p o _ d e b i t o _ i d , o . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o . m i f _ o r d _ l o g i n _ c r e a z i o n e , o . m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               o . e n t e _ p r o p r i e t a r i o _ i d   ,   o . l o g i n _ o p e r a z i o n e 
 
                 f r o m   o r d i n a t i v i   o 
 
                 - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9 
 
 / * 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) * / 
 
 	         w h e r e 
 
                 (   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) 
 
                 ) 
 
                 - -   2 3 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 9   :   d e v o n o   e s s e r e   e s c l u d i   o r d i n a t i v i 
 
                 - -   s o s t i t u i t i   e   s o s t i t u t i 
 
                 a n d 
 
                 n o t   e x i s t s 
 
                 ( s e l e c t   1   f r o m   o r d S o s   w h e r e   o r d S o s . o r d _ i d _ d a = o . m i f _ o r d _ o r d _ i d ) 
 
                 a n d 
 
                 n o t   e x i s t s 
 
                 ( s e l e c t   1   f r o m   o r d S o s   w h e r e   o r d S o s . o r d _ i d _ a = o . m i f _ o r d _ o r d _ i d ) 
 
               ) ; 
 
 
 
             - -   o r d i n a t i v i   e m e s s i   ,   t r a s m e s s i     e   p o i   s p o s t a t i   c o d i c e _ f u n z i o n e = ' V B '   (   m a i   a n n u l l a t i   )   _ - - -   V A R I A Z I O N E 
 
             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . C o d i c e   f u n z i o n e = ' | | F U N Z I O N E _ C O D E _ V B | | ' . ' ; 
 
 
 
             i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d 
 
             ( m i f _ o r d _ o r d _ i d ,   m i f _ o r d _ c o d i c e _ f u n z i o n e ,   m i f _ o r d _ b i l _ i d ,   m i f _ o r d _ p e r i o d o _ i d , m i f _ o r d _ a n n o _ b i l , 
 
               m i f _ o r d _ o r d _ a n n o , m i f _ o r d _ o r d _ n u m e r o , m i f _ o r d _ d a t a _ e m i s s i o n e , m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
               m i f _ o r d _ s o g g e t t o _ i d ,   m i f _ o r d _ m o d p a g _ i d , 
 
               m i f _ o r d _ s u b o r d _ i d   , m i f _ o r d _ e l e m _ i d ,   m i f _ o r d _ m o v g e s t _ i d ,   m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
               m i f _ o r d _ l i q _ i d ,   m i f _ o r d _ a t t o _ a m m _ i d ,   m i f _ o r d _ c o n t o t e s _ i d , m i f _ o r d _ d i s t _ i d , 
 
               m i f _ o r d _ c o d b o l l o _ i d , m i f _ o r d _ c o m m _ t i p o _ i d , m i f _ o r d _ n o t e t e s _ i d , m i f _ o r d _ d e s c , 
 
               m i f _ o r d _ c a s t _ c a s s a , m i f _ o r d _ c a s t _ c o m p e t e n z a , m i f _ o r d _ c a s t _ e m e s s i , 
 
               m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d , m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
               m i f _ o r d _ l o g i n _ c r e a z i o n e , m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
               e n t e _ p r o p r i e t a r i o _ i d ,   l o g i n _ o p e r a z i o n e ) 
 
             ( 
 
               w i t h 
 
               r i t r a s m   a s 
 
               ( s e l e c t   r . m i f _ o r d _ i d ,   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d 
 
 	         f r o m   m i f _ t _ o r d i n a t i v o _ r i t r a s m e s s o   r 
 
 	         w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l 
 
 	         a n d       r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d 
 
 	         a n d       r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) , 
 
               o r d i n a t i v i   a s 
 
               ( s e l e c t   o r d . o r d _ i d   m i f _ o r d _ o r d _ i d ,   F U N Z I O N E _ C O D E _ V B   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
                               b i l . b i l _ i d   m i f _ o r d _ b i l _ i d , p e r . p e r i o d o _ i d   m i f _ o r d _ p e r i o d o _ i d , p e r . a n n o : : i n t e g e r   m i f _ o r d _ a n n o _ b i l , 
 
                               o r d . o r d _ a n n o   m i f _ o r d _ o r d _ a n n o , o r d . o r d _ n u m e r o   m i f _ o r d _ o r d _ n u m e r o , 
 
                               e x t r a c t ( ' y e a r '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                               l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d . o r d _ e m i s s i o n e _ d a t a ) : : v a r c h a r , 2 , ' 0 ' )   m i f _ o r d _ d a t a _ e m i s s i o n e , 
 
                               0   m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
                               0   m i f _ o r d _ s o g g e t t o _ i d , 0   m i f _ o r d _ m o d p a g _ i d , 0   m i f _ o r d _ s u b o r d _ i d , 
 
                               e l e m . e l e m _ i d   m i f _ o r d _ e l e m _ i d , 
 
                               0   m i f _ o r d _ m o v g e s t _ i d , 0   m i f _ o r d _ m o v g e s t _ t s _ i d , 0   m i f _ o r d _ l i q _ i d , 0   m i f _ o r d _ a t t o _ a m m _ i d , 
 
                               o r d . c o n t o t e s _ i d   m i f _ o r d _ c o n t o t e s _ i d , o r d . d i s t _ i d   m i f _ o r d _ d i s t _ i d , o r d . c o d b o l l o _ i d   m i f _ o r d _ c o d b o l l o _ i d , 
 
                               o r d . c o m m _ t i p o _ i d   m i f _ o r d _ c o m m _ t i p o _ i d , 
 
                               o r d . n o t e t e s _ i d   m i f _ o r d _ n o t e t e s _ i d , o r d . o r d _ d e s c   m i f _ o r d _ d e s c , 
 
                               o r d . o r d _ c a s t _ c a s s a   m i f _ o r d _ c a s t _ c a s s a , o r d . o r d _ c a s t _ c o m p e t e n z a   m i f _ o r d _ c a s t _ c o m p e t e n z a , o r d . o r d _ c a s t _ e m e s s i   m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o r d . s i o p e _ t i p o _ d e b i t o _ i d , o r d . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o r d . l o g i n _ c r e a z i o n e   m i f _ o r d _ l o g i n _ c r e a z i o n e , o r d . l o g i n _ m o d i f i c a   m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               e n t e P r o p r i e t a r i o I d   e n t e _ p r o p r i e t a r i o _ i d , l o g i n O p e r a z i o n e   l o g i n _ o p e r a z i o n e 
 
                 f r o m   s i a c _ t _ o r d i n a t i v o   o r d , s i a c _ t _ b i l   b i l ,   s i a c _ t _ p e r i o d o   p e r ,   s i a c _ r _ o r d i n a t i v o _ b i l _ e l e m   e l e m 
 
                 w h e r e     b i l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                   a n d     p e r . p e r i o d o _ i d = b i l . p e r i o d o _ i d 
 
                   a n d     p e r . a n n o : : i n t e g e r   < = a n n o B i l a n c i o : : i n t e g e r 
 
                   a n d     o r d . b i l _ i d = b i l . b i l _ i d 
 
                   a n d     o r d . o r d _ t i p o _ i d = o r d T i p o C o d e I d 
 
                   a n d     o r d . o r d _ e m i s s i o n e _ d a t a < = d a t a E l a b o r a z i o n e 
 
                   a n d     o r d . o r d _ t r a s m _ o i l _ d a t a   i s   n o t   n u l l 
 
                   a n d     o r d . o r d _ s p o s t a m e n t o _ d a t a   i s   n o t   n u l l 
 
 - -                   a n d     o r d . o r d _ t r a s m _ o i l _ d a t a < o r d . o r d _ s p o s t a m e n t o _ d a t a   - -   3 0 . 0 7 . 2 0 1 9   S o f i a   s i a c - 6 9 5 0 
 
                   a n d     d a t e _ t r u n c ( ' D A Y ' , o r d . o r d _ t r a s m _ o i l _ d a t a ) < = d a t e _ t r u n c ( ' D A Y ' , o r d . o r d _ s p o s t a m e n t o _ d a t a )   - -   3 0 . 0 7 . 2 0 1 9   S o f i a   s i a c - 6 9 5 0 
 
                   a n d     o r d . o r d _ s p o s t a m e n t o _ d a t a < = d a t a E l a b o r a z i o n e 
 
 - -     0 6 . 0 7 . 2 0 1 8   S o f i a   j i r a   s i a c - 6 3 0 7 
 
 - -     s c o m m e n t a t o   p e r   s i a c - 6 1 7 5 
 
                   a n d     o r d . o r d _ d a _ t r a s m e t t e r e = t r u e   - -   1 9 . 0 6 . 2 0 1 7   S o f i a   s i a c - 6 1 7 5 
 
                   a n d     n o t   e x i s t s   ( s e l e c t   1   f r o m   s i a c _ r _ o r d i n a t i v o _ s t a t o   o r d _ s t a t o 
 
     	 	 	 	                     w h e r e     o r d _ s t a t o . o r d _ i d = o r d . o r d _ i d 
 
 	 	 	 	 	                 a n d     o r d _ s t a t o . o r d _ s t a t o _ i d = o r d S t a t o C o d e A I d 
 
                                                         a n d     o r d _ s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l ) 
 
                   a n d     e l e m . o r d _ i d = o r d . o r d _ i d 
 
                   a n d     e l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d     e l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
                 ) 
 
               s e l e c t   o . m i f _ o r d _ o r d _ i d ,   o . m i f _ o r d _ c o d i c e _ f u n z i o n e ,   o . m i f _ o r d _ b i l _ i d ,   o . m i f _ o r d _ p e r i o d o _ i d , o . m i f _ o r d _ a n n o _ b i l , 
 
 	 	               o . m i f _ o r d _ o r d _ a n n o , o . m i f _ o r d _ o r d _ n u m e r o , o . m i f _ o r d _ d a t a _ e m i s s i o n e , o . m i f _ o r d _ o r d _ a n n o _ m o v g , 
 
           	 	       o . m i f _ o r d _ s o g g e t t o _ i d ,   o . m i f _ o r d _ m o d p a g _ i d , 
 
                               o . m i f _ o r d _ s u b o r d _ i d   , o . m i f _ o r d _ e l e m _ i d ,   o . m i f _ o r d _ m o v g e s t _ i d ,   o . m i f _ o r d _ m o v g e s t _ t s _ i d , 
 
                               o . m i f _ o r d _ l i q _ i d ,   o . m i f _ o r d _ a t t o _ a m m _ i d ,   o . m i f _ o r d _ c o n t o t e s _ i d , o . m i f _ o r d _ d i s t _ i d , 
 
                               o . m i f _ o r d _ c o d b o l l o _ i d , o . m i f _ o r d _ c o m m _ t i p o _ i d , o . m i f _ o r d _ n o t e t e s _ i d , o . m i f _ o r d _ d e s c , 
 
                               o . m i f _ o r d _ c a s t _ c a s s a , o . m i f _ o r d _ c a s t _ c o m p e t e n z a , o . m i f _ o r d _ c a s t _ e m e s s i , 
 
                               o . s i o p e _ t i p o _ d e b i t o _ i d , o . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d , 
 
                               o . m i f _ o r d _ l o g i n _ c r e a z i o n e , o . m i f _ o r d _ l o g i n _ m o d i f i c a , 
 
                               o . e n t e _ p r o p r i e t a r i o _ i d   ,   o . l o g i n _ o p e r a z i o n e 
 
               f r o m   o r d i n a t i v i   o 
 
 	       w h e r e   m i f O r d R i t r a s m E l a b I d   i s   n u l l 
 
 	 	     o r   ( m i f O r d R i t r a s m E l a b I d   i s   n o t   n u l l   a n d   e x i s t s 
 
                           ( s e l e c t   1   f r o m   r i t r a s m   r   w h e r e   r . m i f _ o r d _ r i t r a s m _ e l a b _ i d = m i f O r d R i t r a s m E l a b I d   a n d   r . m i f _ o r d _ i d = o . m i f _ o r d _ o r d _ i d ) ) 
 
             ) ; 
 
             - -   a g g i o r n a m e n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   p e r   i d 
 
 
 
 
 
             s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   f a s e _ o p e r a t i v a _ c o d e . ' ; 
 
             u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
             s e t   m i f _ o r d _ b i l _ f a s e _ o p e = ( s e l e c t   f a s e . f a s e _ o p e r a t i v a _ c o d e   f r o m   s i a c _ r _ b i l _ f a s e _ o p e r a t i v a   r F a s e ,   s i a c _ d _ f a s e _ o p e r a t i v a   f a s e 
 
             	 	 	 	 	 	 	 w h e r e   r F a s e . b i l _ i d = m . m i f _ o r d _ b i l _ i d 
 
                                                                 a n d       r F a s e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                 a n d       r F a s e . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                                 a n d       f a s e . f a s e _ o p e r a t i v a _ i d = r F a s e . f a s e _ o p e r a t i v a _ i d 
 
                                                                 a n d       f a s e . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                 a n d       f a s e . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
 
 
             s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   s o g g e t t o _ i d . ' ; 
 
             - -   s o g g e t t o _ i d 
 
 
 
             u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
             s e t   m i f _ o r d _ s o g g e t t o _ i d = c o a l e s c e ( s . s o g g e t t o _ i d , 0 ) 
 
             f r o m   s i a c _ r _ o r d i n a t i v o _ s o g g e t t o   s 
 
             w h e r e   s . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
             a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d   s . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m o d p a g _ i d . ' ; 
 
 
 
             - -   m o d p a g _ i d 
 
             u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m   s e t     m i f _ o r d _ m o d p a g _ i d = c o a l e s c e ( s . m o d p a g _ i d , 0 ) 
 
             f r o m   s i a c _ r _ o r d i n a t i v o _ m o d p a g   s 
 
             w h e r e   s . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
       	     a n d   s . m o d p a g _ i d   i s   n o t   n u l l 
 
             a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d   s . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m o d p a g _ i d   [ C S I ] . ' ; 
 
             u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m   s e t   m i f _ o r d _ m o d p a g _ i d = c o a l e s c e ( r e l . m o d p a g _ i d , 0 ) 
 
             f r o m   s i a c _ r _ o r d i n a t i v o _ m o d p a g   s ,   s i a c _ r _ s o g g r e l _ m o d p a g   r e l 
 
             w h e r e   s . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
             a n d   s . s o g g e t t o _ r e l a z _ i d   i s   n o t   n u l l 
 
             a n d   r e l . s o g g e t t o _ r e l a z _ i d = s . s o g g e t t o _ r e l a z _ i d 
 
             a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d   s . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d   r e l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             - -     a n d   r e l . v a l i d i t a _ f i n e   i s   n u l l 
 
             - -   0 4 . 0 4 . 2 0 1 8   S o f i a   S I A C - 6 0 6 4 
 
             a n d   d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( r e l . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) 
 
             a n d   e x i s t s     ( s e l e c t     1   f r o m   s i a c _ r _ s o g g r e l _ m o d p a g   r e l 1 
 
                                       w h e r e         r e l . s o g g e t t o _ r e l a z _ i d = s . s o g g e t t o _ r e l a z _ i d 
 
 	 	                       a n d             r e l 1 . s o g g r e l m p a g _ i d = r e l . s o g g r e l m p a g _ i d 
 
                   	 	       o r d e r   b y   r e l 1 . m o d p a g _ i d 
 
 	 	 	               l i m i t   1 ) ; 
 
 
 
             s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   s u b o r d _ i d . ' ; 
 
 
 
             - -   s u b o r d _ i d 
 
             u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
             s e t   m i f _ o r d _ s u b o r d _ i d   = 
 
                                                           ( s e l e c t   s . o r d _ t s _ i d   f r o m   s i a c _ t _ o r d i n a t i v o _ t s   s 
 
                                                               w h e r e   s . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
                                                                   a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                   a n d   s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                               o r d e r   b y   s . o r d _ t s _ i d 
 
                                                               l i m i t   1 ) ; 
 
 
 
           s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   l i q _ i d . ' ; 
 
 
 
 	   - -   l i q _ i d 
 
 	   u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
 	   s e t   m i f _ o r d _ l i q _ i d   =   ( s e l e c t   s . l i q _ i d   f r o m   s i a c _ r _ l i q u i d a z i o n e _ o r d   s 
 
                                                         w h e r e   s . s o r d _ i d   =   m . m i f _ o r d _ s u b o r d _ i d 
 
                                                             a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                             a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
           s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m o v g e s t _ t s _ i d . ' ; 
 
 
 
           - -   m o v g e s t _ t s _ i d 
 
           u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
           s e t   m i f _ o r d _ m o v g e s t _ t s _ i d   =   ( s e l e c t   s . m o v g e s t _ t s _ i d   f r o m   s i a c _ r _ l i q u i d a z i o n e _ m o v g e s t   s 
 
                                                                       w h e r e   s . l i q _ i d   =   m . m i f _ o r d _ l i q _ i d 
 
                                                                           a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                           a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
           s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m o v g e s t _ i d . ' ; 
 
 
 
           - -   m o v g e s t _ i d 
 
           u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
           s e t   m i f _ o r d _ m o v g e s t _ i d   =   ( s e l e c t   s . m o v g e s t _ i d   f r o m   s i a c _ t _ m o v g e s t _ t s   s 
 
                                                               w h e r e     s . m o v g e s t _ t s _ i d   =   m . m i f _ o r d _ m o v g e s t _ t s _ i d 
 
                                                               a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                               a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
           s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m o v g e s t _ i d . ' ; 
 
 
 
           - -   m o v g e s t _ a n n o 
 
           u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
           s e t   m i f _ o r d _ o r d _ a n n o _ m o v g   =   ( s e l e c t   s . m o v g e s t _ a n n o   f r o m   s i a c _ t _ m o v g e s t   s 
 
                                                             	     w h e r e     s . m o v g e s t _ i d   =   m . m i f _ o r d _ m o v g e s t _ i d 
 
                                                           	     a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                     a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
 
 
           s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   a t t o a m m _ i d . ' ; 
 
 
 
         - -   a t t o a m m _ i d 
 
         u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
         s e t   m i f _ o r d _ a t t o _ a m m _ i d   =   ( s e l e c t   s . a t t o a m m _ i d   f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t o _ a m m   s 
 
                                                                 w h e r e   s . l i q _ i d   =   m . m i f _ o r d _ l i q _ i d 
 
                                                                     a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                     a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   a t t o a m m _ i d   m o v g e s t _ t s . ' ; 
 
 	 - -   a t t o a m m _ m o v g e s t _ t s _ i d 
 
         u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
         s e t   m i f _ o r d _ a t t o _ a m m _ m o v g _ i d   =   ( s e l e c t   s . a t t o a m m _ i d   f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   s 
 
                                                                         w h e r e   s . m o v g e s t _ t s _ i d   =   m . m i f _ o r d _ m o v g e s t _ t s _ i d 
 
                                                                         a n d   s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                                         a n d   s . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
 	 - -   m i f _ o r d _ p r o g r a m m a _ i d 
 
         - -   m i f _ o r d _ p r o g r a m m a _ c o d e 
 
         - -   m i f _ o r d _ p r o g r a m m a _ d e s c 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m i f _ o r d _ p r o g r a m m a _ i d   m i f _ o r d _ p r o g r a m m a _ c o d e   m i f _ o r d _ p r o g r a m m a _ d e s c . ' ; 
 
         u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
         s e t   ( m i f _ o r d _ p r o g r a m m a _ i d , m i f _ o r d _ p r o g r a m m a _ c o d e , m i f _ o r d _ p r o g r a m m a _ d e s c )   =   ( c l a s s . c l a s s i f _ i d , c l a s s . c l a s s i f _ c o d e , c l a s s . c l a s s i f _ d e s c )   - -   1 1 . 0 1 . 2 0 1 6   S o f i a 
 
         f r o m   s i a c _ r _ b i l _ e l e m _ c l a s s   c l a s s E l e m ,   s i a c _ t _ c l a s s   c l a s s 
 
         w h e r e   c l a s s E l e m . e l e m _ i d = m . m i f _ o r d _ e l e m _ i d 
 
         a n d       c l a s s . c l a s s i f _ i d = c l a s s E l e m . c l a s s i f _ i d 
 
         a n d       c l a s s . c l a s s i f _ t i p o _ i d = p r o g r a m m a C o d e T i p o I d 
 
         a n d       c l a s s E l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c l a s s E l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 	 - -   m i f _ o r d _ t i t o l o _ i d 
 
         - -   m i f _ o r d _ t i t o l o _ c o d e 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m i f _ o r d _ t i t o l o _ i d   m i f _ o r d _ t i t o l o _ c o d e . ' ; 
 
         u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
         s e t   ( m i f _ o r d _ t i t o l o _ i d ,   m i f _ o r d _ t i t o l o _ c o d e )   =   ( c p . c l a s s i f _ i d , c p . c l a s s i f _ c o d e ) 
 
 	 f r o m   s i a c _ r _ b i l _ e l e m _ c l a s s   c l a s s E l e m ,   s i a c _ t _ c l a s s   c f ,   s i a c _ r _ c l a s s _ f a m _ t r e e   r ,   s i a c _ t _ c l a s s   c p 
 
 	 w h e r e   c l a s s E l e m . e l e m _ i d = m . m i f _ o r d _ e l e m _ i d 
 
         a n d       c f . c l a s s i f _ i d = c l a s s E l e m . c l a s s i f _ i d 
 
         a n d       c f . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c l a s s E l e m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       c l a s s E l e m . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 a n d       r . c l a s s i f _ i d = c f . c l a s s i f _ i d 
 
 	 a n d       r . c l a s s i f _ i d _ p a d r e   i s   n o t   n u l l 
 
 	 a n d       r . c l a s s i f _ f a m _ t r e e _ i d = f a m T i t S p e M a c r o A g g r C o d e I d 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 a n d       c p . c l a s s i f _ i d = r . c l a s s i f _ i d _ p a d r e 
 
         a n d       c p . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
 
 
 
 
 
 
 
 
 	 - -   m i f _ o r d _ n o t e _ a t t r _ i d 
 
 	 s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   d a t i   i n   t a b e l l a   t e m p o r a n e a   i d   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ]   p e r   m i f _ o r d _ n o t e _ a t t r _ i d . ' ; 
 
 	 u p d a t e   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m 
 
         s e t   m i f _ o r d _ n o t e _ a t t r _ i d =   a t t r . o r d _ a t t r _ i d 
 
         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t r   a t t r 
 
         w h e r e   a t t r . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
         a n d       a t t r . a t t r _ i d = n o t e O r d A t t r I d 
 
         a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   e s i s t e n z a   o r d i n a t i v i   d i   s p e s a   d a   t r a s m e t t e r e . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   w h e r e   e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d ; 
 
 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
             c o d R e s u l t : = - 1 2 ; 
 
             R A I S E   E X C E P T I O N   '   N e s s u n   o r d i n a t i v o   d i   s p e s a   d a   t r a s m e t t e r e . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
         - -   < r i t e n u t e > 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ F L U S S O _ M I F _ E L A B _ R I T E N U T A ] ; 
 
 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         e n d   i f ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
     	 	 	 	 	 t i p o R e l a z R i t O r d : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
 	                                 t i p o R e l a z S p r O r d : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
 	                                 t i p o R e l a z S u b O r d : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         t i p o O n e r e I r p e f : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
                                         t i p o O n e r e I n p s : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 5 ) ) ; 
 
                                         t i p o O n e r e I r p e g : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 6 ) ) ; 
 
 
 
 
 
                                         i f   t i p o R e l a z R i t O r d   i s   n u l l   o r   t i p o R e l a z S p r O r d   i s   n u l l   o r   t i p o R e l a z S u b O r d   i s   n u l l 
 
                                               o r   t i p o O n e r e I n p s   i s   n u l l   o r   t i p o O n e r e I r p e f   i s   n u l l 
 
                                               o r   t i p o O n e r e I r p e g   i s   n u l l   t h e n 
 
                                               R A I S E   E X C E P T I O N   '   D a t i   c o n f i g u r a z i o n e   r i t e n u t e   n o n   c o m p l e t i . ' ; 
 
                                         e n d   i f ; 
 
                                         i s R i t e n u t a A t t i v o : = t r u e ; 
 
                         e n d   i f ; 
 
 	         e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	       	 e n d   i f ; 
 
       e n d   i f ; 
 
 
 
       i f   i s R i t e n u t a A t t i v o = t r u e   t h e n 
 
           	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ F L U S S O _ M I F _ E L A B _ R I T E N U T A _ P R G ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	       	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	       	   e n d   i f ; 
 
         	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
         	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                                 	 p r o g r R i t e n u t a : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                 e n d   i f ; 
 
 	         	 e l s e 
 
 	 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	       	 	 e n d   i f ; 
 
 	           e l s e 
 
         	       i s R i t e n u t a A t t i v o : = f a l s e ; 
 
 	 	   e n d   i f ; 
 
       e n d   i f ; 
 
 
 
       i f   i s R i t e n u t a A t t i v o = t r u e   t h e n 
 
                       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   i d e n t i f i c a t i v o   t i p o   O n e r e   ' | | t i p o O n e r e I r p e f 
 
                                               | | '   s e z i o n e   r i t e n u t e   -   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                       s e l e c t   t i p o . o n e r e _ t i p o _ i d   i n t o   t i p o O n e r e I r p e f I d 
 
                       f r o m   s i a c _ d _ o n e r e _ t i p o   t i p o 
 
                       w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                       a n d       t i p o . o n e r e _ t i p o _ c o d e = t i p o O n e r e I r p e f 
 
                       a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
   	     	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
       	 	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
                       i f   t i p o O n e r e I r p e f I d   i s   n u l l   t h e n 
 
                         	 R A I S E   E X C E P T I O N   '   D a t o   n o n   r e p e r i t o . ' ; 
 
                       e n d   i f ; 
 
 
 
                       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   i d e n t i f i c a t i v o   t i p o   O n e r e   ' | | t i p o O n e r e I n p s 
 
                                               | | '   s e z i o n e   r i t e n u t e   -   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                       s e l e c t   t i p o . o n e r e _ t i p o _ i d   i n t o   t i p o O n e r e I n p s I d 
 
                       f r o m   s i a c _ d _ o n e r e _ t i p o   t i p o 
 
                       w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                       a n d       t i p o . o n e r e _ t i p o _ c o d e = t i p o O n e r e I n p s 
 
                       a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
   	     	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                       i f   t i p o O n e r e I n p s I d   i s   n u l l   t h e n 
 
                         	 R A I S E   E X C E P T I O N   '   D a t o   n o n   r e p e r i t o . ' ; 
 
                       e n d   i f ; 
 
 
 
 	 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   i d e n t i f i c a t i v o   t i p o   O n e r e   ' | | t i p o O n e r e I r p e g 
 
                                                 | | '   s e z i o n e   r i t e n u t e   -   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                       s e l e c t   t i p o . o n e r e _ t i p o _ i d   i n t o   t i p o O n e r e I r p e g I d 
 
                       f r o m   s i a c _ d _ o n e r e _ t i p o   t i p o 
 
                       w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                       a n d       t i p o . o n e r e _ t i p o _ c o d e = t i p o O n e r e I r p e g 
 
                       a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
   	     	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	       a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
 
 
                       i f   t i p o O n e r e I r p e g I d   i s   n u l l   t h e n 
 
                         	 R A I S E   E X C E P T I O N   '   D a t o   n o n   r e p e r i t o . ' ; 
 
                       e n d   i f ; 
 
       e n d   i f ; 
 
 
 
 
 
       - -   < s o s p e s i > 
 
       - -   < s o s p e s o > 
 
       - -   < n u m e r o _ p r o v v i s o r i o > 
 
       - -   < i m p o r t o _ p r o v v i s o r i o > 
 
       f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ F L U S S O _ M I F _ E L A B _ N U M _ S O S P E S O ] ; 
 
       m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ N U M _ S O S P E S O ; 
 
       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
       e n d   i f ; 
 
       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 n u l l ; 
 
                 e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
       	 	 e n d   i f ; 
 
                 i s R i c e v u t a A t t i v o : = t r u e ; 
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
       f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ F A T T U R E ; 
 
       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                   | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                   | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
       e n d   i f ; 
 
       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l     t h e n 
 
   	 	         n u m e r o D o c s : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                         t i p o D o c s     : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                         t i p o G r u p p o D o c s     : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                         i f   n u m e r o D o c s   i s   n o t   n u l l   a n d   n u m e r o D o c s ! = ' '   a n d 
 
                               t i p o D o c s   i s   n o t   n u l l   a n d   t i p o D o c s ! = ' '   a n d 
 
                               t i p o G r u p p o D o c s   i s   n o t   n u l l   a n d   t i p o G r u p p o D o c s ! = ' '   t h e n 
 
                                 t i p o D o c s : = t i p o D o c s | | ' | ' | | t i p o G r u p p o D o c s ; 
 
                         	 i s G e s t i o n e F a t t u r e : = t r u e ; 
 
                         e n d   i f ; 
 
 	 	 e n d   i f ; 
 
         e l s e 
 
         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
         e n d   i f ; 
 
       e n d   i f ; 
 
 
 
       i f   i s G e s t i o n e F a t t u r e = t r u e   t h e n 
 
 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ F A T T _ C O D F I S C ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                   | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                   | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         e n d   i f ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l     t h e n 
 
   	 	         d o c A n a l o g i c o : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m ; 
 
 	 	 e n d   i f ; 
 
           e l s e 
 
         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
           e n d   i f ; 
 
         e n d   i f ; 
 
 
 
       e n d   i f ; 
 
 
 
       i f   i s G e s t i o n e F a t t u r e = t r u e   t h e n 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ F A T T _ D A T A S C A D _ P A G ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                   | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                   | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         e n d   i f ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l     t h e n 
 
                         a t t r C o d e D a t a S c a d : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
 	 	 e n d   i f ; 
 
           e l s e 
 
         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
           e n d   i f ; 
 
         e n d   i f ; 
 
 
 
       e n d   i f ; 
 
 
 
       i f   i s G e s t i o n e F a t t u r e = t r u e   t h e n 
 
 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ F A T T _ N A T U R A _ P A G ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                   | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                   | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         e n d   i f ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 - -   2 0 . 0 2 . 2 0 1 8   S o f i a   J I R A   s i a c - 5 8 4 9 
 
                 / * 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l     t h e n 
 
                         t i t o l o C o r r e n t e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                         d e s c r i T i t o l o C o r r e n t e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                         t i t o l o C a p i t a l e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                         d e s c r i T i t o l o C a p i t a l e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
 
 
 	 	 e n d   i f ; * / 
 
 
 
                 - -   2 0 . 0 2 . 2 0 1 8   S o f i a   J I R A   s i a c - 5 8 4 9 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                 	 d e f N a t u r a P a g : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                 e n d   i f ; 
 
           e l s e 
 
         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
           e n d   i f ; 
 
         e n d   i f ; 
 
 
 
       e n d   i f ; 
 
 
 
       - - -   l e t t u r a   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   p e r   p o p o l a m e n t o   m i f _ t _ o r d i n a t i v o _ s p e s a 
 
       c o d R e s u l t : = n u l l ; 
 
       s t r M e s s a g g i o : = ' L e t t u r a   o r d i n a t i v i   d i   s p e s a   d a   m i g r a r e   [ m i f _ t _ o r d i n a t i v o _ s p e s a _ i d ] . I n i z i o   c i c l o . ' ; 
 
       f o r   m i f O r d i n a t i v o I d R e c   I N 
 
       ( s e l e c t   m s . * 
 
           f r o m   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m s 
 
           w h e r e   m s . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
           o r d e r   b y   m s . m i f _ o r d _ a n n o _ b i l , 
 
                             m s . m i f _ o r d _ o r d _ n u m e r o 
 
       ) 
 
       l o o p 
 
 
 
 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c : = n u l l ; 
 
 	 	 M D P R e c : = n u l l ; 
 
                 c o d A c c r e R e c : = n u l l ; 
 
 	 	 b i l E l e m R e c : = n u l l ; 
 
                 s o g g e t t o R e c : = n u l l ; 
 
                 s o g g e t t o S e d e R e c : = n u l l ; 
 
                 s o g g e t t o R i f I d : = n u l l ; 
 
                 s o g g e t t o S e d e S e c I d : = n u l l ; 
 
 	 	 i n d i r i z z o R e c : = n u l l ; 
 
                 m i f O r d S p e s a I d : = n u l l ; 
 
 
 
 
 
 
 
 
 
                 i s I n d i r i z z o B e n e f : = t r u e ; 
 
                 i s I n d i r i z z o B e n Q u i e t : = t r u e ; 
 
 
 
 
 
                 b a v v i o F r a z A t t r : = f a l s e ; 
 
                 b A v v i o S i o p e N e w : = f a l s e ; 
 
 
 
 
 
 	         s t a t o B e n e f i c i a r i o : = f a l s e ; 
 
 	 	 s t a t o D e l e g a t o C r e d E f f : = f a l s e ; 
 
 
 
                 - -   l e t t u r a   i m p o r t o   o r d i n a t i v o 
 
   	 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   i m p o r t o   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o : = f n c _ m i f _ i m p o r t o _ o r d i n a t i v o ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , o r d D e t T s T i p o I d , 
 
                 	 	 	 	 	 	 	 	 	 	 	 	 	     	 	               f l u s s o E l a b M i f T i p o D e c ) ; 
 
                 i f   f l u s s o E l a b M i f T i p o D e c = t r u e   a n d 
 
                       c o a l e s c e ( p o s i t i o n ( ' . '   i n   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ) , 0 ) = 0   t h e n 
 
                       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o | | ' . 0 0 ' ; 
 
                 e n d   i f ; 
 
 
 
                 - -   l e t t u r a   M D P   t i   o r d i n a t i v o 
 
   	 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   M D P   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
 	 	 s e l e c t   *   i n t o   M D P R e c 
 
                 f r o m   s i a c _ t _ m o d p a g   m d p 
 
                 w h e r e   m d p . m o d p a g _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ m o d p a g _ i d ; 
 
                 i f   M D P R e c   i s   n u l l   t h e n 
 
                 	 R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   s i a c _ t _ m o d p a g . ' ; 
 
                 e n d   i f ; 
 
 
 
                 - -   l e t t u r a   a c c r e d i t o T i p o   t i   o r d i n a t i v o 
 
   	 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   a c c r e d i t o   t i p o   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 s e l e c t   t i p o . a c c r e d i t o _ t i p o _ i d ,   t i p o . a c c r e d i t o _ t i p o _ c o d e , t i p o . a c c r e d i t o _ t i p o _ d e s c , 
 
                               g r u p p o . a c c r e d i t o _ g r u p p o _ i d ,   g r u p p o . a c c r e d i t o _ g r u p p o _ c o d e 
 
                               i n t o   c o d A c c r e R e c 
 
                 f r o m   s i a c _ d _ a c c r e d i t o _ t i p o   t i p o ,   s i a c _ d _ a c c r e d i t o _ g r u p p o   g r u p p o 
 
                 w h e r e   t i p o . a c c r e d i t o _ t i p o _ i d = M D P R e c . a c c r e d i t o _ t i p o _ i d 
 
                     a n d   t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d   d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	     a n d   d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) 
 
                     a n d   g r u p p o . a c c r e d i t o _ g r u p p o _ i d = t i p o . a c c r e d i t o _ g r u p p o _ i d ; 
 
                 i f   c o d A c c r e R e c   i s   n u l l   t h e n 
 
                 	 R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   s i a c _ d _ a c c r e d i t o _ t i p o   s i a c _ d _ a c c r e d i t o _ g r u p p o . ' ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   l e t t u r a   d a t i   s o g g e t t o   o r d i n a t i v o 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   s o g g e t t o   [ s i a c _ r _ s o g g e t t o _ r e l a z ]   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 s e l e c t   r e l . s o g g e t t o _ i d _ d a   i n t o   s o g g e t t o R i f I d 
 
                 f r o m     s i a c _ r _ s o g g e t t o _ r e l a z   r e l 
 
                 w h e r e   r e l . s o g g e t t o _ i d _ a = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s o g g e t t o _ i d 
 
                 a n d       r e l . r e l a z _ t i p o _ i d = o r d S e d e S e c R e l a z T i p o I d 
 
                 a n d       r e l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       r e l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 a n d       r e l . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                 i f   s o g g e t t o R i f I d   i s   n u l l   t h e n 
 
 	                 s o g g e t t o R i f I d : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s o g g e t t o _ i d ; 
 
                 e l s e 
 
                 	 s o g g e t t o S e d e S e c I d : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s o g g e t t o _ i d ; 
 
                 e n d   i f ; 
 
 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   s o g g e t t o   d i   r i f e r i m e n t o   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 s e l e c t   *   i n t o   s o g g e t t o R e c 
 
       	         f r o m   s i a c _ t _ s o g g e t t o   s o g g 
 
               	 w h e r e   s o g g . s o g g e t t o _ i d = s o g g e t t o R i f I d ; 
 
 
 
                 i f   s o g g e t t o R e c   i s   n u l l   t h e n 
 
                 	 R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   s i a c _ t _ s o g g e t t o   [ s o g g e t t o _ i d =   % ] . ' , s o g g e t t o R i f I d ; 
 
                 e n d   i f ; 
 
 
 
                 i f   s o g g e t t o S e d e S e c I d   i s   n o t   n u l l   t h e n 
 
 	                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   s e d e   s e c .   s o g g e t t o   d i   r i f e r i m e n t o   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                         s e l e c t   *   i n t o   s o g g e t t o S e d e R e c 
 
       	 	         f r o m   s i a c _ t _ s o g g e t t o   s o g g 
 
 	               	 w h e r e   s o g g . s o g g e t t o _ i d = s o g g e t t o S e d e S e c I d ; 
 
 
 
 	                 i f   s o g g e t t o S e d e R e c   i s   n u l l   t h e n 
 
         	         	 R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   s i a c _ t _ s o g g e t t o   [ s o g g e t t o _ i d = % ] ' , s o g g e t t o S e d e S e c I d ; 
 
                 	 e n d   i f ; 
 
 
 
                 e n d   i f ; 
 
 
 
 
 
 
 
                 - -   l e t t u r a   e l e m e n t o   b i l a n c i o     o r d i n a t i v o 
 
   	 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   e l e m e n t o   b i l a n c i o   o r d i n a t i v o   d i   s p e s a   p e r   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
 	 	 s e l e c t   *   i n t o   b i l E l e m R e c 
 
                 f r o m   s i a c _ t _ b i l _ e l e m   e l e m 
 
                 w h e r e   e l e m . e l e m _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ e l e m _ i d ; 
 
                 i f   b i l E l e m R e c   i s   n u l l   t h e n 
 
                 	 R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   s i a c _ t _ b i l _ e l e m . ' ; 
 
                 e n d   i f ; 
 
 
 
 	 	 - -   d a t i   t e s t a t a   f l u s s o   p r e s e n t i   c o m e   t a g   s o l o   i n   t e s t a t a 
 
                 - -   v a l o r i z z a t i   s u   o g n i   o r d i n a t i v o   t r a s m e s s o 
 
                 - -   < t e s t a t a _ f l u s s o > 
 
 	 	 - -   < c o d i c e _ A B I _ B T > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ A B I _ B T ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ a b i   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ a b i _ b t : = e n t e O i l R e c . e n t e _ o i l _ a b i ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ a b i _ b t : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < c o d i c e _ e n t e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ E N T E _ I P A ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ i p a   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i p a : = t r i m ( b o t h   '   '   f r o m   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ i p a ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i p a : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 - -   < d e s c r i z i o n e _ e n t e > 
 
 	         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ D E S C _ E N T E ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e P r o p r i e t a r i o R e c . e n t e _ d e n o m i n a z i o n e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ e n t e : = e n t e P r o p r i e t a r i o R e c . e n t e _ d e n o m i n a z i o n e ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ e n t e : = s u b s t r i n g ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   f r o m   1   f o r   3 0 ) ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 	         - -   < c o d i c e _ i s t a t _ e n t e > 
 
 	         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ I S T A T _ E N T E ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ i s t a t   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i s t a t : = e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ i s t a t ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i s t a t : = s u b s t r i n g ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   f r o m   1   f o r   3 0 ) ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 - -   < c o d i c e _ f i s c a l e _ e n t e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D F I S C _ E N T E ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e P r o p r i e t a r i o R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e : = t r i m ( b o t h   '   '   f r o m   e n t e P r o p r i e t a r i o R e c . c o d i c e _ f i s c a l e ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 - -   < c o d i c e _ t r a m i t e _ e n t e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D T R A M I T E _ E N T E ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ t r a m i t e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e : = t r i m ( b o t h   '   '   f r o m   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ t r a m i t e ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 - -   < c o d i c e _ t r a m i t e _ B T > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D T R A M I T E _ B T ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ t r a m i t e _ b t   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e _ b t : = t r i m ( b o t h   '   '   f r o m   e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ t r a m i t e _ b t ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e _ b t : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < c o d i c e _ e n t e _ B T > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ C O D _ E N T E _ B T ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ c o d i c e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ b t : = t r i m ( b o t h   '   '   f r o m   e n t e O i l R e c . e n t e _ o i l _ c o d i c e ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ b t : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < r i f e r i m e n t o _ e n t e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ R I F E R I M E N T O _ E N T E ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   e n t e O i l R e c . e n t e _ o i l _ r i f e r i m e n t o   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r i f e r i m e n t o _ e n t e : = t r i m ( b o t h   '   '   f r o m   e n t e O i l R e c . e n t e _ o i l _ r i f e r i m e n t o ) ; 
 
                         e l s i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r i f e r i m e n t o _ e n t e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
                 - -   < / t e s t a t a _ f l u s s o > 
 
 
 
                 - -   < t e s t a t a _ e s e r c i z i o > 
 
                 - -   < e s e r c i z i o > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ T E S T _ E S E R C I Z I O ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ e s e r c i z i o : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
                 - -   < / t e s t a t a _ e s e r c i z i o > 
 
 
 
                 m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ I N I Z I O _ O R D ; 
 
                 m i f C o u n t T m p R e c : = F L U S S O _ M I F _ E L A B _ I N I Z I O _ O R D ; 
 
 
 
                 - -   < m a n d a t o > 
 
 	 	 - -   < t i p o _ o p e r a z i o n e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f     f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
 	                         f l u s s o E l a b M i f V a l o r e : = f n c _ m i f _ o r d i n a t i v o _ c a r i c o _ b o l l o (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e , f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m ) ; 
 
                         e l s e 
 
                         	 f l u s s o E l a b M i f V a l o r e : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e ; 
 
                         e n d   i f ; 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < n u m e r o _ m a n d a t o > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 / *                   	 i f   f l u s s o E l a b M i f T i p o D e c = f a l s e   t h e n 
 
 	 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m e r o : = l p a d ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o , N U M _ S E T T E , Z E R O _ P A D ) ; 
 
                         e l s e 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m e r o : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o ; 
 
                         e n d   i f ; * / 
 
                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m e r o : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < d a t a _ m a n d a t o > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e     t h e n 
 
                   i f     f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d a t a : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d a t a _ e m i s s i o n e ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n     e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
 
 
 	 	 - -   < i m p o r t o _ m a n d a t o > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 - -   c a l c o l a t o   i n i z i o   c i c l o 
 
                         n u l l ; 
 
                   e l s e 
 
                   	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o : = ' 0 ' ; 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 - -   < c o n t o _ e v i d e n z a > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d   i s   n o t   n u l l   t h e n 
 
                                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
 	 	 	 	 	       | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c o n t o   t e s o r e r i a . ' ; 
 
 
 
 
 
                         	 s e l e c t   d . c o n t o t e s _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 f r o m   s i a c _ d _ c o n t o t e s o r e r i a   d 
 
                                 w h e r e   d . c o n t o t e s _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d ; 
 
                                 i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                                 	 R A I S E   E X C E P T I O N   '   D a t o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ c o n t o _ t e s : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   7   ) ; 
 
                         e n d   i f ; 
 
 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 
 
                 - -   < e s t r e m i _ p r o v v e d i m e n t o _ a u t o r i z z a t i v o > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
 	 	 	 	 	       | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                 a t t o A m m R e c : = n u l l ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                       i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a t t o _ a m m _ i d   i s   n o t   n u l l   t h e n 
 
 	 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 i f   a t t o A m m T i p o S p r   i s   n u l l   t h e n 
 
                         	 	 a t t o A m m T i p o S p r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   a t t o A m m T i p o A l l   i s   n u l l   t h e n 
 
                                 	 a t t o A m m T i p o A l l : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                         	 e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         s e l e c t   *   i n t o   a t t o A m m R e c 
 
                         f r o m   f n c _ m i f _ e s t r e m i _ a t t o _ a m m ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a t t o _ a m m _ i d , 
 
                                                                                     m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a t t o _ a m m _ m o v g _ i d , 
 
                                                                                     a t t o A m m T i p o S p r , a t t o A m m T i p o A l l , 
 
                                                                                     d a t a E l a b o r a z i o n e , d a t a F i n e V a l ) ; 
 
                       e n d   i f ; 
 
 
 
                       i f   a t t o A m m R e c . a t t o A m m E s t r e m i   i s   n o t   n u l l       t h e n 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ e s t r e m i _ a t t o a m m : = a t t o A m m R e c . a t t o A m m E s t r e m i ; 
 
                       e l s e i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                       	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ e s t r e m i _ a t t o a m m : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                       e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
               e n d   i f ; 
 
 
 
 
 
               - -   < r e s p o n s a b i l e _ p r o v v e d i m e n t o > 
 
 	       f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	       f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	       f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
 	       m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 	       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	     e n d   i f ; 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
 
 
                   i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l o g i n _ c r e a z i o n e   i s   n o t   n u l l   t h e n 
 
 	 	 	 f l u s s o E l a b M i f V a l o r e : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l o g i n _ c r e a z i o n e ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                 	 s e l e c t   s u b s t r i n g ( s . s o g g e t t o _ d e s c     f r o m   1   f o r   1 2 )     i n t o   f l u s s o E l a b M i f V a l o r e D e s c 
 
 	 	 	 f r o m   s i a c _ t _ a c c o u n t   a ,   s i a c _ r _ s o g g e t t o _ r u o l o   r ,   s i a c _ t _ s o g g e t t o   s 
 
 	 	 	 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                         a n d       a . a c c o u n t _ c o d e = f l u s s o E l a b M i f V a l o r e 
 
 	 	 	 a n d       r . s o g g e t o _ r u o l o _ i d = a . s o g g e t o _ r u o l o _ i d 
 
 	 	 	 a n d       s . s o g g e t t o _ i d = r . s o g g e t t o _ i d 
 
                         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         i f   	 f l u s s o E l a b M i f V a l o r e D e s c   i s   n o t   n u l l   t h e n 
 
                         	 f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f V a l o r e D e s c ; 
 
                         e n d   i f ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r e s p _ a t t o a m m : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 2 ) ; 
 
                   e n d   i f ; 
 
               e l s e 
 
 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	       e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < u f f i c i o _ r e s p o n s a b i l e > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
           - -   < b i l a n c i o > 
 
           - -   < c o d i f i c a _ b i l a n c i o > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i f i c a _ b i l a n c i o : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ p r o g r a m m a _ c o d e 
 
                                 	 	 	 	 	 	 	 	 	 	 	 	 | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ t i t o l o _ c o d e ; 
 
 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p i t o l o : = b i l E l e m R e c . e l e m _ c o d e ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 	     - -   < d e s c r i z i o n e _ c o d i f i c a > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ c o d i f i c a : = s u b s t r i n g (   b i l E l e m R e c . e l e m _ d e s c   f r o m   1   f o r   3 0 ) ; 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ c o d i f i c a _ b i l : = s u b s t r i n g (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ p r o g r a m m a _ d e s c   f r o m   1   f o r   3 0 ) ; 
 
           	   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
           	   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < g e s t i o n e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ a n n o _ m o v g   t h e n 
 
 	                         	 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                                 e l s e 
 
 	                                 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ g e s t i o n e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < a n n o _ r e s i d u o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                         i f     m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l ! = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ a n n o _ m o v g     t h e n 
 
                               	       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ r e s : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ a n n o _ m o v g ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 
 
             - -   < n u m e r o _ a r t i c o l o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a r t i c o l o : = b i l E l e m R e c . e l e m _ c o d e 2 ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < v o c e _ e c o n o m i c a > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
 
 
             - -   < i m p o r t o _ b i l a n c i o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                       	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o _ b i l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < / b i l a n c i o > 
 
 
 
             - -   < f u n z i o n a r i o _ d e l e g a t o > 
 
             - -   < c o d i c e _ f u n z i o n a r i o _ d e l e g a t o > 
 
             - -   < i m p o r t o _ f u n z i o n a r i o _ d e l e g a t o > 
 
             - -   < t i p o l o g i a _ f u n z i o n a r i o _ d e l e g a t o > 
 
             - -   < n u m e r o _ p a g a m e n t o _ f u n z i o n a r i o _ d e l e g a t o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 5 ; 
 
 
 
             - -   < i n f o r m a z i o n i _ b e n e f i c i a r i o > 
 
 
 
             - -   < p r o g r e s s i v o _ b e n e f i c i a r i o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 - - 	     r a i s e   n o t i c e   ' p r o g r e s s i v o _ b e n e f i c i a r i o   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ b e n e f : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                 e n d   i f ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < i m p o r t o _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
           	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o _ b e n e f : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; 
 
 	           e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	           e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 
 
 	     - -   < t i p o _ p a g a m e n t o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             t i p o P a g a m R e c : = n u l l ; 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
           	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	       	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         	 i f   c o d i c e P a e s e I T   i s   n u l l   t h e n 
 
                                 	 c o d i c e P a e s e I T : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   c o d i c e A c c r e C B   i s   n u l l   t h e n 
 
 	                                 c o d i c e A c c r e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   c o d i c e A c c r e R E G   i s   n u l l   t h e n 
 
 	                                 c o d i c e A c c r e R E G : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                 e n d   i f ; 
 
 	 	 	 	 i f   c o d i c e S e p a   i s   n u l l   t h e n 
 
 	                                 c o d i c e S e p a : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
                                 e n d   i f ; 
 
 	 	 	 	 i f   c o d i c e E x t r a S e p a   i s   n u l l   t h e n 
 
 	                                 c o d i c e E x t r a S e p a : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 5 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c o d i c e G F B   i s   n u l l   t h e n 
 
 	                                 c o d i c e G F B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 6 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
                                 s e l e c t   *   i n t o   t i p o P a g a m R e c 
 
                                 f r o m   f n c _ m i f _ t i p o _ p a g a m e n t o _ s p l u s (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
 	 	 	 	 	 	 	 	 	 	 	               ( c a s e   w h e n   M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > = 2 
 
                                                                                                       t h e n   s u b s t r i n g ( M D P R e c . i b a n   f r o m   1   f o r   2 ) 
 
                                                                                                       e l s e   n u l l   e n d ) ,   - -   c o d i c e P a e s e 
 
 	                                                                                               c o d i c e P a e s e I T , c o d i c e S e p a , c o d i c e E x t r a S e p a , 
 
                                                                                                       c o d i c e A c c r e C B , c o d i c e A c c r e R E G , 
 
                                                                                                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ,   - -   c o m p e n s a z i o n e 
 
 	 	 	 	 	 	 	 	 	 	 	 	       M D P R e c . a c c r e d i t o _ t i p o _ i d , 
 
                                                                                                       c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e , 
 
                                                                                                       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o : : N U M E R I C ,   - -   i m p o r t o _ o r d i n a t i v o 
 
                                                                                                       ( c a s e   w h e n   c o d A c c r e R e c . a c c r e d i t o _ t i p o _ c o d e = c o d i c e G F B   t h e n   t r u e   e l s e   f a l s e   e n d ) , 
 
 	                                                                                               d a t a E l a b o r a z i o n e , d a t a F i n e V a l , 
 
                                                                                                       e n t e P r o p r i e t a r i o I d ) ; 
 
                                 i f   t i p o P a g a m R e c   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o : = t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o ; 
 
                                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c o d e : = t i p o P a g a m R e c . c o d e T i p o P a g a m e n t o ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
 
 
 	                 e n d   i f ; 
 
           	 e l s e 
 
               	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	         e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < i m p i g n o r a b i l i > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
 
 
             - -   < f r a z i o n a b i l e > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n   - - 1 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n   - - 2 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d   - - 3 
 
                           f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l     t h e n 
 
 
 
                           i f   d a t a A v v i o F r a z A t t r   i s   n u l l   t h e n 
 
                           	 d a t a A v v i o F r a z A t t r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                           e n d   i f ; 
 
 
 
                           i f   d a t a A v v i o F r a z A t t r   i s   n o t   n u l l   a n d 
 
                                 d a t a A v v i o F r a z A t t r : : t i m e s t a m p < = d a t e _ t r u n c ( ' D A Y ' , m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d a t a _ e m i s s i o n e : : t i m e s t a m p )   - -   d a t a   e m i s s i o n e   o r d i n a t i v o 
 
                                 t h e n 
 
                                 b a v v i o F r a z A t t r : = t r u e ; 
 
                           e n d   i f ; 
 
 
 
                           i f   b a v v i o F r a z A t t r = f a l s e   t h e n 
 
                             i f   c l a s s i f T i p o C o d e F r a z   i s   n u l l   t h e n 
 
                               c l a s s i f T i p o C o d e F r a z : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                             e n d   i f ; 
 
 
 
                             i f   c l a s s i f T i p o C o d e F r a z V a l   i s   n u l l   t h e n 
 
                               c l a s s i f T i p o C o d e F r a z V a l : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                             e n d   i f ; 
 
                           e l s e 
 
                             i f   a t t r F r a z i o n a b i l e   i s   n u l l   t h e n 
 
 	                           a t t r F r a z i o n a b i l e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
                             e n d   i f ; 
 
                           e n d   i f ; 
 
 
 
                           i f     b a v v i o F r a z A t t r   =   f a l s e   t h e n 
 
                             i f   c l a s s i f T i p o C o d e F r a z   i s   n o t   n u l l   a n d 
 
 	 	 	 	   c l a s s i f T i p o C o d e F r a z V a l   i s   n o t   n u l l   a n d 
 
                                   c l a s s i f T i p o C o d e F r a z I d   i s   n u l l   t h e n 
 
                                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c l a s s i f i c a t o r e T i p o I d   ' | | c l a s s i f T i p o C o d e F r a z | | ' . ' ; 
 
                           	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   c l a s s i f T i p o C o d e F r a z I d 
 
                                 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c l a s s i f T i p o C o d e F r a z 
 
                                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 o r d e r   b y   t i p o . c l a s s i f _ t i p o _ i d 
 
                                 l i m i t   1 ; 
 
                             e n d   i f ; 
 
 
 
                             i f   c l a s s i f T i p o C o d e F r a z V a l   i s   n o t   n u l l   a n d 
 
                                   c l a s s i f T i p o C o d e F r a z I d   i s   n o t   n u l l   t h e n 
 
                               s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   c l a s s i f i c a t o r e   ' | | c l a s s i f T i p o C o d e F r a z | | '   [ s i a c _ r _ o r d i n a t i v o _ c l a s s ] . ' ; 
 
                           	 s e l e c t   c . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r ,   s i a c _ t _ c l a s s   c 
 
                                 w h e r e   r . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                 a n d       c . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
                                 a n d       c . c l a s s i f _ t i p o _ i d = c l a s s i f T i p o C o d e F r a z I d 
 
                                 a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d       c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 o r d e r   b y   r . o r d _ c l a s s i f _ i d 
 
                                 l i m i t   1 ; 
 
 
 
                             e n d   i f ; 
 
 
 
                             i f   c l a s s i f T i p o C o d e F r a z V a l   i s   n o t   n u l l   a n d 
 
                                 f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   a n d 
 
                                 f l u s s o E l a b M i f V a l o r e = c l a s s i f T i p o C o d e F r a z V a l   t h e n 
 
                           	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                           e n d   i f ; 
 
 	 	 	 e l s e 
 
                             i f   a t t r F r a z i o n a b i l e   i s   n o t   n u l l   t h e n 
 
                               - - -   c a l c o l o   s u   a t t r i b u t o 
 
                               c o d R e s u l t : = n u l l ; 
 
                               s e l e c t   1   i n t o   c o d R e s u l t 
 
                               f r o m     s i a c _ t _ o r d i n a t i v o _ t s   t s , s i a c _ r _ l i q u i d a z i o n e _ o r d   l i q o r d , 
 
                                           s i a c _ r _ l i q u i d a z i o n e _ m o v g e s t   r m o v , 
 
                                           s i a c _ r _ m o v g e s t _ t s _ a t t r   r ,   s i a c _ t _ a t t r   a t t r 
 
                               w h e r e   t s . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                               a n d       l i q o r d . s o r d _ i d = t s . o r d _ t s _ i d 
 
                               a n d       r m o v . l i q _ i d = l i q o r d . l i q _ i d 
 
                               a n d       r . m o v g e s t _ t s _ i d = r m o v . m o v g e s t _ t s _ i d 
 
                               a n d       a t t r . a t t r _ i d = r . a t t r _ i d 
 
                               a n d       a t t r . a t t r _ c o d e = a t t r F r a z i o n a b i l e 
 
                               a n d       r . b o o l e a n = ' N ' 
 
                               a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                               a n d       r m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       r m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                               a n d       l i q o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       l i q o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	       a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       t s . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                               i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                               e n d   i f ; 
 
 
 
                           e n d   i f ; 
 
 
 
                         e n d   i f ; 
 
 
 
                     e n d   i f ;   - -   3 
 
             	   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ;     - - -   2 
 
 
 
                 e n d   i f ;   - -   1 
 
 
 
     	       - -   < g e s t i o n e _ p r o v v i s o r i a > 
 
               f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
               m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                 - -   g e s t i o n e _ p r o v v i s o r i a   d a   i m p o s t a r e   s o l o   s e   f r a z i o n a b i l e = N O 
 
               i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                           f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                           m i f O r d i n a t i v o I d R e c . m i f _ o r d _ b i l _ f a s e _ o p e   i s   n o t   n u l l     t h e n 
 
 
 
                           i f   t i p o E s e r c i z i o   i s   n u l l   t h e n 
 
 	                           t i p o E s e r c i z i o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                           e n d   i f ; 
 
                     	 i f   t i p o E s e r c i z i o = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ b i l _ f a s e _ o p e     t h e n 
 
 	 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ p r o v = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
 	 	       e n d   i f ; 
 
 
 
 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
 
 
                 e n d   i f ; 
 
                 - - -   f r a z i o n a b i l e   d a   i m p o s t a r e   N O   s o l o   s e   g e s t i o n e _ p r o v v i s o r i a = S I 
 
                 i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ p r o v   i s   n u l l   t h e n 
 
                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z : = n u l l ; 
 
                 e n d   i f ; 
 
 
 
             e l s e 
 
               	 n u l l ; 
 
             e n d   i f ; 
 
 
 
             - -   < d a t a _ e s e c u z i o n e _ p a g a m e n t o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             o r d D a t a S c a d e n z a : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l   a n d 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   t h e n 
 
                         	 f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b : = f a l s e ;   - -   s e   R E G O L A R I Z Z A Z I O N E   d a t a _ e s e c u z i o n e _ p a g a m e n t o   n o n   d e v e   e s s e r e   v a l o r i z z a t o 
 
                         e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   d a t a   s c a d e n z a . ' ; 
 
                 	   s e l e c t   s u b . o r d _ t s _ d a t a _ s c a d e n z a   i n t o   o r d D a t a S c a d e n z a 
 
                           f r o m   s i a c _ t _ o r d i n a t i v o _ t s   s u b 
 
                           w h e r e   s u b . o r d _ t s _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s u b o r d _ i d ; 
 
 
 
                           i f   o r d D a t a S c a d e n z a   i s   n o t   n u l l   a n d 
 
 - -                               d a t e _ t r u n c ( ' D A Y ' , o r d D a t a S c a d e n z a ) > =   d a t e _ t r u n c ( ' D A Y ' , d a t a E l a b o r a z i o n e )   a n d 
 
                               d a t e _ t r u n c ( ' D A Y ' , o r d D a t a S c a d e n z a ) >   d a t e _ t r u n c ( ' D A Y ' , d a t a E l a b o r a z i o n e )   a n d   - -   1 3 . 1 2 . 2 0 1 7   S o f i a   s i a c - 5 6 5 3 
 
                               e x t r a c t ( ' y e a r '   f r o m   o r d D a t a S c a d e n z a ) : : i n t e g e r < = a n n o B i l a n c i o : : i n t e g e r   t h e n 
 
 	 	     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ d a t a _ e s e c : = 
 
         	 	                 e x t r a c t ( ' y e a r '   f r o m   o r d D a t a S c a d e n z a ) | | ' - ' | | 
 
         	                   	 l p a d ( e x t r a c t ( ' m o n t h '   f r o m   o r d D a t a S c a d e n z a ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                         	   	 l p a d ( e x t r a c t ( ' d a y '   f r o m   o r d D a t a S c a d e n z a ) : : v a r c h a r , 2 , ' 0 ' ) ; 
 
                           e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
 	           e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	           e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < d a t a _ s c a d e n z a _ p a g a m e n t o > 
 
     	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
 	     - -   < d e s t i n a z i o n e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             c o d R e s u l t : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	       R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   o r 
 
                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n   - - 1 
 
 
 
                       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n   - - 2 
 
 	 	         i f   c l a s s V i n c o l a t o C o d e   i s   n u l l   t h e n 
 
 	                 	 c l a s s V i n c o l a t o C o d e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                         e n d   i f ; 
 
 
 
                         i f   c l a s s V i n c o l a t o C o d e   i s   n o t   n u l l   a n d   c l a s s V i n c o l a t o C o d e I d   i s   n u l l   t h e n 
 
                         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   i d e n t i f i c a t i v o   c l a s s V i n c o l a t o C o d e = ' | | c l a s s V i n c o l a t o C o d e | | ' . ' ; 
 
 
 
                                 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   c l a s s V i n c o l a t o C o d e I d 
 
                                 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c l a s s V i n c o l a t o C o d e ; 
 
 
 
                         e n d   i f ; 
 
 
 
                         i f   c l a s s V i n c o l a t o C o d e I d   i s   n o t   n u l l   t h e n 
 
                         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   p e r   c l a s s V i n c o l a t o C o d e = ' | | c l a s s V i n c o l a t o C o d e | | ' . ' ; 
 
 
 
                                                   s e l e c t   c . c l a s s i f _ d e s c   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                                   f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r ,   s i a c _ t _ c l a s s   c 
 
                                                   w h e r e   r . o r d _ i d =     m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                                   a n d       c . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
                                                   a n d       c . c l a s s i f _ t i p o _ i d = c l a s s V i n c o l a t o C o d e I d 
 
                                                   a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                                   a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                                                   a n d       c . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
                         e n d   i f ; 
 
     	           e n d   i f ;   - - 2 
 
 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d   - - 3 
 
                         m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d   i s   n o t   n u l l   a n d 
 
                 	 m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d ! = 0   t h e n 
 
 
 
 	 	         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
         	 	                                       | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                 	 	                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                         	 	                       | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                 	 	               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                         	 	       | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
 	                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o n t o   c o r r e n t e   t e s o r e r i a   [ m i f _ r _ c o n t o _ t e s o r e r i a _ v i n c o l a t o ] . ' ; 
 
 
 
 	 	 	 s e l e c t   m i f . v i n c o l a t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
         	         f r o m   m i f _ r _ c o n t o _ t e s o r e r i a _ v i n c o l a t o   m i f 
 
 	         	 w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         	         a n d       m i f . c o n t o t e s _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d 
 
 	                 a n d       m i f . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         a n d       m i f . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
 
 
                 e n d   i f ;   - - 3 
 
   	         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                       f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                 e n d   i f ; 
 
 
 
 	         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ d e s t : = f l u s s o E l a b M i f V a l o r e ; 
 
                 e n d   i f ; 
 
 
 
               e n d   i f ;   - - 1 
 
             e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
             e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < n u m e r o _ c o n t o _ b a n c a _ i t a l i a _ e n t e _ r i c e v e n t e > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
           c o d R e s u l t : = n u l l ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
           	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         	 - -   n o n   e s p o s t o   s e   r e g o l a r i z z a z i o n e   ( p r o v v i s o r i ) 
 
                                 i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l   a n d 
 
 - -   2 8 . 1 2 . 2 0 1 7   S o f i a   S I A C - 5 6 6 5 	       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o =   t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) )   t h e n 
 
                     	 	       (   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = 
 
                                           t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) 
 
                                         o r 
 
                                           m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = 
 
                                           t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) 
 
                                         )     t h e n   - -   2 8 . 1 2 . 2 0 1 7   S o f i a   S I A C - 5 6 6 5 
 
 
 
                                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b : = f a l s e ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	                           i f   t i p o M D P C b i   i s   n u l l   t h e n 
 
                                       	 t i p o M D P C b i : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                               	     e n d   i f ; 
 
 
 
 
 
                                     i f   t i p o M D P C b i   i s   n o t   n u l l   t h e n 
 
                                     	 i f   c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e = t i p o M D P C b i   t h e n 
 
                                                 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ c o n t o : = M D P R e c . c o n t o c o r r e n t e ; 
 
                                         e n d   i f ; 
 
                                     e n d   i f ; 
 
                                   e n d   i f ; 
 
 
 
 
 
                         e n d   i f ; 
 
               e l s e 
 
                       R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < t i p o _ c o n t a b i l i t a _ e n t e _ r i c e v e n t e > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           c o d R e s u l t : = n u l l ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
 
 
                                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                       i f   t i p o C l a s s F r u t t i f e r o   i s   n u l l   t h e n 
 
                                         	 t i p o C l a s s F r u t t i f e r o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                       e n d   i f ; 
 
 
 
                                       i f   t i p o C l a s s F r u t t i f e r o   i s   n o t   n u l l   a n d   v a l F r u t t i f e r o   i s   n u l l   t h e n 
 
 	                                       v a l F r u t t i f e r o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                               v a l F r u t t i f e r o S t r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                               v a l F r u t t i f e r o S t r A l t r o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
                                       e n d   i f ; 
 
 
 
                                       i f   t i p o C l a s s F r u t t i f e r o   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o S t r   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o S t r A l t r o   i s   n o t   n u l l   a n d 
 
                                             t i p o C l a s s F r u t t i f e r o I d   i s   n u l l   t h e n 
 
 
 
                                         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c l a s s i f T i p o C o d e I d   ' | | t i p o C l a s s F r u t t i f e r o | | ' . ' ; 
 
                                       	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   t i p o C l a s s F r u t t i f e r o I d 
 
                                         f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                         a n d       t i p o . c l a s s i f _ t i p o _ c o d e = t i p o C l a s s F r u t t i f e r o 
 
                                         a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                       e n d   i f ; 
 
 
 
 
 
                                       i f   t i p o C l a s s F r u t t i f e r o I d   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o S t r   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o S t r A l t r o   i s   n o t   n u l l   a n d 
 
                                             v a l F r u t t i f e r o I d   i s   n u l l   t h e n 
 
 
 
                                         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c l a s s i d I d   ' | | t i p o C l a s s F r u t t i f e r o | | '   [ s i a c _ r _ o r d i n a t i v o _ c l a s s ] . ' ; 
 
 
 
 
 
                                       	 s e l e c t   c . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                         f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r ,   s i a c _ t _ c l a s s   c 
 
                                         w h e r e   r . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
 	                                 a n d       c . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
                                         a n d       c . c l a s s i f _ t i p o _ i d = t i p o C l a s s F r u t t i f e r o I d 
 
                                         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         o r d e r   b y   r . o r d _ c l a s s i f _ i d   l i m i t   1 ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 i f   f l u s s o E l a b M i f V a l o r e = v a l F r u t t i f e r o   T H E N 
 
                                                 	 f l u s s o E l a b M i f V a l o r e = v a l F r u t t i f e r o S t r ; 
 
                                                 e l s e 
 
                                                     f l u s s o E l a b M i f V a l o r e = v a l F r u t t i f e r o S t r A l t r o ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
 
 
                                     e n d   i f ; 
 
 
 
 	 	 	 	 e n d   i f ;   - -   p a r a m 
 
 
 
 	 	 	 	 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l : = f l u s s o E l a b M i f V a l o r e ; 
 
                                 e n d   i f ; 
 
 
 
                               i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l   i s   n u l l   a n d 
 
 	                             m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d   i s   n o t   n u l l   a n d 
 
         	                     m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d ! = 0   t h e n 
 
 
 
                               	     f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	                             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o n t o   c o r r e n t e   t e s o r e r i a   [ m i f _ r _ c o n t o _ t e s o r e r i a _ f r u t t i f e r o ] . ' ; 
 
 	                       	     s e l e c t   m i f . f r u t t i f e r o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
 	                             f r o m   m i f _ r _ c o n t o _ t e s o r e r i a _ f r u t t i f e r o   m i f 
 
         	                     w h e r e   m i f . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 	             a n d       m i f . c o n t o t e s _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o n t o t e s _ i d 
 
                         	     a n d       m i f . v a l i d i t a _ f i n e   i s   n u l l 
 
 	                             a n d       m i f . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
         	                     i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                 	               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l : = f l u s s o E l a b M i f V a l o r e ; 
 
                         	     e n d   i f ; 
 
 
 
                             e n d   i f ; 
 
 
 
                             i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l   i s   n u l l   t h e n 
 
                                       	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                             e n d   i f ; 
 
                       e n d   i f ;   - -   d e f a u l t 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < t i p o _ p o s t a l i z z a z i o n e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             c o d R e s u l t : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             r a i s e   n o t i c e   ' t i p o _ p o s t a l i z z a z i o n e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                         f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                       i f   t i p o P a g a m P o s t A   i s   n u l l   t h e n 
 
                       	 t i p o P a g a m P o s t A : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                       e n d   i f ; 
 
 
 
                       i f   t i p o P a g a m P o s t B   i s   n u l l   t h e n 
 
                       	 t i p o P a g a m P o s t B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                       e n d   i f ; 
 
 
 
 
 
                       i f   t i p o P a g a m P o s t A   i s   n o t   n u l l   o r   t i p o P a g a m P o s t B   i s   n o t   n u l l   t h e n 
 
 	 	 	     i f   t i p o P a g a m R e c   i s   n o t   n u l l   a n d   t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o   i s   n o t   n u l l   t h e n 
 
                             	 i f   t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o   i n   ( t i p o P a g a m P o s t A , t i p o P a g a m P o s t B )   t h e n 
 
 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ p o s t a l i z z a : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                 e n d   i f ; 
 
                             e n d   i f ; 
 
                       e n d   i f ; 
 
 
 
                   e n d   i f ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 
 
             - -   < c l a s s i f i c a z i o n e > 
 
 	     - -   < c o d i c e _ c g u > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
             c o d i c e C g e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             r a i s e   n o t i c e   ' c l a s s i f i c a z i o n e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n   - -   a t t i v o 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n   - -   e l a b 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n   - -   p a r a m 
 
 
 
               	   i f   s i o p e C o d e T i p o   i s   n u l l   a n d   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                   	 s i o p e C o d e T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                   e n d   i f ; 
 
 
 
                   i f   s i o p e D e f   i s   n u l l   a n d   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                   	 s i o p e D e f : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                   e n d   i f ; 
 
 
 
                   i f   c o a l e s c e ( d a t a A v v i o S i o p e N e w , N V L _ S T R ) = N V L _ S T R   a n d 
 
                         f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                       	 d a t a A v v i o S i o p e N e w : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                   e n d   i f ; 
 
 
 
                   i f   c o a l e s c e ( d a t a A v v i o S i o p e N e w , N V L _ S T R ) ! = N V L _ S T R   a n d   c o d i c e F i n V T b r   i s   n u l l   t h e n 
 
               	   	 c o d i c e F i n V T b r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
                   e n d   i f ; 
 
 
 
                   i f   c o a l e s c e ( d a t a A v v i o S i o p e N e w , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
               	     i f   d a t a A v v i o S i o p e N e w : : t i m e s t a m p < = d a t e _ t r u n c ( ' D A Y ' , m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d a t a _ e m i s s i o n e : : t i m e s t a m p )   - -   d a t a   e m i s s i o n e   o r d i n a t i v o 
 
                           t h e n 
 
                             b A v v i o S i o p e N e w : = t r u e ; 
 
                       e n d   i f ; 
 
                   e n d   i f ; 
 
 
 
                   i f   b A v v i o S i o p e N e w = t r u e   t h e n   - -   a v v i o S i o p e N e w 
 
                       i f   c o d i c e F i n V T b r   i s   n o t   n u l l   a n d   c o d i c e F i n V T i p o T b r I d   i s   n u l l   t h e n 
 
 	 	     	 - -   c o d i c e F i n V T i p o T b r I d 
 
                         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   I D   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 	 	 	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   c o d i c e F i n V T i p o T b r I d 
 
 	 	 	 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
 	 	 	 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 	 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c o d i c e F i n V T b r 
 
 	 	 	 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , v a l i d i t a _ i n i z i o ) 
 
 	 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                     e n d   i f ; 
 
 
 
                     i f   c o d i c e F i n V T i p o T b r I d   i s   n o t   n u l l   t h e n 
 
                     	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 
 
                         s e l e c t   r e p l a c e ( s u b s t r i n g ( c l a s s . c l a s s i f _ c o d e , 2 ) , ' . ' , ' ' )   ,   c l a s s . c l a s s i f _ d e s c 
 
                                       i n t o   f l u s s o E l a b M i f V a l o r e , f l u s s o E l a b M i f V a l o r e D e s c 
 
 	 	       	 f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r ,   s i a c _ t _ c l a s s   c l a s s 
 
 	 	 	 w h e r e   r . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
 	 	         a n d       c l a s s . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
 	 	         a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e F i n V T i p o T b r I d 
 
 	 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       r . v a l i d i t a _ f i n e   i s   N U L L 
 
 	 	         a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
                     	 i f       f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 
 
                           s e l e c t   r e p l a c e ( s u b s t r i n g ( c l a s s . c l a s s i f _ c o d e , 2 ) , ' . ' , ' ' )   ,   c l a s s . c l a s s i f _ d e s c 
 
                                       i n t o   f l u s s o E l a b M i f V a l o r e , f l u s s o E l a b M i f V a l o r e D e s c 
 
   	 	       	   f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   r ,   s i a c _ t _ c l a s s   c l a s s 
 
 	 	 	   w h e r e   r . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
 	 	           a n d       c l a s s . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
 	 	           a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e F i n V T i p o T b r I d 
 
 	 	           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       r . v a l i d i t a _ f i n e   i s   N U L L 
 
 	 	           a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
                         e n d   i f ; 
 
 
 
                     e n d   i f ; 
 
                   e l s e   - -   a v v i o S i o p e N e w 
 
                       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   I D   c o d i c e   t i p o = ' | | s i o p e C o d e T i p o | | ' . ' ; 
 
 
 
                       i f   s i o p e C o d e T i p o I d   i s   n u l l   a n d   s i o p e C o d e T i p o   i s   n o t   n u l l   t h e n 
 
                       	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s i o p e C o d e T i p o I d 
 
                         f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                         w h e r e   t i p o . c l a s s i f _ t i p o _ c o d e = s i o p e C o d e T i p o 
 
                         a n d       t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                         a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	   	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                       e n d   i f ; 
 
 
 
                       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o d i c e   t i p o = ' | | s i o p e C o d e T i p o | | ' . ' ; 
 
 
 
                       i f   s i o p e C o d e T i p o I d   i s   n o t   n u l l   t h e n 
 
                       	 s e l e c t   c l a s s . c l a s s i f _ c o d e ,   c l a s s . c l a s s i f _ d e s c 
 
                                       i n t o   f l u s s o E l a b M i f V a l o r e , f l u s s o E l a b M i f V a l o r e D e s c 
 
                         f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   c o r d ,   s i a c _ t _ c l a s s   c l a s s 
 
                         w h e r e   c o r d . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                         a n d   c o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d   c o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d   c l a s s . c l a s s i f _ i d = c o r d . c l a s s i f _ i d 
 
                         a n d   c l a s s . c l a s s i f _ c o d e ! = s i o p e D e f 
 
                         a n d   c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d   c l a s s . c l a s s i f _ t i p o _ i d = s i o p e C o d e T i p o I d ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                           s e l e c t   c l a s s . c l a s s i f _ c o d e ,   c l a s s . c l a s s i f _ d e s c 
 
                                         i n t o   f l u s s o E l a b M i f V a l o r e , f l u s s o E l a b M i f V a l o r e D e s c 
 
                           f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   c o r d ,   s i a c _ t _ c l a s s   c l a s s 
 
                           w h e r e   c o r d . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                           a n d   c o r d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d   c o r d . v a l i d i t a _ f i n e   i s   n u l l 
 
                           a n d   c l a s s . c l a s s i f _ i d = c o r d . c l a s s i f _ i d 
 
                           a n d   c l a s s . c l a s s i f _ c o d e ! = s i o p e D e f 
 
                           a n d   c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d   c l a s s . c l a s s i f _ t i p o _ i d = s i o p e C o d e T i p o I d ; 
 
                         e n d   i f ; 
 
 
 
 
 
                       e n d   i f ; 
 
                   e n d   i f ;   - -   a v v i o S i o p e N e w 
 
 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                   	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c g e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         c o d i c e C g e : = f l u s s o E l a b M i f V a l o r e ; 
 
                   e n d   i f ; 
 
                 e n d   i f ;   - -   p a r a m 
 
               e l s e   - -   e l a b 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ;   - -   e l a b 
 
             e n d   i f ;   - -   a t t i v o 
 
 
 
 	     - -   < c o d i c e _ c u p > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         	 i f   c o a l e s c e ( c u p A t t r C o d e , N V L _ S T R ) = N V L _ S T R   t h e n 
 
                                 	 c u p A t t r C o d e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c o a l e s c e ( c u p A t t r C o d e , N V L _ S T R ) ! = N V L _ S T R   a n d   c u p A t t r I d   i s   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   a t t r _ i d   ' | | c u p A t t r C o d e | | ' . ' ; 
 
                                 	 s e l e c t   a t t r . a t t r _ i d   i n t o   c u p A t t r I d 
 
                                         f r o m   s i a c _ t _ a t t r   a t t r 
 
                                         w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                         a n d       a t t r . a t t r _ c o d e = c u p A t t r C o d e 
 
                                         a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c u p A t t r I d   i s   n o t   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c u p A t t r C o d e | | '   [ s i a c _ r _ o r d i n a t i v o _ a t t r ] . ' ; 
 
 
 
                                 	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t r   a 
 
                                         w h e r e   a . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                         a n d       a . a t t r _ i d = c u p A t t r I d 
 
                                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c u p : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c u p   i s   n u l l   t h e n 
 
                                         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c u p A t t r C o d e | | '   [ s i a c _ r _ l i q u i d a z i o n e _ a t t r ] . ' ; 
 
 
 
                                         	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                                 f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t r     a 
 
                                                 w h e r e   a . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                                                 a n d       a . a t t r _ i d = c u p A t t r I d 
 
                                                 a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                                                 i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
         	                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c u p : = f l u s s o E l a b M i f V a l o r e ; 
 
 	                                         e n d   i f ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < c o d i c e _ c p v > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
             - -   < i m p o r t o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
   	             	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ i m p o r t o : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < / c l a s s i f i c a z i o n e > 
 
 
 
             - -   < c l a s s i f i c a z i o n e _ d a t i _ s i o p e _ u s c i t e > 
 
 	     - -   < t i p o _ d e b i t o _ s i o p e _ c > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             i s O r d C o m m e r c i a l e : = f a l s e ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 - -   2 1 . 1 2 . 2 0 1 7   S o f i a   J I R A   S I A C - 5 6 6 5 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                         t i p o D o c s C o m m : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) | | ' | ' | | 
 
                                             t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) | | ' | ' | | 
 
                                             t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) ; 
 
 
 
                         i s O r d C o m m e r c i a l e : = f n c _ m i f _ o r d i n a t i v o _ e s i s t e _ d o c u m e n t i _ s p l u s (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
                                                                                                                                                   t i p o D o c s C o m m , 
 
                                                                                                       	                                           e n t e P r o p r i e t a r i o I d 
 
                                                                                                                                                 ) ; 
 
 
 
 
 
 / *                 	 i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d   i s   n o t   n u l l   t h e n 
 
                                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   t i p o   d e b i t o   [ s i a c _ d _ s i o p e _ t i p o _ d e b i t o ] . ' ; 
 
                         	 s e l e c t   t i p o . s i o p e _ t i p o _ d e b i t o _ d e s c _ b n k i t   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 f r o m   s i a c _ d _ s i o p e _ t i p o _ d e b i t o   t i p o 
 
                                 w h e r e   t i p o . s i o p e _ t i p o _ d e b i t o _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s i o p e _ t i p o _ d e b i t o _ i d ; 
 
                         e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   a n d 
 
                               u p p e r ( f l u s s o E l a b M i f V a l o r e ) = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   t h e n 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m ; 
 
                               i s O r d C o m m e r c i a l e : = t r u e ; 
 
                         e n d   i f ; * / 
 
                         - -   2 1 . 1 2 . 2 0 1 7   S o f i a   J I R A   S I A C - 5 6 6 5 
 
                         i f   i s O r d C o m m e r c i a l e = t r u e   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 	     - -   < t i p o _ d e b i t o _ s i o p e _ n c > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             c o d R e s u l t : = n u l l ; 
 
             i f   i s O r d C o m m e r c i a l e = f a l s e   t h e n 
 
               f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
               s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
               e n d   i f ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                         - -   2 0 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 8   -   t e s t   s u l   p d c F i n   d i   O P   p e r   v e r i f i c a r e   s e   I V A 
 
                         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                   	   i f   c o a l e s c e ( t i p o P d c I V A , ' ' ) = ' '   t h e n 
 
 	                   	 t i p o P d c I V A : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                           e n d   i f ; 
 
                           i f   c o a l e s c e ( c o d e P d c I V A , ' ' ) = ' '   t h e n 
 
 	                   	 c o d e P d c I V A : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                           e n d   i f ; 
 
 
 
                           i f   c o a l e s c e ( t i p o P d c I V A , ' ' ) ! = ' '     a n d   c o a l e s c e ( c o d e P d c I V A , ' ' ) ! = ' '   t h e n 
 
                                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   V e r i f i c a   t i p o   d e b i t o   I V A . ' ; 
 
                           	 s e l e c t   1   i n t o   c o d R e s u l t 
 
                                 f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r c ,   s i a c _ t _ c l a s s   c ,   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                 w h e r e   r c . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                 a n d       c . c l a s s i f _ i d = r c . c l a s s i f _ i d 
 
                                 a n d       t i p o . c l a s s i f _ t i p o _ i d = c . c l a s s i f _ t i p o _ i d 
 
                                 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = t i p o P d c I V A 
 
                                 a n d       c . c l a s s i f _ c o d e   l i k e   c o d e P d c I V A | | ' % ' 
 
                                 a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       r c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	                               	 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
                           e n d   i f ; 
 
 
 
                         e n d   i f ; 
 
 
 
                         - -   2 1 . 1 2 . 2 0 1 7   S o f i a   J I R A   S I A C - 5 6 6 5 
 
                         - - m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o _ n c : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m ; 
 
 
 
                         - -   2 0 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 8 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                         	 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                         e n d   i f ; 
 
                         - -   2 0 . 0 3 . 2 0 1 8   S o f i a   S I A C - 5 9 6 8 
 
 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o _ n c : = f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                   e n d   i f ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 
 
 
 
 
 
             - -   < c o d i c e _ c i g _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             r a i s e   n o t i c e   ' c o d i c e _ c i g _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
             - -   s o l o   p e r   C O M M E R C I A L I 
 
 	     i f   i s O r d C o m m e r c i a l e = t r u e   t h e n 
 
               f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
               s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
               e n d   i f ; 
 
 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         	 i f   c o a l e s c e ( c i g A t t r C o d e , N V L _ S T R ) = N V L _ S T R   t h e n 
 
                                 	 c i g A t t r C o d e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c o a l e s c e ( c i g A t t r C o d e , N V L _ S T R ) ! = N V L _ S T R   a n d   c i g A t t r C o d e I d   i s   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   a t t r _ i d   ' | | c i g A t t r C o d e | | ' . ' ; 
 
                                 	 s e l e c t   a t t r . a t t r _ i d   i n t o   c i g A t t r C o d e I d 
 
                                         f r o m   s i a c _ t _ a t t r   a t t r 
 
                                         w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                         a n d       a t t r . a t t r _ c o d e = c i g A t t r C o d e 
 
                                         a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c i g A t t r C o d e I d   i s   n o t   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c u p A t t r C o d e | | '   [ s i a c _ r _ o r d i n a t i v o _ a t t r ] . ' ; 
 
 
 
                                 	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t r   a 
 
                                         w h e r e   a . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                         a n d       a . a t t r _ i d = c i g A t t r C o d e I d 
 
                                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c i g : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c i g   i s   n u l l   t h e n 
 
                                         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c i g A t t r C o d e | | '   [ s i a c _ r _ l i q u i d a z i o n e _ a t t r ] . ' ; 
 
 
 
                                         	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                                 f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t r     a 
 
                                                 w h e r e   a . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                                                 a n d       a . a t t r _ i d = c i g A t t r C o d e I d 
 
                                                 a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                                                 i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
         	                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c i g : = f l u s s o E l a b M i f V a l o r e ; 
 
 	                                         e n d   i f ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < m o t i v o _ e s c l u s i o n e _ c i g _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             - -   s o l o   p e r   C O M M E R C I A L I 
 
             i f   i s O r d C o m m e r c i a l e = t r u e   a n d 
 
                   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c i g   i s   n u l l   t h e n 
 
               f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
               s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
               e n d   i f ; 
 
 
 
 	       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
               	     i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d   i s   n o t   n u l l   t h e n 
 
                     	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   m o t i v a z i o n e   [ s i a c _ d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e ] . ' ; 
 
                         r a i s e   n o t i c e   ' s i o p e _ a s s e n z a _ m o t i v a z i o n e _ d e s c _ b n k i t ' ; 
 
 	 	     	 s e l e c t   u p p e r ( a s s . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ d e s c _ b n k i t )   i n t o   f l u s s o E l a b M i f V a l o r e 
 
 	 	 	 f r o m   s i a c _ d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e   a s s 
 
 	 	 	 w h e r e   a s s . s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ s i o p e _ a s s e n z a _ m o t i v a z i o n e _ i d ; 
 
                     e n d   i f ; 
 
 	 	     i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	         	     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ m o t i v o _ n o c i g : = f l u s s o E l a b M i f V a l o r e ; 
 
                             r a i s e   n o t i c e   ' s i o p e _ a s s e n z a _ m o t i v a z i o n e _ d e s c _ b n k i t = % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ m o t i v o _ n o c i g ; 
 
 
 
                     e n d   i f ; 
 
                 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             r a i s e   n o t i c e   ' m o t i v o _ e s c l u s i o n e _ c i g _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
             - -   < f a t t u r e _ s i o p e > 
 
             - -   < / f a t t u r e _ s i o p e > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 2 ; 
 
 
 
             - -   < d a t i _ A R C O N E T _ s i o p e > 
 
 
 
 
 
             - -   < c o d i c e _ m i s s i o n e _ s i o p e > 
 
 	     f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ m i s s i o n e : = S U B S T R I N G ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ p r o g r a m m a _ c o d e   f r o m   1   f o r   2 ) ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             r a i s e   n o t i c e   ' c o d i c e _ m i s s i o n e _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
             - -   < c o d i c e _ p r o g r a m m a _ s i o p e > 
 
 	     f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ p r o g r a m m a : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ p r o g r a m m a _ c o d e ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < c o d i c e _ e c o n o m i c o _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                                                             r a i s e   n o t i c e   ' c o d i c e _ e c o n o m i c o _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
 
 
                     i f   c o d i c e F i n V T b r   i s   n u l l   t h e n 
 
 	 	 	 	 c o d i c e F i n V T b r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                     e n d   i f ; 
 
 
 
 	 	     i f   c o d i c e F i n V T b r   i s   n o t   n u l l   a n d   c o d i c e F i n V T i p o T b r I d   i s   n u l l   t h e n 
 
 	 	     	 - -   c o d i c e F i n V T i p o T b r I d 
 
                         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   I D   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 	 	 	 s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   s t r i c t   c o d i c e F i n V T i p o T b r I d 
 
 	 	 	 f r o m   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
 	 	 	 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 	 a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c o d i c e F i n V T b r 
 
 	 	 	 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	 a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , v a l i d i t a _ i n i z i o ) 
 
 	 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                     e n d   i f ; 
 
 
 
                     i f   c o d i c e F i n V T i p o T b r I d   i s   n o t   n u l l   t h e n 
 
                     	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 
 
                         s e l e c t   c l a s s . c l a s s i f _ c o d e     i n t o   f l u s s o E l a b M i f V a l o r e 
 
 	 	       	 f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r ,   s i a c _ t _ c l a s s   c l a s s 
 
 	 	 	 w h e r e   r . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
 	 	         a n d       c l a s s . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
 	 	         a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e F i n V T i p o T b r I d 
 
 	 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       r . v a l i d i t a _ f i n e   i s   N U L L 
 
 	 	         a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
 
 
                     	 i f       f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   v a l o r e   p e r   c o d i c e   t i p o = ' | | c o d i c e F i n V T b r | | ' . ' ; 
 
 
 
                           s e l e c t   c l a s s . c l a s s i f _ c o d e     i n t o   f l u s s o E l a b M i f V a l o r e 
 
   	 	       	   f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   r ,   s i a c _ t _ c l a s s   c l a s s 
 
 	 	 	   w h e r e   r . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
 	 	           a n d       c l a s s . c l a s s i f _ i d = r . c l a s s i f _ i d 
 
 	 	           a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e F i n V T i p o T b r I d 
 
 	 	           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       r . v a l i d i t a _ f i n e   i s   N U L L 
 
 	 	           a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l ; 
 
                         e n d   i f ; 
 
                     e n d   i f ; 
 
 / * 
 
               	     i f   c o l l E v e n t o C o d e I d   i s   n u l l   t h e n 
 
                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' L e t t u r a   t i p o   c o l l .   e v e n t o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m | | ' . ' ; 
 
 
 
 
 
                         s e l e c t   c o l l . c o l l e g a m e n t o _ t i p o _ i d   i n t o   c o l l E v e n t o C o d e I d 
 
                         f r o m   s i a c _ d _ c o l l e g a m e n t o _ t i p o   c o l l 
 
                         w h e r e   c o l l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                         a n d       c o l l . c o l l e g a m e n t o _ t i p o _ c o d e = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) 
 
                         a n d       c o l l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , c o l l . v a l i d i t a _ i n i z i o ) 
 
 	 	         a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( c o l l . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
                   e n d   i f ; 
 
 
 
 	           i f   c o l l E v e n t o C o d e I d   i s   n o t   n u l l   t h e n 
 
 	 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' L e t t u r a   c o n t o   e c o n o m i c o   p a t r i m o n i a l e . ' ; 
 
                                                           r a i s e   n o t i c e   ' Q U I   Q U I   s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
                     s e l e c t   c o n t o . p d c e _ c o n t o _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                     f r o m   s i a c _ t _ p d c e _ c o n t o   c o n t o ,   s i a c _ t _ r e g _ m o v f i n   r e g M o v F i n ,   s i a c _ r _ e v e n t o _ r e g _ m o v f i n   r E v e n t o , 
 
                               s i a c _ d _ e v e n t o   e v e n t o , 
 
                               s i a c _ t _ m o v _ e p   r e g ,   s i a c _ r _ r e g _ m o v f i n _ s t a t o   r e g s t a t o ,   s i a c _ d _ r e g _ m o v f i n _ s t a t o   s t a t o , 
 
                               s i a c _ t _ p r i m a _ n o t a   p n ,   s i a c _ r _ p r i m a _ n o t a _ s t a t o   r p n o t a ,   s i a c _ d _ p r i m a _ n o t a _ s t a t o   p n s t a t o , 
 
                               s i a c _ t _ m o v _ e p _ d e t   d e t 
 
                     w h e r e   e v e n t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       e v e n t o . c o l l e g a m e n t o _ t i p o _ i d = c o l l E v e n t o C o d e I d   - -   O P 
 
                     a n d       r E v e n t o . e v e n t o _ i d = e v e n t o . e v e n t o _ i d 
 
                     a n d       r E v e n t o . c a m p o _ p k _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                     a n d       r e g M o v F i n . r e g m o v f i n _ i d = r E v e n t o . r e g m o v f i n _ i d 
 
 - -                     a n d       r e g M o v F i n . a m b i t o _ i d = a m b i t o F i n I d     - -   A M B I T O _ F I N   t o g l i a m o   a m b i t o 
 
                     a n d       r e g s t a t o . r e g m o v f i n _ i d = r e g M o v F i n . r e g m o v f i n _ i d 
 
                     a n d       s t a t o . r e g m o v f i n _ s t a t o _ i d = r e g s t a t o . r e g m o v f i n _ s t a t o _ i d 
 
                     a n d       s t a t o . r e g m o v f i n _ s t a t o _ c o d e ! = R E G M O V F I N _ S T A T O _ A 
 
                     a n d       r e g . r e g m o v f i n _ i d = r e g M o v F i n . r e g m o v f i n _ i d 
 
                     a n d       p n . p n o t a _ i d = r e g . r e g e p _ i d 
 
                     a n d       r p n o t a . p n o t a _ i d = p n . p n o t a _ i d 
 
                     a n d       p n s t a t o . p n o t a _ s t a t o _ i d = r p n o t a . p n o t a _ s t a t o _ i d 
 
                     a n d       p n s t a t o . p n o t a _ s t a t o _ c o d e ! = R E G M O V F I N _ S T A T O _ A     - -   f o r s e   s a r e b b e   m e g l i o   p r e n d e r e   s o l o   i   D 
 
                     a n d       d e t . m o v e p _ i d = r e g . m o v e p _ i d 
 
                     a n d       d e t . m o v e p _ d e t _ s e g n o = S E G N O _ E C O N O M I C O   - -   D a r e 
 
 	 	     a n d       c o n t o . p d c e _ c o n t o _ i d = d e t . p d c e _ c o n t o _ i d 
 
                     a n d       r e g M o v F i n . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r e g M o v F i n . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r E v e n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r E v e n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       e v e n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       e v e n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r e g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r e g . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r e g s t a t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r e g s t a t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       p n . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       p n . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r p n o t a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r p n o t a . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       c o n t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       c o n t o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     o r d e r   b y   p n . p n o t a _ i d   d e s c 
 
                     l i m i t   1 ; 
 
                   e n d   i f ; 
 
 * / 
 
               e n d   i f ; 
 
 
 
 
 
                 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ e c o n o m i c o : = f l u s s o E l a b M i f V a l o r e ; 
 
                 e n d   i f ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 	     - -   < i m p o r t o _ c o d i c e _ e c o n o m i c o _ s i o p e > 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ e c o n o m i c o   i s   n o t   n u l l   t h e n 
 
             	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                                                                                                         r a i s e   n o t i c e   ' Q U I   Q U I   s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ i m p o r t o _ e c o n o m i c o : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < c o d i c e _ U E _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	     f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	     c o d R e s u l t : = n u l l ; 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                         r a i s e   n o t i c e   ' c o d i c e _ U E _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
 	     f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	     e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
           	 	 i f   c o d i c e U E C o d e T i p o   i s   n u l l   t h e n 
 
 	 	 	 	 c o d i c e U E C o d e T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
 	                 e n d   i f ; 
 
 
 
                         i f   c o d i c e U E C o d e T i p o   i s   n o t   n u l l   a n d   c o d i c e U E C o d e T i p o I d   i s   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ d _ c l a s s _ t i p o . ' ; 
 
 
 
                 	   s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   c o d i c e U E C o d e T i p o I d 
 
                           f r o m     s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                           w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                           a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c o d i c e U E C o d e T i p o 
 
                           a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
 	 	   	   a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                         e n d   i f ; 
 
 
 
 	                 i f   c o d i c e U E C o d e T i p o I d   i s   n o t   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ o r d i n a t i v o _ c l a s s . ' ; 
 
                                                           r a i s e   n o t i c e   ' Q U I   Q U I   c o d i c e U E C o d e T i p o = %   s t r M e s s a g g i o = % ' , c o d i c e U E C o d e T i p o , s t r M e s s a g g i o ; 
 
 
 
                 	   s e l e c t   c l a s s . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                           f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                           w h e r e   r c l a s s . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                           a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                           a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                           a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e U E C o d e T i p o I d 
 
                           a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           o r d e r   b y   r c l a s s . o r d _ c l a s s i f _ i d 
 
                           l i m i t   1 ; 
 
 
 
                                                           r a i s e   n o t i c e   ' 2 2 2 Q U I   Q U I   c o d i c e U E C o d e T i p o = %   s t r M e s s a g g i o = % ' , c o d i c e U E C o d e T i p o , s t r M e s s a g g i o ; 
 
 
 
                           i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ l i q u i d a z i o n e _ c l a s s . ' ; 
 
                 	     s e l e c t   c l a s s . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                             f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                             w h e r e   r c l a s s . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                             a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                             a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                             a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e U E C o d e T i p o I d 
 
                             a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             o r d e r   b y   r c l a s s . l i q _ c l a s s i f _ i d 
 
                             l i m i t   1 ; 
 
                           e n d   i f ; 
 
 	                 e n d   i f ; 
 
 
 
             	         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                 r a i s e   n o t i c e   ' Q U I   Q U I   f l u s s o E l a b M i f V a l o r e = % ' , f l u s s o E l a b M i f V a l o r e ; 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t r a n s a z _ u e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
 
 
             	   e n d   i f ; 
 
                 e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	 e n d   i f ; 
 
 	     e n d   i f ; 
 
 
 
             - -   < c o d i c e _ u s c i t a _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	     f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	     c o d R e s u l t : = n u l l ; 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                                     r a i s e   n o t i c e   ' c o d i c e _ u s c i t a _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
 	     f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	     e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
           	 	 i f   r i c o r r e n t e C o d e T i p o   i s   n u l l   t h e n 
 
 	 	 	 	 r i c o r r e n t e C o d e T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
 	                 e n d   i f ; 
 
 
 
                         i f   r i c o r r e n t e C o d e T i p o   i s   n o t   n u l l   a n d   r i c o r r e n t e C o d e T i p o I d   i s   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ d _ c l a s s _ t i p o . ' ; 
 
 
 
                 	   s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   r i c o r r e n t e C o d e T i p o I d 
 
                           f r o m     s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                           w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                           a n d       t i p o . c l a s s i f _ t i p o _ c o d e = r i c o r r e n t e C o d e T i p o 
 
                           a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
 	 	   	   a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                         e n d   i f ; 
 
 
 
 	                 i f   r i c o r r e n t e C o d e T i p o I d   i s   n o t   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ o r d i n a t i v o _ c l a s s . ' ; 
 
                                                                                                         r a i s e   n o t i c e   ' Q U I   Q U I   s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
                 	   s e l e c t   u p p e r ( c l a s s . c l a s s i f _ d e s c )   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                           f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                           w h e r e   r c l a s s . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                           a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                           a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                           a n d       c l a s s . c l a s s i f _ t i p o _ i d = r i c o r r e n t e C o d e T i p o I d 
 
                           a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           o r d e r   b y   r c l a s s . o r d _ c l a s s i f _ i d 
 
                           l i m i t   1 ; 
 
 
 
 
 
                           i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ l i q u i d a z i o n e _ c l a s s . ' ; 
 
                 	     s e l e c t   u p p e r ( c l a s s . c l a s s i f _ d e s c )   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                             f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                             w h e r e   r c l a s s . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                             a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                             a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                             a n d       c l a s s . c l a s s i f _ t i p o _ i d = r i c o r r e n t e C o d e T i p o I d 
 
                             a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             o r d e r   b y   r c l a s s . l i q _ c l a s s i f _ i d 
 
                             l i m i t   1 ; 
 
                           e n d   i f ; 
 
 	                 e n d   i f ; 
 
 
 
             	         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ r i c o r r e n t e _ s p e s a : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
 
 
             	   e n d   i f ; 
 
                 e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	 e n d   i f ; 
 
 	     e n d   i f ; 
 
 
 
 
 
             - -   < c o d i c e _ c o f o g _ s i o p e > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	     f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	     c o d R e s u l t : = n u l l ; 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
                                                 r a i s e   n o t i c e   ' c o d i c e _ c o f o g _ s i o p e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
 
 
 	     f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	     e n d   i f ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
         	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
           	 	 i f   c o d i c e C o f o g C o d e T i p o   i s   n u l l   t h e n 
 
 	 	 	 	 c o d i c e C o f o g C o d e T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
 	                 e n d   i f ; 
 
 
 
                         i f   c o d i c e C o f o g C o d e T i p o   i s   n o t   n u l l   a n d   c o d i c e C o f o g C o d e T i p o I d   i s   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ d _ c l a s s _ t i p o . ' ; 
 
 
 
                 	   s e l e c t   t i p o . c l a s s i f _ t i p o _ i d   i n t o   c o d i c e C o f o g C o d e T i p o I d 
 
                           f r o m     s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                           w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                           a n d       t i p o . c l a s s i f _ t i p o _ c o d e = c o d i c e C o f o g C o d e T i p o 
 
                           a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
 	 	   	   a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                         e n d   i f ; 
 
 
 
 	                 i f   c o d i c e C o f o g C o d e T i p o I d   i s   n o t   n u l l   t h e n 
 
                 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ o r d i n a t i v o _ c l a s s . ' ; 
 
                                                                                                         r a i s e   n o t i c e   ' Q U I   Q U I   s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
                 	   s e l e c t   c l a s s . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                           f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                           w h e r e   r c l a s s . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                           a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                           a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                           a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e C o f o g C o d e T i p o I d 
 
                           a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           o r d e r   b y   r c l a s s . o r d _ c l a s s i f _ i d 
 
                           l i m i t   1 ; 
 
 
 
 
 
                           i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   t h e n 
 
                 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   s i a c _ r _ l i q u i d a z i o n e _ c l a s s . ' ; 
 
                 	     s e l e c t   c l a s s . c l a s s i f _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                             f r o m   s i a c _ r _ l i q u i d a z i o n e _ c l a s s   r c l a s s ,   s i a c _ t _ c l a s s   c l a s s 
 
                             w h e r e   r c l a s s . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                             a n d       r c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r c l a s s . v a l i d i t a _ f i n e   i s   n u l l 
 
                             a n d       c l a s s . c l a s s i f _ i d = r c l a s s . c l a s s i f _ i d 
 
                             a n d       c l a s s . c l a s s i f _ t i p o _ i d = c o d i c e C o f o g C o d e T i p o I d 
 
                             a n d       c l a s s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             o r d e r   b y   r c l a s s . l i q _ c l a s s i f _ i d 
 
                             l i m i t   1 ; 
 
                           e n d   i f ; 
 
 	                 e n d   i f ; 
 
 
 
             	         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o f o g _ c o d i c e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
 
 
             	   e n d   i f ; 
 
                 e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	 e n d   i f ; 
 
 	     e n d   i f ; 
 
 
 
             - -   < i m p o r t o _ c o f o g _ s i o p e > 
 
     	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o f o g _ c o d i c e   i s   n o t   n u l l   t h e n 
 
               f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	       f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	       e n d   i f ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o f o g _ i m p o r t o : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; 
 
 
 
                   e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	   e n d   i f ; 
 
 	         e n d   i f ; 
 
               e n d   i f ; 
 
 
 
             - -   < / d a t i _ A R C O N E T _ s i o p e > 
 
 
 
             - -   < / c l a s s i f i c a z i o n e _ d a t i _ s i o p e _ u s c i t e > 
 
 
 
             - -   < b o l l o > 
 
             - -   < a s s o g g e t t a m e n t o _ b o l l o > 
 
       	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             o r d C o d i c e B o l l o D e s c : = n u l l ; 
 
             c o d i c e B o l l o P l u s D e s c : = n u l l ; 
 
             c o d i c e B o l l o P l u s E s e n t e : = f a l s e ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d b o l l o _ i d   i s   n o t   n u l l   t h e n 
 
 
 
 
 
 	       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
     	         e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                     	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l   a n d 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i n 
 
                                   ( t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ,   - -   R E G O L A R I Z Z A Z I O N E 
 
                                     t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) )     - -   F 2 4 E P 
 
                                   )   t h e n 
 
 
 
                               c o d i c e B o l l o P l u s E s e n t e : = t r u e ; 
 
                               - -   R E G O L A R I Z Z A Z I O N E 
 
                               i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = 
 
                                     t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) )   t h e n 
 
                                     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ c a r i c o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                               	     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 2 ) ) ; 
 
                               e n d   i f ; 
 
                               - -   F 2 4 E P 
 
                               i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = 
 
                                     t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) )   t h e n 
 
                                     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ c a r i c o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                               	     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                               e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ c a r i c o   i s   n u l l   t h e n 
 
                     	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c o d i c e   b o l l o . ' ; 
 
 
 
                           s e l e c t   b o l l o . c o d b o l l o _ d e s c   ,   p l u s . c o d b o l l o _ p l u s _ d e s c ,   p l u s . c o d b o l l o _ p l u s _ e s e n t e 
 
                                       i n t o   o r d C o d i c e B o l l o D e s c ,   c o d i c e B o l l o P l u s D e s c ,   c o d i c e B o l l o P l u s E s e n t e 
 
                           f r o m   s i a c _ d _ c o d i c e b o l l o   b o l l o ,   s i a c _ d _ c o d i c e b o l l o _ p l u s   p l u s ,   s i a c _ r _ c o d i c e b o l l o _ p l u s   r p 
 
                           w h e r e   b o l l o . c o d b o l l o _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d b o l l o _ i d 
 
                           a n d       r p . c o d b o l l o _ i d = b o l l o . c o d b o l l o _ i d 
 
                           a n d       p l u s . c o d b o l l o _ p l u s _ i d = r p . c o d b o l l o _ p l u s _ i d 
 
                           a n d       r p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       r p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                           i f   c o a l e s c e ( c o d i c e B o l l o P l u s D e s c , N V L _ S T R ) ! = N V L _ S T R     t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ c a r i c o : = c o d i c e B o l l o P l u s D e s c ; 
 
                           e n d   i f ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	     e n d   i f ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
             - -   < c a u s a l e _ e s e n z i o n e _ b o l l o > 
 
       	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             i f   c o d i c e B o l l o P l u s E s e n t e = t r u e   a n d   c o a l e s c e ( o r d C o d i c e B o l l o D e s c , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
             	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
     	         e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e   i s   n u l l   t h e n 
 
 - -                             2 7 . 0 6 . 2 0 1 8   S o f i a   s i a c - 6 2 7 2 
 
 - - 	                     	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e : = s u b s t r i n g ( o r d C o d i c e B o l l o D e s c   f r o m   1   f o r   3 0 ) ; 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e : = o r d C o d i c e B o l l o D e s c ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	     e n d   i f ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
             - -   < / b o l l o > 
 
 
 
 	     - -   < s p e s e > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             o r d C o d i c e B o l l o D e s c : = n u l l ; 
 
             c o d i c e B o l l o P l u s D e s c : = n u l l ; 
 
             c o d i c e B o l l o P l u s E s e n t e : = f a l s e ; 
 
             - -   < s o g g e t t o _ d e s t i n a t a r i o _ d e l l e _ s p e s e > 
 
             i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o m m _ t i p o _ i d   i s   n o t   n u l l   t h e n 
 
 	       f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
     	         e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   c o d i c e   c o m m i s s i o n e . ' ; 
 
 
 
                         s e l e c t   t i p o . c o m m _ t i p o _ d e s c   ,   p l u s . c o m m _ t i p o _ p l u s _ d e s c ,   p l u s . c o m m _ t i p o _ p l u s _ e s e n t e 
 
                                       i n t o   o r d C o d i c e B o l l o D e s c ,   c o d i c e B o l l o P l u s D e s c ,   c o d i c e B o l l o P l u s E s e n t e 
 
                         f r o m   s i a c _ d _ c o m m i s s i o n e _ t i p o   t i p o ,   s i a c _ d _ c o m m i s s i o n e _ t i p o _ p l u s   p l u s ,   s i a c _ r _ c o m m i s s i o n e _ t i p o _ p l u s   r p 
 
                         w h e r e   t i p o . c o m m _ t i p o _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o m m _ t i p o _ i d 
 
                         a n d       r p . c o m m _ t i p o _ i d = t i p o . c o m m _ t i p o _ i d 
 
                         a n d       p l u s . c o m m _ t i p o _ p l u s _ i d = r p . c o m m _ t i p o _ p l u s _ i d 
 
                         a n d       r p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         i f   c o a l e s c e ( c o d i c e B o l l o P l u s D e s c , N V L _ S T R ) ! = N V L _ S T R     t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ c a r i c o : = c o d i c e B o l l o P l u s D e s c ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	     e n d   i f ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
             - -   < n a t u r a _ p a g a m e n t o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 
 
             - -   < c a u s a l e _ e s e n z i o n e _ s p e s e > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             i f   c o d i c e B o l l o P l u s E s e n t e = t r u e   a n d   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ c a r i c o   i s   n o t   n u l l   t h e n 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	       s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
     	       e n d   i f ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	       	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ e s e n z i o n e : = o r d C o d i c e B o l l o D e s c ; 
 
                     e l s e 
 
 	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	 	     e n d   i f ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
             - -   < / s p e s e > 
 
 
 
 	     - -   < b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             - -   < a n a g r a f i c a _ b e n e f i c i a r i o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             a n a g r a f i c a B e n e f C B I : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 - -               r a i s e   n o t i c e   ' b e n e f i c i a r i o   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   s o g g e t t o S e d e S e c I d   i s   n o t   n u l l   t h e n 
 
                         	 f l u s s o E l a b M i f V a l o r e : = s o g g e t t o R e c . s o g g e t t o _ d e s c | | '   ' | | s o g g e t t o S e d e R e c . s o g g e t t o _ d e s c ; 
 
                         e l s e 
 
                         	 f l u s s o E l a b M i f V a l o r e : = s o g g e t t o R e c . s o g g e t t o _ d e s c ; 
 
                         e n d   i f ; 
 
 
 
                         / * i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d   t i p o M D P C b i   i s   n u l l   t h e n 
 
 	                       	 t i p o M D P C b i : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                         e n d   i f ;   * / 
 
 
 
                         - -   s e   n o n   e   g i r o f o n d o   o   s e   l o   e   m a   i l   c o n t o c o r r e n t e _ i n t e s t a z i o n e   e   v u o t o 
 
                         - -   v a l o r i z z o   i   t a g   d i   a n a g r a f i c a _ b e n e f i c i a r i o 
 
                         - -   a l t r i m e n t i   s o l o   a n a g r a f i c a _ b e n e f i c i a r i o = c o n t o c o r r e n t e _ i n t e s t a z i o n e 
 
                         - -   e   a n a g r a f i c a _ b e n e f i c i a r i o   i n   d a t i _ a _ d i s p o s i z i o n e _ e n t e 
 
                         / * i f   c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e ! = t i p o M D P C b i   o r 
 
 	 	 	       ( c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e = t i p o M D P C b i   a n d 
 
                                   ( M D P R e c . c o n t o c o r r e n t e _ i n t e s t a z i o n e   i s   n u l l   o r   M D P R e c . c o n t o c o r r e n t e _ i n t e s t a z i o n e = ' ' ) )   t h e n 
 
 	                       	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 4 0 ) ; 
 
                         e l s e 
 
 	                         	 a n a g r a f i c a B e n e f C B I : = f l u s s o E l a b M i f V a l o r e ; 
 
 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f : = s u b s t r i n g ( M D P R e c . c o n t o c o r r e n t e _ i n t e s t a z i o n e   f r o m   1   f o r   1 4 0 ) ; 
 
                         e n d   i f ; * / 
 
 
 
                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 4 0 ) ; 
 
 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
 
 
 	   - -   < i n d i r i z z o _ b e n e f i c i a r i o > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   i n d i r i z z o _ b e n e f   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   s o g g e t t o S e d e S e c I d   i s   n o t   n u l l   t h e n 
 
                                 s e l e c t   *   i n t o   i n d i r i z z o R e c 
 
                                 f r o m   s i a c _ t _ i n d i r i z z o _ s o g g e t t o   i n d i r 
 
                                 w h e r e   i n d i r . s o g g e t t o _ i d = s o g g e t t o S e d e S e c I d 
 
                                 a n d       i n d i r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       i n d i r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         e l s e 
 
                         	 s e l e c t   *   i n t o   i n d i r i z z o R e c 
 
                                 f r o m   s i a c _ t _ i n d i r i z z o _ s o g g e t t o   i n d i r 
 
                                 w h e r e   i n d i r . s o g g e t t o _ i d = s o g g e t t o R i f I d 
 
                                 a n d       i n d i r . p r i n c i p a l e = ' S ' 
 
                                 a n d       i n d i r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   	         a n d       i n d i r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         e n d   i f ; 
 
 
 
                         i f   i n d i r i z z o R e c   i s   n u l l   t h e n 
 
                         	 - -   R A I S E   E X C E P T I O N   '   E r r o r e   i n   l e t t u r a   i n d i r i z z o   s o g g e t t o   [ s i a c _ t _ i n d i r i z z o _ s o g g e t t o ] . ' ; 
 
                                 i s I n d i r i z z o B e n e f : = f a l s e ; 
 
                         e n d   i f ; 
 
 
 
                         i f   i s I n d i r i z z o B e n e f = t r u e   t h e n 
 
 
 
                           i f   i n d i r i z z o R e c . v i a _ t i p o _ i d   i s   n o t   n u l l   t h e n 
 
                         	 s e l e c t   t i p o . v i a _ t i p o _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 f r o m   s i a c _ d _ v i a _ t i p o   t i p o 
 
                                 w h e r e   t i p o . v i a _ t i p o _ i d = i n d i r i z z o R e c . v i a _ t i p o _ i d 
 
                                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	   	 	 a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                                 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                 	 f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f V a l o r e | | '   ' ; 
 
                                 e n d   i f ; 
 
                           e n d   i f ; 
 
 
 
                           f l u s s o E l a b M i f V a l o r e : = t r i m ( b o t h   f r o m   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) | | c o a l e s c e ( i n d i r i z z o R e c . t o p o n i m o , ' ' ) 
 
                                                                   | | '   ' | | c o a l e s c e ( i n d i r i z z o R e c . n u m e r o _ c i v i c o , ' ' ) ) ; 
 
 
 
                           i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   a n d   a n a g r a f i c a B e n e f C B I   i s   n u l l   t h e n 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
                           e n d   i f ; 
 
                       e n d   i f ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
       	     - -   < c a p _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   i s I n d i r i z z o B e n e f = t r u e   t h e n 
 
                 i f   i n d i r i z z o R e c . z i p _ c o d e   i s   n o t   n u l l   a n d   a n a g r a f i c a B e n e f C B I   i s   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ b e n e f : = l p a d ( i n d i r i z z o R e c . z i p _ c o d e , 5 , ' 0 ' ) ; 
 
                     e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 	     e n d   i f ; 
 
 
 
             - -   < l o c a l i t a _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   i s I n d i r i z z o B e n e f = t r u e   t h e n 
 
 
 
                 i f   i n d i r i z z o R e c . c o m u n e _ i d   i s   n o t   n u l l   a n d   a n a g r a f i c a B e n e f C B I   i s   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 
 
 	           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     	 s e l e c t   c o m . c o m u n e _ d e s c   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                         f r o m   s i a c _ t _ c o m u n e   c o m 
 
                         w h e r e   c o m . c o m u n e _ i d = i n d i r i z z o R e c . c o m u n e _ i d 
 
                         a n d       c o m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       c o m . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 
 
 	     - -   < p r o v i n c i a _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   i s I n d i r i z z o B e n e f = t r u e   t h e n 
 
 
 
                 i f   i n d i r i z z o R e c . c o m u n e _ i d   i s   n o t   n u l l   a n d   a n a g r a f i c a B e n e f C B I   i s   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     	 s e l e c t   p r o v . s i g l a _ a u t o m o b i l i s t i c a   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                         f r o m   s i a c _ r _ c o m u n e _ p r o v i n c i a   p r o v R e l ,   s i a c _ t _ p r o v i n c i a   p r o v 
 
                         w h e r e   p r o v R e l . c o m u n e _ i d = i n d i r i z z o R e c . c o m u n e _ i d 
 
                         a n d       p r o v R e l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       p r o v R e l . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       p r o v . p r o v i n c i a _ i d = p r o v R e l . p r o v i n c i a _ i d 
 
                         a n d       p r o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       p r o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                         o r d e r   b y   p r o v R e l . d a t a _ c r e a z i o n e ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < s t a t o _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ;   - -   p o p o l a r e   i n   s e g u i t o   r i c a v a t o   i l   c o d i c e _ p a e s e   d i   p i a z z a t u r a 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     i f   a n a g r a f i c a B e n e f C B I   i s   n u l l   a n d 
 
                           s t a t o B e n e f i c i a r i o = f a l s e   t h e n 
 
 	                         s t a t o B e n e f i c i a r i o : = t r u e ; 
 
                       e n d   i f ; 
 
                   e l s e 
 
                       R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
 	     - -   < p a r t i t a _ i v a _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   (   a n a g r a f i c a B e n e f C B I   i s   n u l l   a n d 
 
                         ( s o g g e t t o R e c . p a r t i t a _ i v a   i s   n o t   n u l l   o r 
 
                         ( s o g g e t t o R e c . p a r t i t a _ i v a   i s   n u l l   a n d   s o g g e t t o R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d   l e n g t h ( s o g g e t t o R e c . c o d i c e _ f i s c a l e ) = 1 1 ) ) 
 
                     )       t h e n 
 
             	   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                     	         i f   s o g g e t t o R e c . p a r t i t a _ i v a   i s   n o t   n u l l   t h e n 
 
 	 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f : = s o g g e t t o R e c . p a r t i t a _ i v a ; 
 
                                 e l s e 
 
                                         i f   l e n g t h ( t r i m   (   b o t h   '   '   f r o m   s o g g e t t o R e c . c o d i c e _ f i s c a l e ) ) = 1 1   t h e n 
 
                                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o R e c . c o d i c e _ f i s c a l e ) ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
                     e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
               - -   < c o d i c e _ f i s c a l e _ b e n e f i c i a r i o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 - -             i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f   i s   n u l l   a n d   a n a g r a f i c a B e n e f C B I   i s   n u l l   t h e n 
 
             	   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         - -   s e   C A S S A   c o d i c e _ f i s c a l e   o b b l i g a t o r i o 
 
                     	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
 	 	                         i f   t i p o M D P C o   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 	 e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C o   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C o = c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e   t h e n 
 
                                               i f   s o g g e t t o R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   t h e n 
 
                                         	 f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o R e c . c o d i c e _ f i s c a l e ) ; 
 
                                               e l s e 
 
 	                                         i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f   i s   n o t   n u l l   t h e n 
 
           	                                       f l u s s o E l a b M i f V a l o r e : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f ; 
 
                                                 e n d   i f ; 
 
                                               e n d   i f ; 
 
                                         e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         - -   s e   n o n   C A S S A   v a l o r i z z a t o   s e   p a r t i t a   i v a   n o n   p r e s e n t e   e     c o d i c e _ f i s c a l e = 1 6 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f   i s   n u l l   a n d 
 
                               s o g g e t t o R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d 
 
                               l e n g t h ( s o g g e t t o R e c . c o d i c e _ f i s c a l e ) = 1 6   t h e n 
 
                               f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o R e c . c o d i c e _ f i s c a l e ) ; 
 
                         e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 	 	                           m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
                     e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
                   e n d   i f ; 
 
 - -                 e n d   i f ; 
 
             - -   < / b e n e f i c i a r i o > 
 
 
 
 
 
             - -   < d e l e g a t o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             i s M D P C o : = f a l s e ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                         i f   t i p o M D P C o   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 	 e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C o   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C o = c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e   t h e n 
 
                                         	 i s M D P C o : = t r u e ; 
 
                                         e n d   i f ; 
 
 
 
 	 	 	 	 	 i f   i s M D P C o = t r u e   a n d   - -   n o n   e s p o r r e   s e   R E G O L A R I Z Z A Z I O N E   (   p r o v v i s o r i   d i   c a s s a   ) 
 
                                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l   a n d 
 
                         	 	       (   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) 
 
                                                   o r 
 
                                                   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) 
 
                                               )     t h e n   - -   2 0 . 1 2 . 2 0 1 7   S o f i a   J i r a   S I A C - 5 6 6 5 
 
 	 	 	                           i s M D P C o = f a l s e ; 
 
 	 	 	                 e n d   i f ; 
 
                         e n d   i f ; 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             - -   < a n a g r a f i c a _ d e l e g a t o > 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             i f   i s M D P C o = t r u e   a n d   M D P R e c . q u i e t a n z i a n t e   i s   n o t   n u l l   t h e n 
 
                 	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             	 	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 
 
           	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	 	         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
 	                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         	         e n d   i f ; 
 
                         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                                       	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ q u i e t : = M D P R e c . q u i e t a n z i a n t e ; 
 
                       	 	 e l s e 
 
                       	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	 	                   e n d   i f ; 
 
 	                 e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 7 ; 
 
 - -             r a i s e   n o t i c e   ' c o d f i s c _ q u i e t   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
             - -   < c o d i c e _ f i s c a l e _ d e l e g a t o > 
 
             i f   i s M D P C o = t r u e   a n d   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ q u i e t   i s   n o t   n u l l   a n d 
 
                   M D P R e c . q u i e t a n z i a n t e _ c o d i c e _ f i s c a l e   i s   n o t   n u l l     a n d 
 
                   l e n g t h ( M D P R e c . q u i e t a n z i a n t e _ c o d i c e _ f i s c a l e ) = 1 6       t h e n 
 
                           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ;   - -   7 2 
 
 	 	           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
 	                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         	           e n d   i f ; 
 
                           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                                       	 f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   M D P R e c . q u i e t a n z i a n t e _ c o d i c e _ f i s c a l e ) ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ q u i e t : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
 
 
                       	 	 e l s e 
 
                       	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	 	                 e n d   i f ; 
 
 	                   e n d   i f ; 
 
             e n d   i f ; 
 
             - -   < / d e l e g a t o > 
 
 
 
 	     - -   < c r e d i t o r e _ e f f e t t i v o > 
 
             f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
             f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
             s o g g e t t o Q u i e t R e c : = n u l l ; 
 
             s o g g e t t o Q u i e t R i f R e c : = n u l l ; 
 
             s o g g e t t o Q u i e t I d : = n u l l ; 
 
             s o g g e t t o Q u i e t R i f I d : = n u l l ; 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
             s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             e n d   i f ; 
 
 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
 	             / *   - -   2 0 . 0 4 . 2 0 1 8   S o f i a   J I R A   S I A C - 6 0 9 7 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                           m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l   a n d 
 
                           (   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) 
 
                               o r 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) ) 
 
                               o r   - -   1 3 . 0 4 . 2 0 1 8   S o f i a   J I R A   S I A C - 6 0 9 7 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 5 ) ) 
 
                               o r 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 6 ) ) 
 
                                   - -   1 3 . 0 4 . 2 0 1 8   S o f i a   J I R A   S I A C - 6 0 9 7 
 
                               o r 
 
                               m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 7 ) ) 
 
                                   - -   1 9 . 0 4 . 2 0 1 8   S o f i a   J I R A   S I A C - 6 0 9 7 
 
                           )       t h e n   - -   2 0 . 1 2 . 2 0 1 7   S o f i a   J I R A   s i a c - 5 6 6 5 
 
 
 
                     e n d   i f ; * / 
 
 
 
 
 
                     - -   2 0 . 0 4 . 2 0 1 8   S o f i a   J I R A   S I A C - 6 0 9 7 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o   i s   n o t   n u l l     t h e n 
 
 
 
                       f l u s s o E l a b M i f V a l o r e : =   r e g e x p _ r e p l a c e ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , 
 
                                                                                                 t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) | | ' . ' | | 
 
                                                                                                 t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) | | ' . ' , 
 
 	 	 	 	 	 	 	                                         ' ' ) ; 
 
   	 	       i f     f n c _ m i f _ o r d i n a t i v o _ e s e n z i o n e _ b o l l o ( m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o , f l u s s o E l a b M i f V a l o r e ) = t r u e     t h e n 
 
 	                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = f a l s e ; 
 
                               f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                       e n d   i f ; 
 
                     e n d   i f ; 
 
 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n   - -   n o n   e s p o r r e   s u   r e g o l a r i z z a z i o n e   ( p r o v v i s o r i ) 
 
                       i f     o r d C s i R e l a z T i p o I d   i s   n u l l   t h e n 
 
                         i f   o r d C s i R e l a z T i p o   i s   n u l l   t h e n 
 
                         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
 	                                 o r d C s i R e l a z T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         o r d C s i C O T i p o : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         i f   o r d C s i R e l a z T i p o   i s     n o t   n u l l   t h e n 
 
                                 s e l e c t   t i p o . o i l _ r e l a z _ t i p o _ i d   i n t o   o r d C s i R e l a z T i p o I d 
 
                               	 f r o m   s i a c _ d _ o i l _ r e l a z _ t i p o   t i p o 
 
 	                         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         	                     a n d   t i p o . o i l _ r e l a z _ t i p o _ c o d e = o r d C s i R e l a z T i p o 
 
                 	             a n d   t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                     a n d   t i p o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                         e n d   i f ; 
 
                       e n d   i f ; 
 
 
 
                       i f   o r d C s i R e l a z T i p o I d   i s   n o t   n u l l   a n d 
 
                             (   o r d C s i C O T i p o   i s   n u l l   o r   o r d C s i C O T i p o ! = c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e   )   t h e n 
 
 
 
                                 s o g g e t t o Q u i e t I d : = M D P R e c . s o g g e t t o _ i d ; 
 
 
 
                                 s e l e c t   s o g g . * 
 
                                               i n t o     s o g g e t t o Q u i e t R e c 
 
                                 f r o m   s i a c _ t _ s o g g e t t o   s o g g ,   s i a c _ r _ s o g g r e l _ m o d p a g   r e l m d p , s i a c _ r _ s o g g e t t o _ r e l a z   r e l s o g g , 
 
                                           s i a c _ r _ o i l _ r e l a z _ t i p o   r o i l 
 
                                 w h e r e   s o g g . s o g g e t t o _ i d = M D P R e c . s o g g e t t o _ i d 
 
                                 a n d       s o g g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       s o g g . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d       r e l m d p . m o d p a g _ i d = M D P R e c . m o d p a g _ i d 
 
                                 a n d       r e l m d p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 - -   a n d       r e l m d p . v a l i d i t a _ f i n e   i s   n u l l   0 4 . 0 4 . 2 0 1 8   S o f i a   S I A C - 6 0 6 4 
 
                                 - -   0 4 . 0 4 . 2 0 1 8   S o f i a   S I A C - 6 0 6 4 
 
 	 	 	         a n d   d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( r e l m d p . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) 
 
         	 	 	 a n d       r e l m d p . s o g g e t t o _ r e l a z _ i d = r e l s o g g . s o g g e t t o _ r e l a z _ i d 
 
                                 a n d       r e l s o g g . s o g g e t t o _ i d _ a = M D P R e c . s o g g e t t o _ i d 
 
                                 a n d       r e l s o g g . s o g g e t t o _ i d _ d a = s o g g e t t o R i f I d 
 
                                 a n d       r o i l . r e l a z _ t i p o _ i d = r e l s o g g . r e l a z _ t i p o _ i d 
 
                                 a n d       r o i l . o i l _ r e l a z _ t i p o _ i d = o r d C s i R e l a z T i p o I d 
 
                                 a n d       r e l s o g g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       r e l s o g g . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d       r o i l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       r o i l . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 	 	 	 i f   s o g g e t t o Q u i e t R e c   i s   n u l l   t h e n 
 
                                 	 s o g g e t t o Q u i e t I d : = n u l l ; 
 
                                 e n d   i f ; 
 
 
 
                               i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   t h e n 
 
                                   s e l e c t   s o g g . * 
 
                                                 i n t o   s o g g e t t o Q u i e t R i f R e c 
 
 	 	                   f r o m     s i a c _ t _ s o g g e t t o   s o g g ,   s i a c _ r _ s o g g e t t o _ r e l a z   r e l 
 
 	 	                   w h e r e   r e l . s o g g e t t o _ i d _ a = s o g g e t t o Q u i e t R e c . s o g g e t t o _ i d 
 
 	 	                   a n d       r e l . r e l a z _ t i p o _ i d = o r d S e d e S e c R e l a z T i p o I d 
 
 	 	                   a n d       r e l . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	                   a n d       r e l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                   a n d       r e l . v a l i d i t a _ f i n e   i s   n u l l 
 
                                   a n d       s o g g . s o g g e t t o _ i d = r e l . s o g g e t t o _ i d _ d a 
 
 	 	                   a n d       s o g g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                   a n d       s o g g . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                                   i f   s o g g e t t o Q u i e t R i f R e c   i s   n u l l   t h e n 
 
 
 
                                   e l s e 
 
                                   	 s o g g e t t o Q u i e t R i f I d : = s o g g e t t o Q u i e t R i f R e c . s o g g e t t o _ i d ; 
 
                                   e n d   i f ; 
 
                               e n d   i f ; 
 
                         e n d   i f ; 
 
                     e n d   i f ; 
 
               e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
               e n d   i f ; 
 
             e n d   i f ; 
 
 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
     	     - -   < a n a g r a f i c a _ c r e d i t o r e _ e f f e t t i v o > 
 
             i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 
 
 	           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ;   - - 6 3 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	                         i f   s o g g e t t o Q u i e t R i f I d   i s   n o t   n u l l   t h e n 
 
         	                 	 f l u s s o E l a b M i f V a l o r e : = s o g g e t t o Q u i e t R i f R e c . s o g g e t t o _ d e s c | | '   ' | | s o g g e t t o Q u i e t R e c . s o g g e t t o _ d e s c ; 
 
                 	         e l s e 
 
                         	 	 f l u s s o E l a b M i f V a l o r e : = s o g g e t t o Q u i e t R e c . s o g g e t t o _ d e s c ; 
 
 	                         e n d   i f ; 
 
 
 
                                 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - -                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ d e l : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 4 0 ) ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   c r e d i t o r e _ e f f e t t i v o   - -   a n a g r a f i c a _ b e n e f i c i a r i o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f ; 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 4 0 ) ; 
 
 
 
                                 e n d   i f ; 
 
                   	 e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
 	     e n d   i f ; 
 
 
 
             m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
             - -   < i n d i r i z z o _ c r e d i t o r e _ e f f e t t i v o > 
 
             i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   i n d i r i z z o R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                                 s e l e c t   *   i n t o   i n d i r i z z o R e c 
 
                                 f r o m   s i a c _ t _ i n d i r i z z o _ s o g g e t t o   i n d i r 
 
                                 w h e r e   i n d i r . s o g g e t t o _ i d = s o g g e t t o Q u i e t I d 
 
                                 a n d       ( c a s e   w h e n   s o g g e t t o Q u i e t R i f I d   i s   n u l l 
 
                                                         t h e n   i n d i r . p r i n c i p a l e = ' S '   e l s e   c o a l e s c e ( i n d i r . p r i n c i p a l e , ' N ' ) = ' N '   e n d ) 
 
                                 a n d       i n d i r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       i n d i r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                 i f   i n d i r i z z o R e c   i s   n u l l   t h e n 
 
                                         i s I n d i r i z z o B e n Q u i e t : = f a l s e ; 
 
                         	 e n d   i f ; 
 
 
 
 	 	 	         i f   i s I n d i r i z z o B e n Q u i e t = t r u e   t h e n 
 
 
 
                         	   i f   i n d i r i z z o R e c . v i a _ t i p o _ i d   i s   n o t   n u l l   t h e n 
 
                         	 	 s e l e c t   t i p o . v i a _ t i p o _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 	 f r o m   s i a c _ d _ v i a _ t i p o   t i p o 
 
                               	 	 w h e r e   t i p o . v i a _ t i p o _ i d = i n d i r i z z o R e c . v i a _ t i p o _ i d 
 
 	                                 a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	           	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , t i p o . v a l i d i t a _ i n i z i o ) 
 
   	 	 	   	 	 a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( t i p o . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
 
 
                                 	 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                 	 	 f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f V a l o r e | | '   ' ; 
 
                               	         e n d   i f ; 
 
 
 
                       	 	     e n d   i f ; 
 
 
 
 	                           f l u s s o E l a b M i f V a l o r e : = t r i m ( b o t h   f r o m   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) | | c o a l e s c e ( i n d i r i z z o R e c . t o p o n i m o , ' ' ) 
 
         	                                                           | | '   ' | | c o a l e s c e ( i n d i r i z z o R e c . n u m e r o _ c i v i c o , ' ' ) ) ; 
 
 
 
                 	           i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - - 	                 	         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ d e l : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
 	                           e n d   i f ; 
 
                                 e n d   i f ; 
 
                   	 e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 	   - -   < c a p _ c r e d i t o r e _ e f f e t t i v o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s I n d i r i z z o B e n Q u i e t = t r u e   t h e n 
 
                 i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   a n d   i n d i r i z z o R e c   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 - -                   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ d e l : = l p a d ( i n d i r i z z o R e c . z i p _ c o d e , 5 , ' 0 ' ) ; 
 
 
 
 	 	 	 	 - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                 - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ b e n e f : = l p a d ( i n d i r i z z o R e c . z i p _ c o d e , 5 , ' 0 ' ) ; 
 
                         e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < l o c a l i t a _ c r e d i t o r e _ e f f e t t i v o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s I n d i r i z z o B e n Q u i e t = t r u e   t h e n 
 
                 i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   a n d   i n d i r i z z o R e c . c o m u n e _ i d   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                         	 s e l e c t   c o m . c o m u n e _ d e s c   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                       	 	 f r o m   s i a c _ t _ c o m u n e   c o m 
 
 	                         w h e r e   c o m . c o m u n e _ i d = i n d i r i z z o R e c . c o m u n e _ i d 
 
         	                 a n d       c o m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       c o m . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - - 	 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ d e l : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ b e n e f : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   3 0 ) ; 
 
                 	         e n d   i f ; 
 
                         e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 	   - -   < p r o v i n c i a _ c r e d i t o r e _ e f f e t t i v o > 
 
 	   i f   i s I n d i r i z z o B e n Q u i e t = t r u e   t h e n 
 
                 i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   a n d   i n d i r i z z o R e c . c o m u n e _ i d   i s   n o t   n u l l   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
                         	 s e l e c t   p r o v . s i g l a _ a u t o m o b i l i s t i c a   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                         	 f r o m   s i a c _ r _ c o m u n e _ p r o v i n c i a   p r o v R e l ,   s i a c _ t _ p r o v i n c i a   p r o v 
 
                       	 	 w h e r e   p r o v R e l . c o m u n e _ i d = i n d i r i z z o R e c . c o m u n e _ i d 
 
                       	     	 a n d       p r o v R e l . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       p r o v R e l . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	         a n d       p r o v . p r o v i n c i a _ i d = p r o v R e l . p r o v i n c i a _ i d 
 
                         	 a n d       p r o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       p r o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                 	         o r d e r   b y   p r o v R e l . d a t a _ c r e a z i o n e ; 
 
 
 
 	                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - - 	 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ d e l : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                 	         e n d   i f ; 
 
                         e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 	   - -   < s t a t o _ c r e d i t o r e _ e f f e t t i v o > 
 
           i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l     t h e n 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
               e n d   i f ; 
 
               i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   s t a t o D e l e g a t o C r e d E f f = f a l s e   t h e n 
 
 	                         s t a t o D e l e g a t o C r e d E f f : = t r u e ; 
 
                                 - -   v a l o r i z z a t o   p o i   i n   p i a z z a t u r a 
 
                         e n d   i f ; 
 
                     e l s e 
 
                       R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                     e n d   i f ; 
 
               e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 	   - -   < p a r t i t a _ i v a _ c r e d i t o r e _ e f f e t t i v o > 
 
           i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l   T H E N 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                                 i f     s o g g e t t o Q u i e t R i f I d   i s   n o t   n u l l   t h e n 
 
 	                         	 i f   s o g g e t t o Q u i e t R i f R e c . p a r t i t a _ i v a   i s   n o t   n u l l     o r 
 
                                               ( s o g g e t t o Q u i e t R i f R e c . p a r t i t a _ i v a   i s   n u l l   a n d 
 
                                                 s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d   l e n g t h ( s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e ) = 1 1 ) 
 
                                               t h e n 
 
                                               	 i f   s o g g e t t o Q u i e t R i f R e c . p a r t i t a _ i v a   i s   n o t   n u l l   t h e n 
 
 	         	                           f l u s s o E l a b M i f V a l o r e : = s o g g e t t o Q u i e t R i f R e c . p a r t i t a _ i v a ; 
 
                                                 e l s e 
 
                                                   f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e ) ; 
 
                                                 e n d   i f ; 
 
                                           e n d   i f ; 
 
 	 	 	 	 e l s e 
 
                                 	 i f   s o g g e t t o Q u i e t R e c . p a r t i t a _ i v a   i s   n o t   n u l l     o r 
 
                                               ( s o g g e t t o Q u i e t R e c . p a r t i t a _ i v a   i s   n u l l   a n d 
 
                                                 s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d   l e n g t h ( s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e ) = 1 1 ) 
 
                                               t h e n 
 
                                               	 i f   s o g g e t t o Q u i e t R e c . p a r t i t a _ i v a   i s   n o t   n u l l   t h e n 
 
 	         	                           f l u s s o E l a b M i f V a l o r e : = s o g g e t t o Q u i e t R e c . p a r t i t a _ i v a ; 
 
                                                 e l s e 
 
                                                   f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e ) ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
 
 
 	 	 	         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - - 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ d e l : = f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                                 e n d   i f ; 
 
                   	 e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           - -   < c o d i c e _ f i s c a l e _ c r e d i t o r e _ e f f e t t i v o > 
 
           i f   s o g g e t t o Q u i e t I d   i s   n o t   n u l l     t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         	 i f   s o g g e t t o Q u i e t R i f I d   i s   n o t   n u l l   t h e n 
 
                                   i f   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ d e l   i s   n u l l   t h e n 
 
                                     i f   s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d 
 
                                           l e n g t h ( s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e ) =   1 6   t h e n 
 
 	                                   f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o Q u i e t R i f R e c . c o d i c e _ f i s c a l e ) ; 
 
                                     e n d   i f ; 
 
                                   e n d   i f ; 
 
                                 e l s e 
 
                                   i f   s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e   i s   n o t   n u l l   a n d 
 
                                         l e n g t h ( s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e ) = 1 6   t h e n 
 
 	                                   f l u s s o E l a b M i f V a l o r e : = t r i m   (   b o t h   '   '   f r o m   s o g g e t t o Q u i e t R e c . c o d i c e _ f i s c a l e ) ; 
 
                                   e n d   i f ; 
 
                                 e n d   i f ; 
 
 
 
 	 	 	 	 i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
 - - 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ d e l : = f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5   -   s c a m b i o   t a g 
 
                                         - -   i n   a n a g r a f i c a _ b e n e f i c i a r i o   - -   c r e d i t o r e _ e f f e t t i v o 
 
     	 	                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                                 e n d   i f ; 
 
                   	 e l s e 
 
                         	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < / c r e d i t o r e _ e f f e t t i v o > 
 
 / * * / 
 
 	   - -   < p i a z z a t u r a > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           i s O r d P i a z z a t u r a : = f a l s e ; 
 
           a c c r e d i t o G r u p p o C o d e : = n u l l ; 
 
           i s P a e s e S e p a : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 - -           r a i s e   n o t i c e   ' p i a z z a t u r a   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
               	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         i s O r d P i a z z a t u r a : = f n c _ m i f _ o r d i n a t i v o _ p i a z z a t u r a _ s p l u s ( M D P R e c . a c c r e d i t o _ t i p o _ i d , 
 
                                                                                                                       	 	   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
 	 	     	 	 	 	 	 	 	 	 	 	 	 	                   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , 
 
                                                                                                                                   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o , 
 
 	 	 	                                                                                                           d a t a E l a b o r a z i o n e , d a t a F i n e V a l , e n t e P r o p r i e t a r i o I d ) ; 
 
                   e n d   i f ; 
 
             	 e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
 
 
             	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   t i p o   a c c r e d i t o   M D P   p e r   p o p o l a m e n t o     c a m p i   r e l a t i v i   a ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
 - -                 r a i s e   n o t i c e   ' O r d i n a t i v o   c o n   p i a z z a t u r a   %   c o d i c e   f u n z i o n e = % ' , m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , m i f O r d i n a t i v o I d R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e ; 
 
 
 
 	 	 a c c r e d i t o G r u p p o C o d e : = c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e ; 
 
 	         - - r a i s e   n o t i c e   ' a c c r e d i t o G r u p p o C o d e = %   ' , a c c r e d i t o G r u p p o C o d e ; 
 
 
 
                 i f   M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2     t h e n 
 
                 	 s e l e c t   d i s t i n c t   1   i n t o   i s P a e s e S e p a 
 
                         f r o m   s i a c _ t _ s e p a   s e p a 
 
                         w h e r e   s e p a . s e p a _ i s o _ c o d e = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) 
 
                         a n d       s e p a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                         a n d       s e p a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             	         a n d       d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) > = d a t e _ t r u n c ( ' d a y ' , s e p a . v a l i d i t a _ i n i z i o ) 
 
   	 	 	 a n d 	     d a t e _ t r u n c ( ' d a y ' , d a t a E l a b o r a z i o n e ) < = d a t e _ t r u n c ( ' d a y ' , c o a l e s c e ( s e p a . v a l i d i t a _ f i n e , d a t a E l a b o r a z i o n e ) ) ; 
 
                 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < a b i _ b e n e f i c i a r i o > 
 
   	   m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
 	 	 	 	 	 i f   t i p o M D P C C P   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   6   f o r   5 ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a b i _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	   e n d   i f ; 
 
 	   e n d   i f ; 
 
 
 
           - -   < c a b _ b e n e f i c i a r i o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
                   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
   	           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                   e n d   i f ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
 	 	 	 	 	 i f   t i p o M D P C C P   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1 1   f o r   5 ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a b _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < n u m e r o _ c o n t o _ c o r r e n t e _ b e n e f i c i a r i o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o M D P C C P   i s   n u l l   o r   t i p o M D P C C P = ' '   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1 6   f o r   1 2 ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               c o a l e s c e ( M D P R e c . c o n t o c o r r e n t e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = l p a d ( M D P R e c . c o n t o c o r r e n t e , N U M _ D O D I C I , Z E R O _ P A D ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - - r a i s e   n o t i c e   ' n u m e r o _ c o n t o _ c o r r e n t e _ b e n e f i c i a r i o ' ; 
 
                                         - - r a i s e   n o t i c e   ' t i p o M D P C C P = %   ' , t i p o M D P C C P ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c c _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < c a r a t t e r i _ c o n t r o l l o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
 	         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 	 	 	 	 	 - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
 	 	 	 	 	 i f   t i p o M D P C C P   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   3   f o r   2 ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c t r l _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	 e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < c o d i c e _ c i n > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
 	 	 	 	 	 - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
 	 	 	 	 	 i f   t i p o M D P C C P   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   5   f o r   1 ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c i n _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < c o d i c e _ p a e s e > 
 
 	   m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   t h e n 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	 e n d   i f ; 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
                                         i f   t i p o P a e s e C B   i s   n u l l   t h e n 
 
 	                                         t i p o P a e s e C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 	 	 	 	 	 - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
 	 	 	 	 	 i f   t i p o M D P C C P   i s   n u l l   t h e n 
 
                                         	 t i p o M D P C C P : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > 2   a n d 
 
                                               t i p o P a e s e C B   i s   n o t   n u l l   a n d   t i p o P a e s e C B = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 )   t h e n   - -   s o l o   I T 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
 	 	 	 	 	 - -   1 5 . 0 1 . 2 0 1 8   S o f i a   J I R A   S I A C - 5 7 6 5 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n u l l   a n d 
 
                                               f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                               t i p o M D P C C P   i s   n o t   n u l l   a n d   t i p o M D P C C P = a c c r e d i t o G r u p p o C o d e   t h e n 
 
                                               f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d _ p a e s e _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
 - -                                                 r a i s e   n o t i c e   ' s t a t o B e n f i c i a r i o = % ' , s t a t o B e n e f i c i a r i o ; 
 
                                                 i f   s t a t o B e n e f i c i a r i o = t r u e   a n d   s t a t o D e l e g a t o C r e d E f f = f a l s e   t h e n   - -   s e   C S I   I B A N   n o n   r i p o r t a   d a t i   d e l   b e n e f i c i a r i o   q u i n d i   o m e t t i a m o   c o d i c e _ p a e s e 
 
                                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                                 e n d   i f ; 
 
                                                 i f   s t a t o D e l e g a t o C r e d E f f = t r u e   t h e n 
 
 - - 	                                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ d e l : = f l u s s o E l a b M i f V a l o r e ; 
 
                                                         - -   2 4 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5 
 
                                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f ; 
 
                                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
               e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
           - -   e x t r a   s e p a 
 
           - -   < d e n o m i n a z i o n e _ b a n c a _ d e s t i n a t a r i a > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e   a n d   i s P a e s e S e p a   i s   n u l l   t h e n 
 
 	 	   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           	   f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	 	   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	   e n d   i f ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 	 i f   t i p o M D P C B   i s   n u l l   t h e n 
 
 	                                         t i p o M D P C B : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
 
 
                                         i f   t i p o M D P C B   i s   n o t   n u l l   a n d   t i p o M D P C B = a c c r e d i t o G r u p p o C o d e   a n d 
 
                                               M D P R e c . b a n c a _ d e n o m i n a z i o n e   i s   n o t   n u l l     t h e n 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = M D P R e c . b a n c a _ d e n o m i n a z i o n e ; 
 
                                         e n d   i f ; 
 
                                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e n o m _ b a n c a _ b e n e f : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
         	                 e n d   i f ; 
 
         	     	 e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
           	   e n d   i f ; 
 
           e n d   i f ; 
 
           - -   < / p i a z z a t u r a > 
 
 
 
           - -   s e z i o n e   e s t e r i   s e p a 
 
           - -   < s e p a _ c r e d i t _ t r a n s f e r > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e 
 
                 a n d   i s P a e s e S e p a   i s   n o t   n u l l   t h e n 
 
           	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       	         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	   e n d   i f ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 i f   p a e s e S e p a T r   i s   n u l l   t h e n 
 
 	                 	       	 p a e s e S e p a T r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   a c c r e d i t o G r u p p o S e p a T r   i s   n u l l   t h e n 
 
 	                         	 a c c r e d i t o G r u p p o S e p a T r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   S e p a T r   i s   n u l l   t h e n 
 
 	 	                         S e p a T r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
         	                 i f   a c c r e d i t o G r u p p o S e p a T r   i s   n o t   n u l l   a n d   S e p a T r   i s   n o t   n u l l   a n d   p a e s e S e p a T r   i s   n o t   n u l l   t h e n 
 
 	         	                 s e p a C r e d i t T r a n s f e r : = t r u e ; 
 
                         	 e n d   i f ; 
 
                           e n d   i f ; 
 
                         e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < i b a n > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e 
 
                 a n d   s e p a C r e d i t T r a n s f e r = t r u e 
 
                 a n d   i s P a e s e S e p a   i s   n o t   n u l l 
 
                 a n d   a c c r e d i t o G r u p p o S e p a T r = a c c r e d i t o G r u p p o C o d e   t h e n 
 
           	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       	         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	   e n d   i f ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	           	 i f   M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > = 2   a n d 
 
                 	 	       s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) ! = p a e s e S e p a T r   t h e n 
 
 	 	                       	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s e p a _ i b a n _ t r : = M D P R e c . i b a n ; 
 
 
 
                                       - -   0 1 . 1 0 . 2 0 1 8   S o f i a   S I A C - 6 4 2 1 
 
                                       i f   c o a l e s c e ( s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) , ' ' ) ! = ' '   t h e n 
 
 - -                                                 r a i s e   n o t i c e   ' s t a t o B e n f i c i a r i o = % ' , s t a t o B e n e f i c i a r i o ; 
 
                                                 i f   s t a t o B e n e f i c i a r i o = t r u e   a n d   s t a t o D e l e g a t o C r e d E f f = f a l s e   t h e n 
 
                                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) ; 
 
                                                 e n d   i f ; 
 
                                                 i f   s t a t o D e l e g a t o C r e d E f f = t r u e   t h e n 
 
                                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ d e l : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f ; 
 
                                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f : = s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
 
 
                 	 	 e n d   i f ; 
 
                         e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < b i c > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           i f   i s O r d P i a z z a t u r a = t r u e 
 
                 a n d   s e p a C r e d i t T r a n s f e r = t r u e 
 
                 a n d   i s P a e s e S e p a   i s   n o t   n u l l 
 
                 a n d   a c c r e d i t o G r u p p o S e p a T r = a c c r e d i t o G r u p p o C o d e   t h e n 
 
           	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       	         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
             	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	   e n d   i f ; 
 
                   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	 	           	 i f   M D P R e c . b i c   i s   n o t   n u l l   a n d 
 
                                       M D P R e c . i b a n   i s   n o t   n u l l   a n d   l e n g t h ( M D P R e c . i b a n ) > = 2   a n d 
 
                 	 	       s u b s t r i n g ( u p p e r ( M D P R e c . i b a n )   f r o m   1   f o r   2 ) ! = p a e s e S e p a T r   t h e n 
 
 	 	                       m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s e p a _ b i c _ t r : = M D P R e c . b i c ; 
 
                 	 	 e n d   i f ; 
 
                         e l s e 
 
                 	         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
                   e n d   i f ; 
 
           e n d   i f ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 5 ; 
 
           - -   < / s e p a _ c r e d i t _ t r a n s f e r > 
 
 
 
 
 
           - -   < c a u s a l e >   a n c o r a   i n f o r m a z i o n i _ b e n e f i c i a r i o 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 - -           r a i s e   n o t i c e   ' c a u s a l e   m i f C o u n t R e c = % ' , m i f C o u n t R e c ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . L e t t u r a   C U P - C I G . ' ; 
 
                         	 i f   c u p C a u s A t t r   i s   n u l l   t h e n 
 
 	                         	 c u p C a u s A t t r : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   c i g C a u s A t t r   i s   n u l l   t h e n 
 
 	                                 c i g C a u s A t t r : = t r i m   ( b o t h   '   ' 	   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c o a l e s c e ( c u p C a u s A t t r , N V L _ S T R ) ! = N V L _ S T R     a n d   c u p C a u s A t t r I d   i s   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   a t t r _ i d   ' | | c u p C a u s A t t r | | ' . ' ; 
 
                                 	 s e l e c t   a t t r . a t t r _ i d   i n t o   c u p C a u s A t t r I d 
 
                                         f r o m   s i a c _ t _ a t t r   a t t r 
 
                                         w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                         a n d       a t t r . a t t r _ c o d e = c u p C a u s A t t r 
 
                                         a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c o a l e s c e ( c i g C a u s A t t r , N V L _ S T R ) ! = N V L _ S T R   a n d   c i g C a u s A t t r I d   i s   n u l l   t h e n 
 
 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   a t t r _ i d   ' | | c i g C a u s A t t r | | ' . ' ; 
 
                                 	 s e l e c t   a t t r . a t t r _ i d   i n t o   c i g C a u s A t t r I d 
 
                                         f r o m   s i a c _ t _ a t t r   a t t r 
 
                                         w h e r e   a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                         a n d       a t t r . a t t r _ c o d e = c i g C a u s A t t r 
 
                                         a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                 e n d   i f ; 
 
 
 
 
 
                                 i f   c u p C a u s A t t r I d   i s   n o t   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c u p C a u s A t t r | | '   [ s i a c _ r _ o r d i n a t i v o _ a t t r ] . ' ; 
 
 
 
                                 	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t r   a 
 
                                         w h e r e   a . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                         a n d       a . a t t r _ i d = c u p C a u s A t t r I d 
 
                                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) = N V L _ S T R   t h e n 
 
                                               	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c u p C a u s A t t r | | '   [ s i a c _ r _ l i q u i d a z i o n e _ a t t r ] . ' ; 
 
 
 
                                         	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                                 f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t r     a 
 
                                                 w h e r e   a . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                                                 a n d       a . a t t r _ i d = c u p C a u s A t t r I d 
 
                                                 a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
 
 
                                 i f   c i g C a u s A t t r I d   i s   n o t   n u l l   t h e n 
 
                                 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c i g C a u s A t t r | | '   [ s i a c _ r _ o r d i n a t i v o _ a t t r ] . ' ; 
 
 
 
                                 	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e D e s c 
 
                                         f r o m   s i a c _ r _ o r d i n a t i v o _ a t t r   a 
 
                                         w h e r e   a . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                         a n d       a . a t t r _ i d = c i g C a u s A t t r I d 
 
                                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e D e s c , N V L _ S T R ) = N V L _ S T R   t h e n 
 
                                               	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
 	                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
         	                                       | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                 	                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                         	                       | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                 	               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                         	       | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   v a l o r e   ' | | c i g C a u s A t t r | | '   [ s i a c _ r _ l i q u i d a z i o n e _ a t t r ] . ' ; 
 
 
 
                                         	 s e l e c t   a . t e s t o   i n t o   f l u s s o E l a b M i f V a l o r e D e s c 
 
                                                 f r o m   s i a c _ r _ l i q u i d a z i o n e _ a t t r     a 
 
                                                 w h e r e   a . l i q _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l i q _ i d 
 
                                                 a n d       a . a t t r _ i d = c i g C a u s A t t r I d 
 
                                                 a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                         e n d   i f ; 
 
                                 e n d   i f ; 
 
 
 
                         e n d   i f ; 
 
                         - -   c u p 
 
 	 	 	 i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , N V L _ S T R ) ! = N V L _ S T R   t h e n 
 
 	 	 	               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e : = c u p C a u s A t t r | | '   ' | | f l u s s o E l a b M i f V a l o r e ; 
 
 
 
                         e n d   i f ; 
 
                         - -   c i g 
 
 	 	 	 i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e D e s c , N V L _ S T R ) ! = N V L _ S T R     t h e n 
 
                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e : = 
 
                                             t r i m   ( b o t h   '   '   f r o m   c o a l e s c e ( m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e , '   ' ) | | 
 
                                                       '   ' | | c i g C a u s A t t r | | '   ' | | f l u s s o E l a b M i f V a l o r e D e s c ) ; 
 
                         e n d   i f ; 
 
 
 
 
 
 	 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e : = 
 
             	 	 	 r e p l a c e ( r e p l a c e ( s u b s t r i n g ( t r i m   ( b o t h   '   '   f r o m   c o a l e s c e ( m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e , '   ' ) | | '   ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d e s c   ) 
 
 	                                                         f r o m   1   f o r   3 7 0 )   ,   c h r ( V T _ A S C I I ) , c h r ( S P A C E _ A S C I I ) ) , c h r ( B S _ A S C I I ) , N V L _ S T R ) ; 
 
 
 
 - - 	 	 	 r a i s e   n o t i c e   ' m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e   % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e ; 
 
 
 
 
 
 	           e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	           e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < s o s p e s o > 
 
           - -   < n u m e r o _ p r o v v i s o r i o > 
 
           - -   < i m p o r t o _ p r o v v i s o r i o > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 2 ; 
 
 
 
 	   - -   < r i t e n u t a > 
 
           - -   < i m p o r t o _ r i t e n u t e > 
 
           - -   < n u m e r o _ r e v e r s a l e > 
 
           - -   < p r o g r e s s i v o _ v e r s a n t e > 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 3 ; 
 
 
 
 	   - -   < i n f o r m a z i o n i _ a g g i u n t i v e > 
 
 
 
           - -   < l i n g u a > 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l i n g u a : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
 
 
 - -                                 r a i s e   n o t i c e   ' L I N G U A   d e f   %   % ' , f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o , f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                         e n d   i f ; 
 
 	           e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	           e n d   i f ; 
 
           e n d   i f ; 
 
 
 
 
 
         - -   < r i f e r i m e n t o _ d o c u m e n t o _ e s t e r n o > 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         i f   t i p o P a g a m R e c   i s   n o t   n u l l   t h e n 
 
         	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
                 f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
                 f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
                 c o d R e s u l t : = n u l l ; 
 
 
 
                 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 	         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	   	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	         e n d   i f ; 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
         	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                 	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   a n d 
 
                                       f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
 
 
 	 	 	 	         - -   3 0 . 0 7 . 2 0 1 8   S o f i a   s i a c - 6 2 0 2 
 
                                         i f   c o a l e s c e ( t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 5 ) ) , ' ' ) ! = ' '   t h e n 
 
 
 
                                               s e l e c t   1   i n t o   c o d R e s u l t 
 
                                               f r o m   s i a c _ r _ o r d i n a t i v o _ c l a s s   r c ,   s i a c _ t _ c l a s s   c   ,   s i a c _ d _ c l a s s _ t i p o   t i p o 
 
                                               w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                               a n d       t i p o . c l a s s i f _ t i p o _ c o d e = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 5 ) ) 
 
                                               a n d       c . c l a s s i f _ t i p o _ i d = t i p o . c l a s s i f _ t i p o _ i d 
 
                                               a n d       r c . c l a s s i f _ i d = c . c l a s s i f _ i d 
 
                                               a n d       r c . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               a n d       r c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                               a n d       r c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                                               i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	 	                                       s e l e c t   *   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                                       f r o m   f n c _ m i f _ o r d i n a t i v o _ s p l u s _ g e t _ m e s e ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d a t a _ e m i s s i o n e ) ; 
 
                                               e n d   i f ; 
 
 
 
                                               i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) ! = ' '   t h e n 
 
                                               	 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 3 ) ) 
 
                                                                                           | | '   ' | | f l u s s o E l a b M i f V a l o r e ; 
 
                                               e n d   i f ; 
 
                                         e n d   i f ; 
 
                                         - -   3 0 . 0 7 . 2 0 1 8   S o f i a   s i a c - 6 2 0 2 
 
 
 
 
 
                                         - -   m o d a l i t a   a c c r e d i t o = S T I   -   S T I P E N D I 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) = ' '   a n d   - -   3 0 . 0 7 . 2 0 1 8   S o f i a   s i a c - 6 2 0 2 
 
                                               c o d A c c r e R e c . a c c r e d i t o _ t i p o _ c o d e   = 
 
                                                       t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 3 ) )   t h e n 
 
                                                       f l u s s o E l a b M i f V a l o r e : = 
 
                                                           t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 2 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f     c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) = ' '   a n d   - -   3 0 . 0 7 . 2 0 1 8   S o f i a   s i a c - 6 2 0 2 
 
                                                 t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o   i n 
 
                                                 ( t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) , 
 
                                                   t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) 
 
                                                 )   t h e n 
 
 	 	                                 f l u s s o E l a b M i f V a l o r e : = t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o ; 
 
                                         e n d   i f ; 
 
 
 
                                         - -   2 3 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5 
 
 	 	 	                 i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) = ' '   a n d   - -   3 0 . 0 7 . 2 0 1 8   S o f i a   s i a c - 6 2 0 2 
 
                                               c o d A c c r e R e c . a c c r e d i t o _ g r u p p o _ c o d e   = 
 
                                                       t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 4 ) )   a n d 
 
                                                       M D P R e c . c o n t o c o r r e n t e   i s   n o t   n u l l   a n d   M D P R e c . c o n t o c o r r e n t e ! = ' ' 
 
                                                         t h e n 
 
                                                       f l u s s o E l a b M i f V a l o r e : = M D P R e c . c o n t o c o r r e n t e ; 
 
                                         e n d   i f ; 
 
                                         - -   2 3 . 0 1 . 2 0 1 8   S o f i a   j i r a   s i a c - 5 7 6 5 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) = ' '   a n d   t i p o P a g a m R e c . d e f R i f D o c E s t e r n o = t r u e   t h e n 
 
                                                 f l u s s o E l a b M i f V a l o r e : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f , S E P A R A T O R E , 1 ) ) ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   c o a l e s c e ( f l u s s o E l a b M i f V a l o r e , ' ' ) ! = ' '   t h e n 
 
 	                                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r i f _ d o c _ e s t e r n o : = f l u s s o E l a b M i f V a l o r e ; 
 
                                         e n d   i f ; 
 
 	 	                 e n d   i f ; 
 
 	 	 	 e l s e 
 
           	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	 	         e n d   i f ; 
 
         	 e n d   i f ; 
 
         e n d   i f ; 
 
 
 
         - -   1 6 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0   -   v e d i   d i   s e g u i t o   i m p l e m e n t a z i o n e   t a g 
 
         - -   < a v v i s o _ p a g o P A > 
 
         - -   < c o d i c e _ i d e n t i f i c a t i v o _ e n t e > 
 
         - -   < n u m e r o _ a v v i s o > 
 
         - -   < / a v v i s o _ p a g o P A > 
 
 
 
         - -   < / i n f o r m a z i o n i _ a g g i u n t i v e > 
 
 
 
 
 
 
 
 
 
         - -   < s o s t i t u z i o n e _ m a n d a t o > 
 
 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         o r d S o s t R e c : = n u l l ; 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
         e n d   i f ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                                 	 s e l e c t   *   i n t o   o r d S o s t R e c 
 
                                         f r o m   f n c _ m i f _ o r d i n a t i v o _ s o s t i t u i t o (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
   	 	 	 	 	 	 	 	 	 	 	 	 	 	 o r d R e l a z C o d e T i p o I d , 
 
                                                                                                                 d a t a E l a b o r a z i o n e , d a t a F i n e V a l ) ; 
 
         	 e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	         e n d   i f ; 
 
 
 
         e n d   i f ; 
 
 
 
       m i f C o u n t R e c : = m i f C o u n t R e c + 3 ; 
 
       i f   o r d S o s t R e c   i s   n o t   n u l l   t h e n 
 
       	 	   f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
       	 	   f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c - 2 ] ; 
 
 	           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c - 2 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   - -   < n u m e r o _ m a n d a t o _ d a _ s o s t i t u i r e > 
 
             	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
             	   e n d   i f ; 
 
 
 
             	   i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	       i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 - -                 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m _ o r d _ c o l l e g : = l p a d ( o r d S o s t R e c . o r d N u m e r o S o s t i t u t o : : v a r c h a r , N U M _ S E T T E , Z E R O _ P A D ) ; 
 
                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m _ o r d _ c o l l e g : = o r d S o s t R e c . o r d N u m e r o S o s t i t u t o : : v a r c h a r ; 
 
 	         	 e l s e 
 
           	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	           	 e n d   i f ; 
 
                   e n d   i f ; 
 
 
 
           	 - -   < p r o g r e s s i v o _ b e n e f i c i a r i o _ d a _ s o s t u i r e > 
 
           	 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
     	         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c - 1 ] ; 
 
 	         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c - 1 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	         e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f   i s   n o t   n u l l   t h e n 
 
                                 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ o r d _ c o l l e g : = f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f D e f ; 
 
                                 e n d   i f ; 
 
           	         e l s e 
 
           	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
 	         e n d   i f ; 
 
 
 
                 - -   < e s e r c i z i o _ m a n d a t o _ d a _ s o s t i t u i r e > 
 
                 f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	 	 f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	         e n d   i f ; 
 
 
 
                 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                               	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ o r d _ c o l l e g : = o r d S o s t R e c . o r d A n n o S o s t i t u t o ; 
 
           	         e l s e 
 
           	 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	                 e n d   i f ; 
 
 	         e n d   i f ; 
 
 
 
           e n d   i f ; 
 
 
 
 
 
           - -   < d a t i _ a _ d i s p o s i z i o n e _ e n t e _ b e n e f i c i a r i o >   f a c o l t a t i v o   n o n   v a l o r i z z a t o 
 
           - -   < / i n f o r m a z i o n i _ b e n e f i c i a r i o > 
 
 
 
           - -   < d a t i _ a _ d i s p o s i z i o n e _ e n t e _ m a n d a t o > 
 
 	   - -   < c o d i c e _ d i s t i n t a > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	   s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	   e n d   i f ; 
 
 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
             i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
             	 	 i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d i s t _ i d   i s   n o t   n u l l   t h e n 
 
 	 	 	 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' .   L e t t u r a   d i s t i n t a   [ s i a c _ d _ d i s t i n t a ] . ' ; 
 
                         	 s e l e c t     d . d i s t _ c o d e   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                                 f r o m   s i a c _ d _ d i s t i n t a   d 
 
                                 w h e r e   d . d i s t _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ d i s t _ i d ; 
 
                         e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                             	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ d i s t i n t a : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
             e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	     e n d   i f ; 
 
 	   e n d   i f ; 
 
 
 
           - -   < a t t o _ c o n t a b i l e > 
 
           f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
           f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
           m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
           f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
           s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
           e n d   i f ; 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
 	           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                   	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   t h e n 
 
                                 i f   a t t o A m m T i p o A l l R a g   i s   n u l l   t h e n 
 
                         	 	 a t t o A m m T i p o A l l R a g : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) ) ; 
 
                                 e n d   i f ; 
 
                                 i f   a t t o A m m S t r T i p o R a g   i s   n u l l   t h e n 
 
                                 	 a t t o A m m S t r T i p o R a g : = t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 2 ) ) ; 
 
                   	 	 e n d   i f ; 
 
 
 
                                 i f   a t t o A m m T i p o A l l R a g   i s   n o t   n u l l   a n d     a t t o A m m S t r T i p o R a g   i s   n o t   n u l l   t h e n 
 
 
 
                                   f l u s s o E l a b M i f V a l o r e : = f n c _ m i f _ e s t r e m i _ a t t o a m m _ a l l ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a t t o _ a m m _ i d , 
 
                                   	 	 	 	 	 	 	 	 	 	                     a t t o A m m T i p o A l l R a g , a t t o A m m S t r T i p o R a g , 
 
                                                                                                                                     d a t a E l a b o r a z i o n e ,   d a t a F i n e V a l ) ; 
 
 
 
                                 e n d   i f ; 
 
                     	 e n d   i f ; 
 
 
 
                         i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                                   	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ a t t o _ c o n t a b i l e : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
 
 
                   e l s e 
 
                         R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
             - -   1 5 . 0 1 . 2 0 1 8   S o f i a   S I A C - 5 7 6 5 
 
             - -   < c o d i c e _ o p e r a t o r e > 
 
 	     f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
 	     f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
 	     f l u s s o E l a b M i f V a l o r e D e s c : = n u l l ; 
 
 	     m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
 	     f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	 	     R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	     e n d   i f ; 
 
 	     i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
       	 	 i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
 
 
                   i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l o g i n _ c r e a z i o n e   i s   n o t   n u l l   t h e n 
 
 	 	 	 f l u s s o E l a b M i f V a l o r e : = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ l o g i n _ c r e a z i o n e ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                 	 s e l e c t   s u b s t r i n g ( s . s o g g e t t o _ d e s c     f r o m   1   f o r   1 2 )     i n t o   f l u s s o E l a b M i f V a l o r e D e s c 
 
 	 	 	 f r o m   s i a c _ t _ a c c o u n t   a ,   s i a c _ r _ s o g g e t t o _ r u o l o   r ,   s i a c _ t _ s o g g e t t o   s 
 
 	 	 	 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                         a n d       a . a c c o u n t _ c o d e = f l u s s o E l a b M i f V a l o r e 
 
 	 	 	 a n d       r . s o g g e t o _ r u o l o _ i d = a . s o g g e t o _ r u o l o _ i d 
 
 	 	 	 a n d       s . s o g g e t t o _ i d = r . s o g g e t t o _ i d 
 
                         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       a . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         i f   	 f l u s s o E l a b M i f V a l o r e D e s c   i s   n o t   n u l l   t h e n 
 
                         	 f l u s s o E l a b M i f V a l o r e : = f l u s s o E l a b M i f V a l o r e D e s c ; 
 
                         e n d   i f ; 
 
                   e n d   i f ; 
 
 
 
                   i f   f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   t h e n 
 
                         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d e _ o p e r a t o r e : = s u b s t r i n g ( f l u s s o E l a b M i f V a l o r e   f r o m   1   f o r   1 2 ) ; 
 
                   e n d   i f ; 
 
               e l s e 
 
 	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
     	       e n d   i f ; 
 
           e n d   i f ; 
 
 
 
           - -   < / d a t i _ a _ d i s p o s i z i o n e _ e n t e _ m a n d a t o > 
 
 
 
 
 
         - -   0 9 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0 
 
         - -   < a v v i s o _ p a g o P A > 
 
         i s P a g o P A : = f a l s e ; 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	 e n d   i f ; 
 
 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
                         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m   i s   n o t   n u l l   a n d 
 
                               t i p o P a g a m R e c . d e s c T i p o P a g a m e n t o   = 
 
                                                       t r i m   ( b o t h   '   '   f r o m   s p l i t _ p a r t ( f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f P a r a m , S E P A R A T O R E , 1 ) )   t h e n 
 
                                   i s P a g o P A   : = t r u e ; 
 
                         e n d   i f ; 
 
           e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	   e n d   i f ; 
 
 	 e n d   i f ; 
 
 
 
         - -   < c o d i c e _ i d e n t i f i c a t i v o _ e n t e > 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	 e n d   i f ; 
 
 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 
 
 	           i f   i s P a g o P A     =   t r u e   t h e n 
 
                         i f     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f   i s   n o t   n u l l   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g o p a _ c o d f i s c : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f ; 
 
                         e l s e 
 
                                 i f     m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f   i s   n o t   n u l l   t h e n 
 
 	                                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g o p a _ c o d f i s c : = m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
 	 	 e n d   i f ; 
 
             e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	     e n d   i f ; 
 
 	 e n d   i f ; 
 
         - -   < / c o d i c e _ i d e n t i f i c a t i v o _ e n t e > 
 
 
 
 
 
         - -   < n u m e r o _ a v v i s o > 
 
         f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
         m i f C o u n t R e c : = m i f C o u n t R e c + 1 ; 
 
         f l u s s o E l a b M i f V a l o r e : = n u l l ; 
 
         f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
 	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f I d   i s   n u l l   t h e n 
 
     	   	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o   n o n   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
 	 e n d   i f ; 
 
 
 
         i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f A t t i v o = t r u e   t h e n 
 
           i f   f l u s s o E l a b M i f E l a b R e c . f l u s s o E l a b M i f E l a b = t r u e   t h e n 
 
 	           i f   i s P a g o P A     =   t r u e   t h e n 
 
                         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O 
 
                                               | | ' .   L e t t u r a   n u m e r o   a v v i s o   P a g o P A ' 
 
                                               | | ' . ' ; 
 
                         s e l e c t   d o c . c o d _ a v v i s o _ p a g o _ p a   i n t o   f l u s s o E l a b M i f V a l o r e 
 
                         f r o m   s i a c _ t _ o r d i n a t i v o _ t s   t s   , s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r , s i a c _ t _ s u b d o c   s u b , s i a c _ t _ d o c   d o c 
 
                         w h e r e   t s . o r d _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                         a n d       r . o r d _ t s _ i d = t s . o r d _ t s _ i d 
 
                         a n d       s u b . s u b d o c _ i d = r . s u b d o c _ i d 
 
                         a n d       d o c . d o c _ i d = s u b . d o c _ i d 
 
                         a n d       d o c . c o d _ a v v i s o _ p a g o _ p a   i s   n o t   n u l l 
 
                         a n d       d o c . c o d _ a v v i s o _ p a g o _ p a ! = ' ' 
 
                         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                         l i m i t   1 ; 
 
 
 
                         i f     f l u s s o E l a b M i f V a l o r e   i s   n o t   n u l l   a n d   f l u s s o E l a b M i f V a l o r e ! = ' '   t h e n 
 
                         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g o p a _ n u m _ a v v i s o : = f l u s s o E l a b M i f V a l o r e ; 
 
                         e n d   i f ; 
 
 	 	   e n d   i f ; 
 
             e l s e 
 
           	 	 R A I S E   E X C E P T I O N   '   C o n f i g u r a z i o n e   t a g / c a m p o     n o n   e l a b o r a b i l e . ' ; 
 
 	     e n d   i f ; 
 
 	 e n d   i f ; 
 
         - -   < / n u m e r o _ a v v i s o > 
 
         - -   < / a v v i s o _ p a g o P A > 
 
         - -   0 9 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0 
 
 
 
           - -   < / m a n d a t o > 
 
 / * * / 
 
                 / * r a i s e   n o t i c e   ' c o d i c e _ f u n z i o n e =   % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e ; 
 
 	 	 r a i s e   n o t i c e   ' n u m e r o _ m a n d a t o =   % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m e r o ; 
 
                 r a i s e   n o t i c e   ' d a t a _ m a n d a t o =   % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d a t a ; 
 
                 r a i s e   n o t i c e   ' i m p o r t o _ m a n d a t o =   % ' , m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o ; * / 
 
 
 
 	 	   s t r M e s s a g g i o : = ' I n s e r i m e n t o   m i f _ t _ o r d i n a t i v o _ s p e s a   p e r   o r d .   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                 I N S E R T   I N T O   m i f _ t _ o r d i n a t i v o _ s p e s a 
 
                 ( 
 
     	 	 - -   m i f _ o r d _ d a t a _ e l a b ,   d e f   n o w 
 
     	 	   m i f _ o r d _ f l u s s o _ e l a b _ m i f _ i d , 
 
   	 	   m i f _ o r d _ b i l _ i d , 
 
   	 	   m i f _ o r d _ o r d _ i d , 
 
     	 	   m i f _ o r d _ a n n o , 
 
     	 	   m i f _ o r d _ n u m e r o , 
 
     	 	   m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
     	 	   m i f _ o r d _ d a t a , 
 
     	 	   m i f _ o r d _ i m p o r t o , 
 
     	 	   m i f _ o r d _ f l a g _ f i n _ l o c , 
 
     	 	   m i f _ o r d _ d o c u m e n t o , 
 
     	 	   m i f _ o r d _ b c i _ t i p o _ e n t e _ p a g , 
 
     	 	   m i f _ o r d _ b c i _ d e s t _ e n t e _ p a g , 
 
     	 	   m i f _ o r d _ b c i _ c o n t o _ t e s , 
 
   	 	   m i f _ o r d _ e s t r e m i _ a t t o a m m , 
 
                   m i f _ o r d _ r e s p _ a t t o a m m , 
 
                   m i f _ o r d _ u f f _ r e s p _ a t t o m m , 
 
     	 	   m i f _ o r d _ c o d i c e _ a b i _ b t , 
 
     	 	   m i f _ o r d _ c o d i c e _ e n t e , 
 
     	 	   m i f _ o r d _ d e s c _ e n t e , 
 
     	 	   m i f _ o r d _ c o d i c e _ e n t e _ b t , 
 
     	 	   m i f _ o r d _ a n n o _ e s e r c i z i o , 
 
                   m i f _ o r d _ c o d i c e _ f l u s s o _ o i l , 
 
     	 	   m i f _ o r d _ i d _ f l u s s o _ o i l , 
 
     	 	   m i f _ o r d _ d a t a _ c r e a z i o n e _ f l u s s o , 
 
     	 	   m i f _ o r d _ a n n o _ f l u s s o , 
 
   	 	   m i f _ o r d _ c o d i c e _ s t r u t t u r a , 
 
     	 	   m i f _ o r d _ e n t e _ l o c a l i t a , 
 
     	 	   m i f _ o r d _ e n t e _ i n d i r i z z o , 
 
   	 	   m i f _ o r d _ c o d i c e _ r a g g r u p , 
 
     	 	   m i f _ o r d _ p r o g r _ b e n e f , 
 
                   m i f _ o r d _ p r o g r _ d e s t , 
 
     	 	   m i f _ o r d _ b c i _ c o n t o , 
 
     	 	   m i f _ o r d _ b c i _ t i p o _ c o n t a b i l , 
 
     	 	   m i f _ o r d _ c l a s s _ c o d i c e _ c g e , 
 
     	 	   m i f _ o r d _ c l a s s _ i m p o r t o , 
 
     	 	   m i f _ o r d _ c l a s s _ c o d i c e _ c u p , 
 
     	 	   m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ p r o v , 
 
     	 	   m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z , 
 
     	 	   m i f _ o r d _ c o d i f i c a _ b i l a n c i o , 
 
                   m i f _ o r d _ c a p i t o l o , 
 
     	 	   m i f _ o r d _ a r t i c o l o , 
 
     	 	   m i f _ o r d _ d e s c _ c o d i f i c a , 
 
                   m i f _ o r d _ d e s c _ c o d i f i c a _ b i l , 
 
     	 	   m i f _ o r d _ g e s t i o n e , 
 
     	 	   m i f _ o r d _ a n n o _ r e s , 
 
     	 	   m i f _ o r d _ i m p o r t o _ b i l , 
 
     	 	   m i f _ o r d _ s t a n z , 
 
         	   m i f _ o r d _ m a n d a t i _ s t a n z , 
 
     	 	   m i f _ o r d _ d i s p o n i b i l i t a , 
 
     	 	   m i f _ o r d _ p r e v , 
 
     	 	   m i f _ o r d _ m a n d a t i _ p r e v , 
 
     	 	   m i f _ o r d _ d i s p _ c a s s a , 
 
     	 	   m i f _ o r d _ a n a g _ b e n e f , 
 
     	 	   m i f _ o r d _ i n d i r _ b e n e f , 
 
     	 	   m i f _ o r d _ c a p _ b e n e f , 
 
     	 	   m i f _ o r d _ l o c a l i t a _ b e n e f , 
 
     	 	   m i f _ o r d _ p r o v _ b e n e f , 
 
                   m i f _ o r d _ s t a t o _ b e n e f , 
 
     	 	   m i f _ o r d _ p a r t i v a _ b e n e f , 
 
     	 	   m i f _ o r d _ c o d f i s c _ b e n e f , 
 
     	 	   m i f _ o r d _ a n a g _ q u i e t , 
 
     	 	   m i f _ o r d _ i n d i r _ q u i e t , 
 
     	 	   m i f _ o r d _ c a p _ q u i e t , 
 
     	 	   m i f _ o r d _ l o c a l i t a _ q u i e t , 
 
     	 	   m i f _ o r d _ p r o v _ q u i e t , 
 
     	 	   m i f _ o r d _ p a r t i v a _ q u i e t , 
 
     	 	   m i f _ o r d _ c o d f i s c _ q u i e t , 
 
 	           m i f _ o r d _ s t a t o _ q u i e t , 
 
     	 	   m i f _ o r d _ a n a g _ d e l , 
 
                   m i f _ o r d _ i n d i r _ d e l , 
 
                   m i f _ o r d _ c a p _ d e l , 
 
                   m i f _ o r d _ l o c a l i t a _ d e l , 
 
                   m i f _ o r d _ p r o v _ d e l , 
 
     	 	   m i f _ o r d _ c o d f i s c _ d e l , 
 
                   m i f _ o r d _ p a r t i v a _ d e l , 
 
                   m i f _ o r d _ s t a t o _ d e l , 
 
     	 	   m i f _ o r d _ i n v i o _ a v v i s o , 
 
     	 	   m i f _ o r d _ a b i _ b e n e f , 
 
     	 	   m i f _ o r d _ c a b _ b e n e f , 
 
     	 	   m i f _ o r d _ c c _ b e n e f _ e s t e r o , 
 
   	 	   m i f _ o r d _ c c _ b e n e f , 
 
                   m i f _ o r d _ c t r l _ b e n e f , 
 
     	 	   m i f _ o r d _ c i n _ b e n e f , 
 
     	 	   m i f _ o r d _ c o d _ p a e s e _ b e n e f , 
 
     	 	   m i f _ o r d _ d e n o m _ b a n c a _ b e n e f , 
 
     	 	   m i f _ o r d _ c c _ p o s t a l e _ b e n e f , 
 
     	 	   m i f _ o r d _ s w i f t _ b e n e f , 
 
     	 	   m i f _ o r d _ i b a n _ b e n e f , 
 
                   m i f _ o r d _ s e p a _ i b a n _ t r , 
 
                   m i f _ o r d _ s e p a _ b i c _ t r , 
 
                   m i f _ o r d _ s e p a _ i d _ e n d _ t r , 
 
     	 	   m i f _ o r d _ b o l l o _ e s e n z i o n e , 
 
     	 	   m i f _ o r d _ b o l l o _ c a r i c o , 
 
     	 	   m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e , 
 
     	 	   m i f _ o r d _ c o m m i s s i o n i _ c a r i c o , 
 
                   m i f _ o r d _ c o m m i s s i o n i _ e s e n z i o n e , 
 
     	 	   m i f _ o r d _ c o m m i s s i o n i _ i m p o r t o , 
 
                   m i f _ o r d _ c o m m i s s i o n i _ n a t u r a , 
 
     	 	   m i f _ o r d _ p a g a m _ t i p o , 
 
     	 	   m i f _ o r d _ p a g a m _ c o d e , 
 
     	 	   m i f _ o r d _ p a g a m _ i m p o r t o , 
 
     	 	   m i f _ o r d _ p a g a m _ c a u s a l e , 
 
     	 	   m i f _ o r d _ p a g a m _ d a t a _ e s e c , 
 
     	 	   m i f _ o r d _ l i n g u a , 
 
     	 	   m i f _ o r d _ r i f _ d o c _ e s t e r n o , 
 
     	 	   m i f _ o r d _ i n f o _ t e s o r i e r e , 
 
     	 	   m i f _ o r d _ f l a g _ c o p e r t u r a , 
 
     	 	   m i f _ o r d _ n u m _ o r d _ c o l l e g , 
 
     	 	   m i f _ o r d _ p r o g r _ o r d _ c o l l e g , 
 
     	 	   m i f _ o r d _ a n n o _ o r d _ c o l l e g , 
 
     	 	   m i f _ o r d _ c o d e _ o p e r a t o r e ,   - -   1 5 . 0 1 . 2 0 1 8   S o f i a   S I A C - 5 7 6 5 
 
     	 	   m i f _ o r d _ d e s c r i _ e s t e s a _ c a p , 
 
     	 	   m i f _ o r d _ s i o p e _ c o d i c e _ c g e , 
 
     	 	   m i f _ o r d _ s i o p e _ d e s c r i _ c g e , 
 
                   m i f _ o r d _ c o d i c e _ e n t e _ i p a , 
 
                   m i f _ o r d _ c o d i c e _ e n t e _ i s t a t , 
 
                   m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e , 
 
                   m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e _ b t , 
 
 	           m i f _ o r d _ r i f e r i m e n t o _ e n t e , 
 
                   m i f _ o r d _ i m p o r t o _ b e n e f , 
 
                   m i f _ o r d _ p a g a m _ p o s t a l i z z a , 
 
                   m i f _ o r d _ c l a s s _ t i p o _ d e b i t o , 
 
                   m i f _ o r d _ c l a s s _ t i p o _ d e b i t o _ n c , 
 
                   m i f _ o r d _ c l a s s _ c i g , 
 
                   m i f _ o r d _ c l a s s _ m o t i v o _ n o c i g , 
 
                   m i f _ o r d _ c l a s s _ m i s s i o n e , 
 
                   m i f _ o r d _ c l a s s _ p r o g r a m m a , 
 
                   m i f _ o r d _ c l a s s _ e c o n o m i c o , 
 
                   m i f _ o r d _ c l a s s _ i m p o r t o _ e c o n o m i c o , 
 
                   m i f _ o r d _ c l a s s _ t r a n s a z _ u e , 
 
                   m i f _ o r d _ c l a s s _ r i c o r r e n t e _ s p e s a , 
 
                   m i f _ o r d _ c l a s s _ c o f o g _ c o d i c e , 
 
                   m i f _ o r d _ c l a s s _ c o f o g _ i m p o r t o , 
 
                   m i f _ o r d _ c o d i c e _ d i s t i n t a , 
 
                   m i f _ o r d _ c o d i c e _ a t t o _ c o n t a b i l e , 
 
                   - -   1 6 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0 
 
                   m i f _ o r d _ p a g o p a _ c o d f i s c , 
 
                   m i f _ o r d _ p a g o p a _ n u m _ a v v i s o , 
 
     	 	   v a l i d i t a _ i n i z i o , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
     	 	   l o g i n _ o p e r a z i o n e 
 
 	 	 ) 
 
 	 	 V A L U E S 
 
                 ( 
 
 	     	   - - : m i f _ o r d _ d a t a _ e l a b , 
 
     	 	   f l u s s o E l a b M i f L o g I d ,   - - i d E l a b o r a z i o n e   u n i v o c o 
 
     	 	   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ b i l _ i d , 
 
     	 	   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
     	 	   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ a n n o , 
 
     	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m e r o , 
 
     	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e , 
 
     	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d a t a , 
 
 - -     	           ( c a s e   w h e n   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ f u n z i o n e   i n   ( F U N Z I O N E _ C O D E _ N , F U N Z I O N E _ C O D E _ A )   t h e n 
 
 - -                                         ' 0 . 0 0 '   e l s e   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o   e n d ) , 
 
                   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ f l a g _ f i n _ l o c , 
 
     	           m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d o c u m e n t o , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ e n t e _ p a g , 
 
   	   	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ d e s t _ e n t e _ p a g , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ c o n t o _ t e s , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ e s t r e m i _ a t t o a m m , 
 
                   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r e s p _ a t t o a m m , 
 
     	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ u f f _ r e s p _ a t t o m m , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ a b i _ b t , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e , 
 
 	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ e n t e , 
 
     	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ b t , 
 
   	 	   m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ e s e r c i z i o , 
 
     	 	 a n n o B i l a n c i o | | f l u s s o E l a b M i f D i s t O i l R e t I d : : v a r c h a r , 
 
     	 	 f l u s s o E l a b M i f O i l I d ,   - - i d f l u s s o O i l 
 
                 e x t r a c t ( y e a r   f r o m   n o w ( ) ) | | ' - ' | | 
 
                 l p a d ( e x t r a c t ( ' m o n t h '   f r o m   n o w ( ) ) : : v a r c h a r , 2 , ' 0 ' ) | | ' - ' | | 
 
                 l p a d ( e x t r a c t ( ' d a y '   f r o m   n o w ( ) ) : : v a r c h a r , 2 , ' 0 ' ) | | ' T ' | | 
 
                 l p a d ( e x t r a c t ( ' h o u r '   f r o m   n o w ( ) ) : : v a r c h a r , 2 , ' 0 ' ) | | ' : ' | | 
 
                 l p a d ( e x t r a c t ( ' m i n u t e '   f r o m   n o w ( ) ) : : v a r c h a r , 2 , ' 0 ' ) | | ' : ' | | ' 0 0 ' ,     - -   m i f _ o r d _ d a t a _ c r e a z i o n e _ f l u s s o 
 
                 e x t r a c t ( y e a r   f r o m   n o w ( ) ) : : i n t e g e r , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ s t r u t t u r a , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ e n t e _ l o c a l i t a , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ e n t e _ i n d i r i z z o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ r a g g r u p , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ d e s t , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ c o n t o , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b c i _ t i p o _ c o n t a b i l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c g e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ i m p o r t o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ c u p , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ p r o v , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o d i c e _ g e s t _ f r a z , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i f i c a _ b i l a n c i o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p i t o l o , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a r t i c o l o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ c o d i f i c a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c _ c o d i f i c a _ b i l , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ g e s t i o n e , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ r e s , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o _ b i l , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a n z , 
 
         	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ m a n d a t i _ s t a n z , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d i s p o n i b i l i t a , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r e v , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ m a n d a t i _ p r e v , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d i s p _ c a s s a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ b e n e f , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ b e n e f , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ q u i e t , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ q u i e t , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ q u i e t , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ q u i e t , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ q u i e t , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ q u i e t , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ q u i e t , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ q u i e t , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n a g _ d e l , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n d i r _ d e l , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a p _ d e l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l o c a l i t a _ d e l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o v _ d e l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d f i s c _ d e l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a r t i v a _ d e l , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s t a t o _ d e l , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n v i o _ a v v i s o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a b i _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c a b _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c c _ b e n e f _ e s t e r o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c c _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c t r l _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c i n _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d _ p a e s e _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e n o m _ b a n c a _ b e n e f , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c c _ p o s t a l e _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s w i f t _ b e n e f , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i b a n _ b e n e f , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s e p a _ i b a n _ t r , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s e p a _ b i c _ t r , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s e p a _ i d _ e n d _ t r , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ e s e n z i o n e , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ b o l l o _ c a r i c o , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d i n _ b o l l o _ c a u s _ e s e n z i o n e , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ c a r i c o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ e s e n z i o n e , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ i m p o r t o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o m m i s s i o n i _ n a t u r a , 
 
     	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ t i p o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c o d e , 
 
 	         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ i m p o r t o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ c a u s a l e , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ d a t a _ e s e c , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ l i n g u a , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r i f _ d o c _ e s t e r n o , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i n f o _ t e s o r i e r e , 
 
   	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ f l a g _ c o p e r t u r a , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ n u m _ o r d _ c o l l e g , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p r o g r _ o r d _ c o l l e g , 
 
 	 	 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ a n n o _ o r d _ c o l l e g , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d e _ o p e r a t o r e ,   - -   1 5 . 0 1 . 2 0 1 8   S o f i a   S I A C - 5 7 6 5 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ d e s c r i _ e s t e s a _ c a p , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s i o p e _ c o d i c e _ c g e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ s i o p e _ d e s c r i _ c g e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i p a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ i s t a t , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ e n t e _ t r a m i t e _ b t , 
 
 	         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ r i f e r i m e n t o _ e n t e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ i m p o r t o _ b e n e f , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g a m _ p o s t a l i z z a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t i p o _ d e b i t o _ n c , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c i g , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ m o t i v o _ n o c i g , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ m i s s i o n e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ p r o g r a m m a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ e c o n o m i c o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ i m p o r t o _ e c o n o m i c o , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ t r a n s a z _ u e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ r i c o r r e n t e _ s p e s a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o f o g _ c o d i c e , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c l a s s _ c o f o g _ i m p o r t o , 
 
 	         m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ d i s t i n t a , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ c o d i c e _ a t t o _ c o n t a b i l e , 
 
                 - -   1 6 . 0 9 . 2 0 1 9   S o f i a   S I A C - 6 8 4 0 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g o p a _ c o d f i s c , 
 
                 m i f F l u s s o O r d i n a t i v o R e c . m i f _ o r d _ p a g o p a _ n u m _ a v v i s o , 
 
                 n o w ( ) , 
 
                 e n t e P r o p r i e t a r i o I d , 
 
                 l o g i n O p e r a z i o n e 
 
       ) 
 
       r e t u r n i n g   m i f _ o r d _ i d   i n t o   m i f O r d S p e s a I d ; 
 
 
 
 
 
 
 
 
 
   - -   d a t i   f a t t u r e   d a   v a l o r i z z a r e   s e   o r d i n a t i v o   c o m m e r c i a l e 
 
   - -   @ @ @ @   s i c u r a m e n t e   d a   c o m p l e t a r e 
 
   - -   < f a t t u r a _ s i o p e > 
 
   i f   i s G e s t i o n e F a t t u r e   =   t r u e   a n d   i s O r d C o m m e r c i a l e = t r u e   t h e n 
 
     f l u s s o E l a b M i f E l a b R e c : = n u l l ; 
 
     m i f C o u n t R e c : = F L U S S O _ M I F _ E L A B _ F A T T U R E ; 
 
     t i t o l o C a p : = n u l l ; 
 
     f l u s s o E l a b M i f E l a b R e c : = m i f F l u s s o E l a b M i f A r r [ m i f C o u n t R e c ] ; 
 
     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . G e s t i o n e   f a t t u r e . L e t t u r a   n a t u r a   s p e s a . ' ; 
 
 
 
     / * i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ t i t o l o _ c o d e = t i t o l o C o r r e n t e   t h e n 
 
 	     	 t i t o l o C a p : = d e s c r i T i t o l o C o r r e n t e ; 
 
     e l s e 
 
       i f   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ t i t o l o _ c o d e = t i t o l o C a p i t a l e   t h e n 
 
           	 t i t o l o C a p : = d e s c r i T i t o l o C a p i t a l e ; 
 
       e n d   i f ; 
 
     e n d   i f ; * / 
 
     - -   2 0 . 0 2 . 2 0 1 8   S o f i a   J I R A   s i a c - 5 8 4 9 
 
     s e l e c t   o i l . o i l _ n a t u r a _ s p e s a _ d e s c   i n t o   t i t o l o C a p 
 
     f r o m   s i a c _ d _ o i l _ n a t u r a _ s p e s a   o i l ,   s i a c _ r _ o i l _ n a t u r a _ s p e s a _ t i t o l o   r 
 
     w h e r e   r . o i l _ n a t u r a _ s p e s a _ t i t o l o _ i d = m i f O r d i n a t i v o I d R e c . m i f _ o r d _ t i t o l o _ i d 
 
     a n d       o i l . o i l _ n a t u r a _ s p e s a _ i d = r . o i l _ n a t u r a _ s p e s a _ i d 
 
     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
     i f   t i t o l o C a p   i s   n u l l   t h e n   t i t o l o C a p : = d e f N a t u r a P a g ;   e n d   i f ; 
 
       - -   2 6 . 0 2 . 2 0 1 8   S o f i a   J I R A   s i a c - 5 8 4 9   -   i n c l u s i o n e   d e l l e   n o t e   c r e d i t o     p e r   o r d i n a t i v i   d i   p a g a m e n t o 
 
     t i t o l o C a p : = t i t o l o C a p | | ' | N ' ;   - -   0 8 . 0 5 . 2 0 1 8   S o f i a   s i a c - 6 1 3 7 
 
     s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   L e t t u r a   d a t i   c o n f i g u r a z i o n e   p e r   c a m p o   ' | | f l u s s o E l a b M i f E l a b R e c . f l u s s o _ e l a b _ m i f _ c a m p o 
 
                                               | | '   m i f C o u n t R e c = ' | | m i f C o u n t R e c 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . G e s t i o n e   f a t t u r e . I n i z i o   c i c l o . ' ; 
 
     o r d R e c : = n u l l ; 
 
     f o r   o r d R e c   i n 
 
     ( s e l e c t   *   f r o m   f n c _ m i f _ o r d i n a t i v o _ d o c u m e n t i _ s p l u s (   m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
 	 	 	 	 	 	 	 	 	 	 	                   n u m e r o D o c s : : i n t e g e r , 
 
                                                                                                           t i p o D o c s , 
 
                                                                                                           d o c A n a l o g i c o , 
 
                                                                                                           a t t r C o d e D a t a S c a d , 
 
                                                                                                           t i t o l o C a p , 
 
                                                                                                           e n t e O i l R e c . e n t e _ o i l _ c o d i c e _ p c c _ u f f , 
 
 	 	       	 	                                                 	                   e n t e P r o p r i e t a r i o I d , 
 
 	                         	 	                                                           d a t a E l a b o r a z i o n e , d a t a F i n e V a l ) 
 
     ) 
 
     l o o p 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   I n s e r i m e n t o   f a t t u r e   ' 
 
                                               | | '   i n   m i f _ t _ o r d i n a t i v o _ s p e s a _ d o c u m e n t i   ' 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
                   i n s e r t   i n t o     m i f _ t _ o r d i n a t i v o _ s p e s a _ d o c u m e n t i 
 
                   (   m i f _ o r d _ i d , 
 
 	 	       m i f _ o r d _ d o c u m e n t o , 
 
                       m i f _ o r d _ d o c _ c o d i c e _ i p a _ e n t e , 
 
 	               m i f _ o r d _ d o c _ t i p o , 
 
                       m i f _ o r d _ d o c _ t i p o _ a , 
 
 	 	       m i f _ o r d _ d o c _ i d _ l o t t o _ s d i , 
 
 	 	       m i f _ o r d _ d o c _ t i p o _ a n a l o g , 
 
 	 	       m i f _ o r d _ d o c _ c o d f i s c _ e m i s , 
 
 	 	       m i f _ o r d _ d o c _ a n n o , 
 
 	               m i f _ o r d _ d o c _ n u m e r o , 
 
 	               m i f _ o r d _ d o c _ i m p o r t o , 
 
 	               m i f _ o r d _ d o c _ d a t a _ s c a d e n z a , 
 
 	               m i f _ o r d _ d o c _ m o t i v o _ s c a d e n z a , 
 
 	               m i f _ o r d _ d o c _ n a t u r a _ s p e s a , 
 
 	 	       v a l i d i t a _ i n i z i o , 
 
 	 	       e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	       l o g i n _ o p e r a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( m i f O r d S p e s a I d , 
 
                     - - o r d R e c . n u m e r o _ f a t t u r a _ s i o p e , 
 
                     ' S ' ,   - -   0 7 . 0 6 . 2 0 1 8   S o f i a   S I A C - 6 2 2 8 
 
 	 	     o r d R e c . c o d i c e _ i p a _ e n t e _ s i o p e , 
 
 	 	     o r d R e c . t i p o _ d o c u m e n t o _ s i o p e , 
 
                     o r d R e c . t i p o _ d o c u m e n t o _ s i o p e _ a , 
 
                     o r d R e c . i d e n t i f i c a t i v o _ l o t t o _ s d i _ s i o p e , 
 
                     o r d R e c . t i p o _ d o c u m e n t o _ a n a l o g i c o _ s i o p e , 
 
                     t r i m   (   b o t h   '   '   f r o m   o r d R e c . c o d i c e _ f i s c a l e _ e m i t t e n t e _ s i o p e ) , 
 
 	 	     o r d R e c . a n n o _ e m i s s i o n e _ f a t t u r a _ s i o p e , 
 
 	 	     o r d R e c . n u m e r o _ f a t t u r a _ s i o p e , 
 
                     o r d R e c . i m p o r t o _ s i o p e , 
 
 	 	     o r d R e c . d a t a _ s c a d e n z a _ p a g a m _ s i o p e , 
 
 	 	     o r d R e c . m o t i v o _ s c a d e n z a _ s i o p e , 
 
         	     o r d R e c . n a t u r a _ s p e s a _ s i o p e , 
 
                     n o w ( ) , 
 
                     e n t e P r o p r i e t a r i o I d , 
 
                     l o g i n O p e r a z i o n e 
 
                   ) ; 
 
     e n d   l o o p ; 
 
   e n d   i f ; 
 
 
 
 
 
 
 
 
 
       - -   < r i t e n u t a > 
 
       - -   < i m p o r t o _ r i t e n u t a > 
 
       - -   < n u m e r o _ r e v e r s a l e > 
 
       - -   < p r o g r e s s i v o _ r e v e r s a l e > 
 
 
 
       i f     i s R i t e n u t a A t t i v o = t r u e   t h e n 
 
         r i t e n u t a R e c : = n u l l ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   G e s t i o n e     r i t e n u t e ' 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         f o r   r i t e n u t a R e c   i n 
 
         ( s e l e c t   * 
 
           f r o m   f n c _ m i f _ o r d i n a t i v o _ r i t e n u t e ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
                   	   	 	 	 	 	             t i p o R e l a z R i t O r d , t i p o R e l a z S u b O r d , t i p o R e l a z S p r O r d , 
 
                                                                             t i p o O n e r e I r p e f I d , t i p o O n e r e I n p s I d , 
 
                                                                             t i p o O n e r e I r p e g I d , 
 
 	 	 	 	 	 	 	 	 	     o r d S t a t o C o d e A I d , o r d D e t T s T i p o I d , 
 
                                                                             f l u s s o E l a b M i f T i p o D e c , 
 
         	                                                             e n t e P r o p r i e t a r i o I d , d a t a E l a b o r a z i o n e , d a t a F i n e V a l ) 
 
         ) 
 
         l o o p 
 
                 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   I n s e r i m e n t o   r i t e n u t a ' 
 
                                               | | '   i n   m i f _ t _ o r d i n a t i v o _ s p e s a _ r i t e n u t e   ' 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       	 	 i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ r i t e n u t e 
 
                 ( m i f _ o r d _ i d , 
 
     	 	   m i f _ o r d _ r i t _ t i p o , 
 
   	 	   m i f _ o r d _ r i t _ i m p o r t o , 
 
   	 	   m i f _ o r d _ r i t _ n u m e r o , 
 
     	 	   m i f _ o r d _ r i t _ o r d _ i d , 
 
   	 	   m i f _ o r d _ r i t _ p r o g r _ r e v , 
 
     	 	   v a l i d i t a _ i n i z i o , 
 
 	 	   e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	   l o g i n _ o p e r a z i o n e ) 
 
                 v a l u e s 
 
                 ( m i f O r d S p e s a I d , 
 
                   t i p o R i t e n u t a , 
 
                   r i t e n u t a R e c . i m p o r t o R i t e n u t a , 
 
                   r i t e n u t a R e c . n u m e r o R i t e n u t a , 
 
                   r i t e n u t a R e c . o r d R i t e n u t a I d , 
 
                   p r o g r R i t e n u t a , 
 
                   n o w ( ) , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e 
 
                 ) ; 
 
 
 
         e n d   l o o p ; 
 
       e n d   i f ; 
 
 
 
       - -   < s o s p e s o > 
 
       - -   < n u m e r o _ p r o v v i s o r i o > 
 
       - -   < i m p o r t o _ p r o v v i s o r i o > 
 
     i f     i s R i c e v u t a A t t i v o = t r u e   t h e n 
 
         r i c e v u t a R e c : = n u l l ; 
 
         s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   G e s t i o n e     p r o v v i s o r i ' 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
         f o r   r i c e v u t a R e c   i n 
 
         ( s e l e c t   * 
 
           f r o m   f n c _ m i f _ o r d i n a t i v o _ r i c e v u t e ( m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d , 
 
                                                                             f l u s s o E l a b M i f T i p o D e c , 
 
         	                                                             e n t e P r o p r i e t a r i o I d , d a t a E l a b o r a z i o n e , d a t a F i n e V a l ) 
 
         ) 
 
         l o o p 
 
         	 s t r M e s s a g g i o : = ' L e t t u r a   d a t i   o r d i n a t i v o   n u m e r o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ n u m e r o 
 
                                               | | '   a n n o B i l a n c i o = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ a n n o _ b i l 
 
                                               | | '   o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ o r d _ i d 
 
                                               | | '   m i f _ o r d _ i d = ' | | m i f O r d i n a t i v o I d R e c . m i f _ o r d _ i d 
 
                                               | | ' .   I n s e r i m e n t o       r i c e v u t a ' 
 
                                               | | '   i n   m i f _ t _ o r d i n a t i v o _ s p e s a _ r i c e v u t e   ' 
 
                                               | | '   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       	 	 i n s e r t   i n t o   m i f _ t _ o r d i n a t i v o _ s p e s a _ r i c e v u t e 
 
                 ( m i f _ o r d _ i d , 
 
 	           m i f _ o r d _ r i c _ a n n o , 
 
 	           m i f _ o r d _ r i c _ n u m e r o , 
 
 	           m i f _ o r d _ p r o v c _ i d , 
 
 	 	   m i f _ o r d _ r i c _ i m p o r t o , 
 
 	           v a l i d i t a _ i n i z i o , 
 
 	 	   e n t e _ p r o p r i e t a r i o _ i d , 
 
 	           l o g i n _ o p e r a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( m i f O r d S p e s a I d , 
 
                   r i c e v u t a R e c . a n n o R i c e v u t a , 
 
                   r i c e v u t a R e c . n u m e r o R i c e v u t a , 
 
                   r i c e v u t a R e c . p r o v R i c e v u t a I d , 
 
                   r i c e v u t a R e c . i m p o r t o R i c e v u t a , 
 
                   n o w ( ) , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e 
 
                 ) ; 
 
         e n d   l o o p ; 
 
     e n d   i f ; 
 
 
 
     n u m e r o O r d i n a t i v i T r a s m : = n u m e r o O r d i n a t i v i T r a s m + 1 ; 
 
   e n d   l o o p ; 
 
 
 
 / *   i f   c o m P c c A t t r I d   i s   n o t   n u l l   a n d   n u m e r o O r d i n a t i v i T r a s m > 0   t h e n 
 
       	       s t r M e s s a g g i o : = ' I n s e r i m e n t o   R e g i s t r o   P C C . ' ; 
 
 	       i n s e r t   i n t o   s i a c _ t _ r e g i s t r o _ p c c 
 
 	       ( d o c _ i d , 
 
         	 s u b d o c _ i d , 
 
 	         p c c o p _ t i p o _ i d , 
 
         	 o r d i n a t i v o _ d a t a _ e m i s s i o n e , 
 
 	         o r d i n a t i v o _ n u m e r o , 
 
         	 r p c c _ q u i e t a n z a _ d a t a , 
 
                 r p c c _ q u i e t a n z a _ i m p o r t o , 
 
 	         s o g g e t t o _ i d , 
 
         	 v a l i d i t a _ i n i z i o , 
 
 	         e n t e _ p r o p r i e t a r i o _ i d , 
 
         	 l o g i n _ o p e r a z i o n e 
 
 	         ) 
 
         	 ( 
 
                   w i t h 
 
                   m i f   a s 
 
                   ( s e l e c t   m . m i f _ o r d _ o r d _ i d   o r d _ i d ,   m . m i f _ o r d _ s o g g e t t o _ i d   s o g g e t t o _ i d , 
 
                                   o r d . o r d _ e m i s s i o n e _ d a t a   ,   o r d . o r d _ n u m e r o 
 
                     f r o m   m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m ,   s i a c _ t _ o r d i n a t i v o   o r d 
 
                     w h e r e   m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s u b s t r i n g ( m . m i f _ o r d _ c o d i c e _ f u n z i o n e   f r o m   1   f o r   1 ) = F U N Z I O N E _ C O D E _ I 
 
                     a n d       o r d . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
                   ) , 
 
                   t i p o d o c   a s 
 
                   ( s e l e c t   t i p o . d o c _ t i p o _ i d 
 
                     f r o m   s i a c _ d _ d o c _ t i p o   t i p o   , s i a c _ r _ d o c _ t i p o _ a t t r   a t t r 
 
                     w h e r e   a t t r . a t t r _ i d = c o m P c c A t t r I d 
 
                     a n d       a t t r . b o o l e a n = ' S ' 
 
                     a n d       t i p o . d o c _ t i p o _ i d = a t t r . d o c _ t i p o _ i d 
 
                     a n d       a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       t i p o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       t i p o . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) , 
 
                   d o c   a s 
 
                   ( s e l e c t   d i s t i n c t   m . m i f _ o r d _ o r d _ i d   o r d _ i d ,   s u b d o c . d o c _ i d   ,   s u b d o c . s u b d o c _ i d ,   s u b d o c . s u b d o c _ i m p o r t o ,   d o c . d o c _ t i p o _ i d 
 
 	             f r o m     m i f _ t _ o r d i n a t i v o _ s p e s a _ i d   m ,   s i a c _ t _ o r d i n a t i v o _ t s   t s ,   s i a c _ r _ s u b d o c _ o r d i n a t i v o _ t s   r s u b d o c , 
 
                                 s i a c _ t _ s u b d o c   s u b d o c ,   s i a c _ t _ d o c   d o c 
 
                     w h e r e   m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s u b s t r i n g ( m . m i f _ o r d _ c o d i c e _ f u n z i o n e   f r o m   1   f o r   1 ) = F U N Z I O N E _ C O D E _ I 
 
                     a n d       t s . o r d _ i d = m . m i f _ o r d _ o r d _ i d 
 
                     a n d       r s u b d o c . o r d _ t s _ i d = t s . o r d _ t s _ i d 
 
                     a n d       s u b d o c . s u b d o c _ i d = r s u b d o c . s u b d o c _ i d 
 
                     a n d       d o c . d o c _ i d = s u b d o c . d o c _ i d 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       r s u b d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s u b d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       s u b d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       s u b d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                   ) 
 
                   s e l e c t 
 
                     d o c . d o c _ i d , 
 
                     d o c . s u b d o c _ i d , 
 
                     p c c O p e r a z T i p o I d , 
 
 - -                     m i f . o r d _ e m i s s i o n e _ d a t a , 
 
 - - 	 	     m i f . o r d _ e m i s s i o n e _ d a t a + ( 1 * i n t e r v a l   ' 1   d a y ' ) , 
 
 	 	     m i f . o r d _ e m i s s i o n e _ d a t a , 
 
                     m i f . o r d _ n u m e r o , 
 
                     d a t a E l a b o r a z i o n e , 
 
                     d o c . s u b d o c _ i m p o r t o , 
 
                     m i f . s o g g e t t o _ i d , 
 
                     n o w ( ) , 
 
                     e n t e P r o p r i e t a r i o I d , 
 
                     l o g i n O p e r a z i o n e 
 
                   f r o m   m i f ,   d o c , t i p o d o c 
 
                   w h e r e   m i f . o r d _ i d = d o c . o r d _ i d 
 
                   a n d       t i p o d o c . d o c _ t i p o _ i d = d o c . d o c _ t i p o _ i d 
 
                 ) ; 
 
       e n d   i f ; * / 
 
 
 
 
 
       s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ o u t _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       u p d a t e   s i a c _ t _ p r o g r e s s i v o   p   s e t   p r o g _ v a l u e = f l u s s o E l a b M i f O i l I d 
 
       w h e r e   p . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       p . p r o g _ k e y = ' o i l _ o u t _ ' | | a n n o B i l a n c i o 
 
       a n d       p . a m b i t o _ i d = a m b i t o F i n I d 
 
       a n d       p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
       s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   p r o g r e s s i v o   p e r   i d e n t i f i c a t i v o   f l u s s o   O I L   [ s i a c _ t _ p r o g r e s s i v o   p r o g _ k e y = o i l _ ' | | M A N D M I F _ T I P O | | ' _ ' | | a n n o B i l a n c i o | | '     p e r   f l u s s o   M I F   t i p o   ' | | M A N D M I F _ T I P O | | ' . ' ; 
 
       u p d a t e   s i a c _ t _ p r o g r e s s i v o   p   s e t   p r o g _ v a l u e = f l u s s o E l a b M i f D i s t O i l R e t I d 
 
       w h e r e   p . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       p . p r o g _ k e y = ' o i l _ ' | | M A N D M I F _ T I P O | | ' _ ' | | a n n o B i l a n c i o 
 
       a n d       p . a m b i t o _ i d = a m b i t o F i n I d 
 
       a n d       p . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
       s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   m i f _ t _ f l u s s o _ e l a b o r a t o . ' ; 
 
 
 
       u p d a t e     m i f _ t _ f l u s s o _ e l a b o r a t o 
 
       s e t   ( f l u s s o _ e l a b _ m i f _ i d _ f l u s s o _ o i l , f l u s s o _ e l a b _ m i f _ c o d i c e _ f l u s s o _ o i l , f l u s s o _ e l a b _ m i f _ n u m _ o r d _ e l a b , f l u s s o _ e l a b _ m i f _ f i l e _ n o m e , f l u s s o _ e l a b _ m i f _ e s i t o _ m s g ) = 
 
       	       ( f l u s s o E l a b M i f O i l I d , a n n o B i l a n c i o | | f l u s s o E l a b M i f D i s t O i l R e t I d : : v a r c h a r , n u m e r o O r d i n a t i v i T r a s m , f l u s s o E l a b M i f T i p o N o m e F i l e | | ' _ ' | | e n t e O i l R e c . e n t e _ o i l _ c o d i c e , 
 
                 ' E l a b o r a z i o n e   i n   c o r s o   t i p o   f l u s s o   ' | | M A N D M I F _ T I P O | | '   -   D a t i   i n s e r i t i   i n   m i f _ t _ o r d i n a t i v o _ s p e s a ' ) 
 
       w h e r e   f l u s s o _ e l a b _ m i f _ i d = f l u s s o E l a b M i f L o g I d ; 
 
 
 
         - -   g e s t i r e   a g g i o r n a m e n t o   m i f _ t _ f l u s s o _ e l a b o r a t o 
 
 
 
 	 R A I S E   N O T I C E   ' n u m e r o O r d i n a t i v i T r a s m   % ' ,   n u m e r o O r d i n a t i v i T r a s m ; 
 
         m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | '   T r a s m e s s i   ' | | n u m e r o O r d i n a t i v i T r a s m | | '   o r d i n a t i v i   d i   s p e s a . ' ; 
 
         m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
         f l u s s o E l a b M i f I d : = f l u s s o E l a b M i f L o g I d ; 
 
         n o m e F i l e M i f : = f l u s s o E l a b M i f T i p o N o m e F i l e | | ' _ ' | | e n t e O i l R e c . e n t e _ o i l _ c o d i c e ; 
 
 
 
 
 
         f l u s s o E l a b M i f D i s t O i l I d : = ( a n n o B i l a n c i o | | f l u s s o E l a b M i f D i s t O i l R e t I d : : v a r c h a r ) : : i n t e g e r ; 
 
         r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :     %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 ) , m i f C o u n t R e c ; 
 
                 i f   c o d R e s u l t = - 1 2   t h e n 
 
                     m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' ) | | '   ' | | m i f C o u n t R e c | | ' . '   ; 
 
                     c o d i c e R i s u l t a t o : = 0 ; 
 
                 e l s e 
 
                     m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E :     ' | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' ) | | '   ' | | m i f C o u n t R e c | | ' . '   ; 
 
               	     c o d i c e R i s u l t a t o : = - 1 ; 
 
         	 e n d   i f ; 
 
 
 
                 n u m e r o O r d i n a t i v i T r a s m : = 0 ; 
 
 	 	 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 i f   f l u s s o E l a b M i f L o g I d   i s   n o t   n u l l   t h e n 
 
                         f l u s s o E l a b M i f I d : = f l u s s o E l a b M i f L o g I d ; 
 
                 	 u p d a t e     m i f _ t _ f l u s s o _ e l a b o r a t o 
 
       	 	 	 s e t   ( f l u s s o _ e l a b _ m i f _ e s i t o , f l u s s o _ e l a b _ m i f _ e s i t o _ m s g ) = 
 
                                 ( ' K O ' , m e s s a g g i o R i s u l t a t o ) 
 
 	 	         w h e r e   f l u s s o _ e l a b _ m i f _ i d = f l u s s o E l a b M i f L o g I d ; 
 
                 e l s e 
 
                 	 f l u s s o E l a b M i f I d : = n u l l ; 
 
                 e n d   i f ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   N O _ D A T A _ F O U N D   T H E N 
 
                 r a i s e   n o t i c e   ' %   %   E R R O R E   :   %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , m i f C o u n t R e c ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   N e s s u n   d a t o   p r e s e n t e   i n   a r c h i v i o   ' | | '   ' | | m i f C o u n t R e c | | ' . ' ; 
 
                 n u m e r o O r d i n a t i v i T r a s m : = 0 ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 i f   f l u s s o E l a b M i f L o g I d   i s   n o t   n u l l   t h e n 
 
                         f l u s s o E l a b M i f I d : = f l u s s o E l a b M i f L o g I d ; 
 
                 	 u p d a t e     m i f _ t _ f l u s s o _ e l a b o r a t o 
 
       	 	 	 s e t   ( f l u s s o _ e l a b _ m i f _ e s i t o , f l u s s o _ e l a b _ m i f _ e s i t o _ m s g ) = 
 
                                 ( ' K O ' , m e s s a g g i o R i s u l t a t o ) 
 
 	 	         w h e r e   f l u s s o _ e l a b _ m i f _ i d = f l u s s o E l a b M i f L o g I d ; 
 
                 e l s e 
 
                 	 f l u s s o E l a b M i f I d : = n u l l ; 
 
                 e n d   i f ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                 r a i s e   n o t i c e   ' %   %   E R R O R E   :   %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , m i f C o u n t R e c ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o   ' | | '   ' | | m i f C o u n t R e c | | ' . ' ; 
 
                 n u m e r o O r d i n a t i v i T r a s m : = 0 ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 i f   f l u s s o E l a b M i f L o g I d   i s   n o t   n u l l   t h e n 
 
 
 
 
 
                         f l u s s o E l a b M i f I d : = f l u s s o E l a b M i f L o g I d ; 
 
                 	 u p d a t e     m i f _ t _ f l u s s o _ e l a b o r a t o 
 
       	 	 	 s e t   ( f l u s s o _ e l a b _ m i f _ e s i t o , f l u s s o _ e l a b _ m i f _ e s i t o _ m s g ) = 
 
                                 ( ' K O ' , m e s s a g g i o R i s u l t a t o ) 
 
 	 	         w h e r e   f l u s s o _ e l a b _ m i f _ i d = f l u s s o E l a b M i f L o g I d ; 
 
                 e l s e 
 
                 	 f l u s s o E l a b M i f I d : = n u l l ; 
 
                 e n d   i f ; 
 
                 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   1 0 0 ) , m i f C o u n t R e c ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   D B : ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) | | '   ' | | m i f C o u n t R e c | | ' . '   ; 
 
                 n u m e r o O r d i n a t i v i T r a s m : = 0 ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 i f   f l u s s o E l a b M i f L o g I d   i s   n o t   n u l l   t h e n 
 
                         f l u s s o E l a b M i f I d : = f l u s s o E l a b M i f L o g I d ; 
 
                 	 u p d a t e     m i f _ t _ f l u s s o _ e l a b o r a t o 
 
       	 	 	 s e t   ( f l u s s o _ e l a b _ m i f _ e s i t o , f l u s s o _ e l a b _ m i f _ e s i t o _ m s g ) = 
 
                                 ( ' K O ' , m e s s a g g i o R i s u l t a t o ) 
 
 	 	         w h e r e   f l u s s o _ e l a b _ m i f _ i d = f l u s s o E l a b M i f L o g I d ; 
 
 
 
                 e l s e 
 
                 	 f l u s s o E l a b M i f I d : = n u l l ; 
 
                 e n d   i f ; 
 
 
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