/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* INSERIMENTO DELLE CAUSALI SE NON ESISTENTI */

insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'CHI ATT', 'Chiusura Patrimoniale Attivo', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='CHI ATT' 
      and z.ente_proprietario_id=a.ente_proprietario_id );


insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'CHI PASS', 'Chiusura Patrimoniale Passivo', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='CHI PASS' 
      and z.ente_proprietario_id=a.ente_proprietario_id );  
	  

insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'CHI CE', 'Chiusura Costi', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='CHI CE' 
      and z.ente_proprietario_id=a.ente_proprietario_id );  


insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'CHI RE', 'Chiusura Ricavi', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='CHI RE' 
      and z.ente_proprietario_id=a.ente_proprietario_id );      



insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'APE ATT', 'Apertura Patrimoniale Attivo', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='APE ATT' 
      and z.ente_proprietario_id=a.ente_proprietario_id );        
     


insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'APE PASS', 'Apertura Patrimoniale Passivo', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='APE PASS' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 
      
      
insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'REE', 'Risultato economico esercizio', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='REE' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 
	  
insert into siac_t_causale_ep (
  causale_ep_code,
  causale_ep_desc ,
  causale_ep_tipo_id,
  validita_inizio ,
  validita_fine ,
  ente_proprietario_id ,
  data_creazione ,
  data_modifica ,
  data_cancellazione ,
  login_operazione ,
  login_creazione ,
  login_modifica ,
  login_cancellazione,
  causale_ep_default ,
  ambito_id)
select 'SRI', 'Storno Risconti', b.causale_ep_tipo_id,
CURRENT_DATE, NULL, a.ente_proprietario_id, now(), now(), NULL,
'admin', 'admin', 'admin', NULL, false, c.ambito_id
from siac_t_ente_proprietario a,
	siac_d_causale_ep_tipo b,siac_d_ambito c
where a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=c.ente_proprietario_id
and b.causale_ep_tipo_code='LIB'
and c.ambito_code='AMBITO_FIN'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from siac_t_causale_ep z 
      where z.causale_ep_code='SRI' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 	  

/*   

*/

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 
 'DETSALDI',
  'DETERMINAZIONE SALDI CONTI ECONOMICO PATRIMONIALI',
  null,
  NULL,
  1,
  '2016-01-01',
  'admin',
  ente_proprietario_id
from siac_t_ente_proprietario a 
where a.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='DETSALDI' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 


insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'CHIPP',
  'CHIUSURA PASSIVITA'' PATRIMONIALI E CONTI ORDINE PASSIVI',
  c.causale_ep_id, -- CHI 943379
  b.pdce_conto_id, -- 2331711
  2,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.02.01.01'
and c.causale_ep_code='CHI PASS'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='CHIPP' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 
	  

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'CHIAP',
  'CHIUSURA ATTIVITA'' PATRIMONIALI E CONTI ORDINE ATTIVI',
  c.causale_ep_id, 
  b.pdce_conto_id, 
  3,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.02.01.01'
and c.causale_ep_code='CHI ATT'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='CHIAP' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 
	  
	  
insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'EPCE',
  'EPILOGO COSTI',
  c.causale_ep_id, 
  b.pdce_conto_id, 
  4,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.03.01.01'
and c.causale_ep_code='CHI CE'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='EPCE' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 
	  
insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'EPRE',
  'EPILOGO RICAVI',
  c.causale_ep_id,
  b.pdce_conto_id,
  5,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.03.01.01'
and c.causale_ep_code='CHI RE'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='EPRE' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 


 insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'DETREE',
  'DETERMINAZIONE RISULTATO ECONOMICO D''ESERCIZIO',
  c.causale_ep_id,
  b.pdce_conto_id,
  6,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.03.01.01'
and c.causale_ep_code='REE'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='DETREE' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 	
	  

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'APEPP',
  'APERTURA PASSIVITA'' PATRIMONIALI E CONTI ORDINE PASSIVI',
  c.causale_ep_id,
  b.pdce_conto_id,
  7,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.01.01.01'
and c.causale_ep_code='APE PASS'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='APEPP' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 	
	  
insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'APEAP',
  'APERTURA ATTIVITA'' PATRIMONIALI E CONTI ORDINE ATTIVI',
  c.causale_ep_id,
  b.pdce_conto_id,
  8,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, siac_t_pdce_conto b, siac_t_causale_ep c
where a.ente_proprietario_id=b.ente_proprietario_id
and b.ente_proprietario_id=c.ente_proprietario_id
and b.pdce_conto_code='8.01.01.01'
and c.causale_ep_code='APE ATT'
and a.data_cancellazione IS NULL
and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='APEAP' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 		  
	  

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'STRISC',
  'STORNO RISCONTI',
  c.causale_ep_id,
  null,--b.pdce_conto_id,
  9,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a, --siac_t_pdce_conto b, 
	siac_t_causale_ep c
where a.ente_proprietario_id=c.ente_proprietario_id
--and b.ente_proprietario_id=c.ente_proprietario_id
--and b.pdce_conto_code='8.01.01.01'
and c.causale_ep_code='SRI'
and a.data_cancellazione IS NULL
--and b.data_cancellazione IS NULL
and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='STRISC' 
      and z.ente_proprietario_id=a.ente_proprietario_id );  
	 
	 

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select 'CONTABIL',
  'CONTABILIZZAZIONE',
  null,--c.causale_ep_id,
  null,--b.pdce_conto_id,
  10,
  '2016-01-01',
  'admin',
  a.ente_proprietario_id
from siac_t_ente_proprietario a--, --siac_t_pdce_conto b, 
	--siac_t_causale_ep c
where--a.ente_proprietario_id=c.ente_proprietario_id
--and b.ente_proprietario_id=c.ente_proprietario_id
--and b.pdce_conto_code='8.01.01.01'
--and c.causale_ep_code='SRI'
 a.data_cancellazione IS NULL
--and b.data_cancellazione IS NULL
--and c.data_cancellazione IS NULL
and not exists (select 1 
      from fase_gen_d_elaborazione_fineanno_tipo z 
      where z.fase_gen_elab_tipo_code='CONTABIL' 
      and z.ente_proprietario_id=a.ente_proprietario_id ); 