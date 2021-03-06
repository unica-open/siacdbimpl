/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/*soggetto_tipo_fonte_durc CHAR(1),
soggetto_fine_validita_durc DATE,
soggetto_fonte_durc_manuale_classif_id INTEGER,
soggetto_fonte_durc_automatica TEXT,
soggetto_note_durc TEXT,*/

-- 05.12.2018 Sofia SIAC-6261
alter table  siac_dwh_soggetto
  add soggetto_tipo_fonte_durc varchar(1),
  add soggetto_fonte_durc_automatica varchar(500),
  add soggetto_note_durc varchar(500),
  add soggetto_fine_validita_durc TIMESTAMP WITHOUT TIME ZONE,
  add soggetto_fonte_durc_manuale_code varchar(200),
  add soggetto_fonte_durc_manuale_desc varchar(500); r c   v a r c h a r ( 1 ) , 
 
     a d d   s o g g e t t o _ f o n t e _ d u r c _ a u t o m a t i c a   v a r c h a r ( 5 0 0 ) , 
 
     a d d   s o g g e t t o _ n o t e _ d u r c   v a r c h a r ( 5 0 0 ) , 
 
     a d d   s o g g e t t o _ f i n e _ v a l i d i t a _ d u r c   T I M E S T A M P   W I T H O U T   T I M E   Z O N E , 
 
     a d d   s o g g e t t o _ f o n t e _ d u r c _ m a n u a l e _ c o d e   v a r c h a r ( 2 0 0 ) , 
 
     a d d   s o g g e t t o _ f o n t e _ d u r c _ m a n u a l e _ d e s c   v a r c h a r ( 5 0 0 ) ; 