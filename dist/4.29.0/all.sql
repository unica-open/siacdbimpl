/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select fnc_siac_bko_inserisci_azione('OP-BKOF015-eliminaSoggettoCollegatoImpegno', 'Impegni - Backoffice elimina soggetto', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	
select fnc_siac_bko_inserisci_azione('OP-BKOF016-aggiornaImpegnoConBloccoRagioneria', 'Impegni - Backoffice aggiorna impegno con blocco ragioneria', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	
-- 7842 / 7844 fine

-- SIAC-7903 -  Sofia 02.12.2020 Inizio
update siac_d_siope_assenza_motivazione d
set    siope_assenza_motivazione_desc='cig da specificare in fase di liquidazione',
       data_modifica=now(),
       login_operazione=d.login_operazione||'-SIAC-7903'
where d.ente_proprietario_id in (2,3,4,5,10,14,16)
and   d.siope_assenza_motivazione_code='CL'
and   d.siope_assenza_motivazione_desc='Cig da definire in fase di liquidazione'
and   d.data_cancellazione is null;
-- SIAC-7903 -  Sofia 02.12.2020 Fine

--SIAC-7865 - Maurizio - INIZIO

--aggiorno la posizione dei report successivi a BILR062
update siac_t_report a
set data_modifica=now(),
	login_operazione = login_operazione|| ' - SIAC-7865',
    rep_ordina_elenco_variab=rep_ordina_elenco_variab + 2
where a.rep_ordina_elenco_variab > (SELECT t_rep.rep_ordina_elenco_variab
  					from siac_t_report t_rep
                    where t_rep.ente_proprietario_id=a.ente_proprietario_id
                    	and t_rep.rep_codice='BILR062')
	and  login_operazione not like '%SIAC-7865';                       
								
--inserisco i 2 report nuovi (il BILR111 non ha variabili e non lo inserisco).
insert into siac_t_report(
rep_codice,  rep_desc,  rep_birt_codice,
  validita_inizio, ente_proprietario_id,  data_creazione,
  data_modifica,  login_operazione,  rep_ordina_elenco_variab)
select 'BILR110', 'Rendiconto - Allegato 9 - Entrate: Riepilogo per Titolo - Tipologia (BILR110)',
  'BILR110_Allegato_9_bilancio_di_gestione_entrate',
  now(), ente.ente_proprietario_id, now(),
  now(), 'SIAC-7865', (select t_rep.rep_ordina_elenco_variab+1
  					from siac_t_report t_rep
                    where t_rep.ente_proprietario_id=ente.ente_proprietario_id
                    	and t_rep.rep_codice='BILR062')
from siac_t_ente_proprietario ente  
where ente.data_cancellazione IS NULL
	and not exists (select 1
    				from siac_t_report a
                    where a.ente_proprietario_id=ente.ente_proprietario_id
                    	and a.rep_codice='BILR110'
                        and a.data_cancellazione IS NULL);
	 
insert into siac_t_report(
rep_codice,  rep_desc,  rep_birt_codice,
  validita_inizio, ente_proprietario_id,  data_creazione,
  data_modifica,  login_operazione,  rep_ordina_elenco_variab)
select 'BILR112', 'Rendiconto - Allegato 9 - Quadro Generale Riassuntivo (BILR112)',
  'BILR112_Allegato_9_bill_gest_quadr_riass_gen',
  now(), ente.ente_proprietario_id, now(),
  now(), 'SIAC-7865', (select t_rep.rep_ordina_elenco_variab + 2
  					from siac_t_report t_rep
                    where t_rep.ente_proprietario_id=ente.ente_proprietario_id
                    	and t_rep.rep_codice='BILR062')
from siac_t_ente_proprietario ente  
where ente.data_cancellazione IS NULL
	and not exists (select 1
    				from siac_t_report a
                    where a.ente_proprietario_id=ente.ente_proprietario_id
                    	and a.rep_codice='BILR112'
                        and a.data_cancellazione IS NULL);                 
    
	--VARIABILI PER REPORT BILR110      
   -- 3 anni 
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ava_amm_rend',
        'Entrate - Avanzo di Amministrazione - di cui avanzo utilizzato anticipatamente',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ava_amm_rend');	
                           
      
      
--1 anno
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ava_amm_prec_rend', 
'Entrate - Avanzo di amministrazione anno precedente - di cui Utilizzo Fondo anticipazioni di liquidità',
        0,
        'N',
        2,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ava_amm_prec_rend');	
      
-- 1 anno
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ant_liq_prec_rend',
        'Entrate - Avanzo di amministrazione anno precedente - di cui Utilizzo Fondo anticipazioni di liquidità',
        0,
        'N',
        3,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_prec_rend');	
            
--3 anni
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ant_liq_rend',
        'Entrate - Utilizzo avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita''',
        0,
        'N',
        4, --deve essere 4 perche' e' presente nel BILR048, BILR052, BILR062
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_rend');	
            
--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR110'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ava_amm_prec_rend')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR110'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
      
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR110'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
2 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ava_amm_rend')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR110'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
      

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR110'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
3 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ant_liq_prec_rend')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR110'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
            

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR110'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
4 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ant_liq_rend')
and c.anno='2020'
and a.data_cancellazione IS NULL
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR110'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
      
	  --VARIABILI PER REPORT BILR112
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR112'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ant_liq_rend')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR112'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));

				

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_fondo_ant_liq_spese_rend',
        'Spese - Rimborso Prestiti - di cui Fondo anticipazioni di liquidita''',
        0,
        'N',
        1, 
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fondo_ant_liq_spese_rend');	
      


INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR112'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
2 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_fondo_ant_liq_spese_rend')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR112'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
				
		--VARIABILI PER REPORT BILR217
update siac_t_report_importi
set data_modifica=now(),
	login_operazione=login_operazione||' - SIAC-7865',
    repimp_desc='10) Rimborso prestiti - di cui Fondo anticipazioni di liquidita'''
where repimp_id in(
select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.ente_proprietario_id=2
and c.repimp_codice='di_cui_ant_liq_assest'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and c.login_operazione not like '%SIAC-7865');			
				
				
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_incr_att_fin_inscr_ent_assest',
        '18) Fondo pluriennale vincolato per incremento di attivita'' finanziarie iscritto in entrata',
        0,
        'N',
        24, 
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7865'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_incr_att_fin_inscr_ent_assest');	
      
update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='19) Fondo pluriennale vincolato per spese correnti iscritto in entrata al netto delle componenti non vincolate derivanti dal riaccertamento ord.'
where repimp_codice='s_fpv_sc_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );


update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='20) Entrate titoli 1-2-3 non sanitarie con specifico vincolo di destinazione'
where repimp_codice='s_entrate_tit123_vinc_dest_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );

update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='21) Entrate titoli 1-2-3 destinate al finanziamento del SSN'
where repimp_codice='s_entrate_tit123_ssn_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );


update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='22) Spese correnti non sanitarie finanziate da entrate con specifico vincolo di destinazione'
where repimp_codice='s_spese_vinc_dest_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );


update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='23) Fondo pluriennale vincolato di parte corrente (di spesa) al netto delle componenti non vincolate derivanti dal riaccertamento ord.'
where repimp_codice='s_fpv_pc_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );


update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='24) Spese correnti finanziate da entrate destinate al SSN'
where repimp_codice='s_sc_ssn_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );

update siac_r_report_importi r_rep
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    posizione_stampa = (select left(c.repimp_desc,2)::integer
                        from siac_t_report a,
                        siac_r_report_importi b,
                        siac_t_report_importi c,
                        siac_t_bil d,
                        siac_t_periodo e
                    where a.rep_id=b.rep_id
                    and b.repimp_id=c.repimp_id
                    and c.bil_id=d.bil_id
                    and d.periodo_id=e.periodo_id
                    and b.reprimp_id= r_rep.reprimp_id
                    and a.rep_codice='BILR217'
                    and e.anno='2020'
                    and b.data_cancellazione is null 
                    and c.data_cancellazione is null)
where reprimp_id in(select b.reprimp_id
    from siac_t_report a,
    siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and b.reprimp_id= r_rep.reprimp_id
and a.rep_codice='BILR217'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and b.login_operazione not like '%SIAC-7865') ;


INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR217'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
18 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('fpv_incr_att_fin_inscr_ent_assest')
and c.anno='2020'
and a.ente_proprietario_id in (2,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR217'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));	


	--Report BILR219.
update SIAC_T_REPORT_IMPORTI 
set data_modifica = now(),
	login_operazione = login_operazione||' - SIAC-7865',
    repimp_desc='07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidita'''
where repimp_codice='F_di_cui_fondo_assest'
	and repimp_id in (select c.repimp_id
from siac_t_report a,
	siac_r_report_importi b,
    siac_t_report_importi c,
    siac_t_bil d,
    siac_t_periodo e
where a.rep_id=b.rep_id
and b.repimp_id=c.repimp_id
and c.bil_id=d.bil_id
and d.periodo_id=e.periodo_id
and a.rep_codice='BILR219'
and e.anno='2020'
and b.data_cancellazione is null 
and c.data_cancellazione is null
and c.login_operazione not like '%SIAC-7865' );	


--SIAC-7865 - Maurizio - FINE


--SIAC-7877 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR217_equilibri_bilancio_regione_assest_entrate"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR217_equilibri_bilancio_regione_assest_spese"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
h_count integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
x_array VARCHAR [];
id_bil integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

--14/12/2020 Funzione rivista per ottimizzare le prestazioni insieme alle modifiche 
--  per la SIAC-7877.
 
--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select fnc_siac_random_user()
into	user_table;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

display_error:='';

--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
strQuery:= '
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importi.anno	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno				in 	('''||annoCapImp||''','''||annoCapImp1||''','''||annoCapImp2||''')									
        and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id,
                    anno_importi.anno';                    

	raise notice 'Query variazioni entrate = %', strQuery;
    execute  strQuery;
end if;

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	cl.classif_id categoria_id,
                p_anno anno_bilancio,
                e.*
		from 	siac_r_bil_elem_class rc, 
            siac_t_bil_elem e, 
            siac_d_class_tipo ct,
            siac_t_class cl,
            siac_d_bil_elem_tipo tipo_elemento,          
            siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
            siac_d_bil_elem_categoria cat_del_capitolo,
            siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id=cl.classif_tipo_id
        and cl.classif_id=rc.classif_id 
        and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
        and e.elem_id=rc.elem_id        
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and e.ente_proprietario_id=p_ente_prop_id
        and e.bil_id= id_bil
        and ct.classif_tipo_code='CATEGORIA'
        and tipo_elemento.elem_tipo_code = elemTipoCode
        and	stato_capitolo.elem_stato_code	=	'VA'
        and	cat_del_capitolo.elem_cat_code	=	'STD'
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
        and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
        and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
        and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())),
   pdc_capitolo as (
      select r_capitolo_pdc.elem_id,
           pdc.classif_code pdc_code
      from siac_r_bil_elem_class r_capitolo_pdc,
           siac_t_class pdc,
           siac_d_class_tipo pdc_tipo
      where r_capitolo_pdc.classif_id = pdc.classif_id and
           pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
           r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
           pdc_tipo.classif_tipo_code like 'PDC_%'		and
           r_capitolo_pdc.data_cancellazione 			is null and 	
           pdc.data_cancellazione is null 	and
           pdc_tipo.data_cancellazione 	is null), 
   imp_comp_anno as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
     imp_comp_anno1 as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp1
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
	imp_comp_anno2 as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp2
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
    variaz_stanz_anno as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
        group by a.elem_id),
    variaz_stanz_anno1 as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
        group by a.elem_id),
    variaz_stanz_anno2 as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
        group by a.elem_id)                
select capitoli.anno_bilancio::varchar bil_anno,
		''::varchar titoloe_tipo_code,
		strut_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
        strut_bilancio.titolo_code::varchar titoloe_code,
        strut_bilancio.titolo_desc::varchar titoloe_desc,
        ''::varchar tipologia_tipo_code,
        strut_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
        strut_bilancio.tipologia_code::varchar tipologia_code,
        strut_bilancio.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        strut_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
        strut_bilancio.categoria_code::varchar categoria_code,
        strut_bilancio.categoria_desc::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
  --14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
        (COALESCE(imp_comp_anno.importo,0) +
         COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric stanziamento_prev_anno,
        (COALESCE(imp_comp_anno1.importo,0) +
         COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric stanziamento_prev_anno1,
        (COALESCE(imp_comp_anno2.importo,0) +
    	 COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric stanziamento_prev_anno2,
        pdc_capitolo.pdc_code::varchar codice_pdc,
        ''::varchar display_error
from strut_bilancio
	LEFT JOIN capitoli on capitoli.categoria_id = strut_bilancio.categoria_id  
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id  
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN variaz_stanz_anno on capitoli.elem_id = variaz_stanz_anno.elem_id
    LEFT JOIN variaz_stanz_anno1 on capitoli.elem_id = variaz_stanz_anno1.elem_id
    LEFT JOIN variaz_stanz_anno2 on capitoli.elem_id = variaz_stanz_anno2.elem_id;                               
            
delete from siac_rep_var_entrate where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;     
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  pdc varchar,
  display_error varchar
) AS
$body$
DECLARE

capitoloRec record;
capitoloImportiRec record;
classifBilRec record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
user_table	varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;
strQuery varchar;
strApp varchar;
intApp numeric;
x_array VARCHAR [];

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI';	 -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
pdc='';
 
--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

select fnc_siac_random_user()
into	user_table;

display_error:='';

--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importi.anno	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno				in 	('''||annoCapImp||''','''||annoCapImp1||''','''||annoCapImp2||''')									
        and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id,
                    anno_importi.anno';                    

	raise notice 'Query variazioni spesa = %', strQuery;
    execute  strQuery;
end if;
    
return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*
		from 
     		siac_d_class_tipo programma_tipo,
     		siac_t_class programma,
     		siac_d_class_tipo macroaggr_tipo,
     		siac_t_class macroaggr,
	 		siac_t_bil_elem capitolo,
	 		siac_d_bil_elem_tipo tipo_elemento,
     		siac_r_bil_elem_class r_capitolo_programma,
     		siac_r_bil_elem_class r_capitolo_macroaggr,
     		siac_d_bil_elem_stato stato_capitolo, 
     		siac_r_bil_elem_stato r_capitolo_stato,
	 		siac_d_bil_elem_categoria cat_del_capitolo,
     		siac_r_bil_elem_categoria r_cat_capitolo
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),
pdc_capitolo as (
select r_capitolo_pdc.elem_id,
	 pdc.classif_code pdc_code
from siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo
where r_capitolo_pdc.classif_id = pdc.classif_id and
  	 pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
     r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
     pdc_tipo.classif_tipo_code like 'PDC_%'		and
     r_capitolo_pdc.data_cancellazione 			is null and 	
     pdc.data_cancellazione is null 	and
     pdc_tipo.data_cancellazione 	is null),           
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --'STR'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_fpv_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
variaz_stanz_anno as (
	select a.elem_id, sum(a.importo) importo_stanz
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp
    group by a.elem_id),
variaz_stanz_anno1 as (
	select a.elem_id, sum(a.importo) importo_stanz1
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp1
    group by a.elem_id),
variaz_stanz_anno2 as (
	select a.elem_id, sum(a.importo) importo_stanz2
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp2
    group by a.elem_id),        
variaz_cassa_anno as (
	select a.elem_id, sum(a.importo) importo_cassa
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpCassa --SCA Cassa
        and a.periodo_anno = annoCapImp
    group by a.elem_id),  
variaz_residui_anno as (
	select a.elem_id, sum(a.importo) importo_residui
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpRes --STR Residui
        and a.periodo_anno = annoCapImp
    group by a.elem_id)                                                                                                       
select 
   capitoli.anno_bilancio::varchar bil_anno,
   ''::varchar missione_tipo_code,
   strut_bilancio.missione_tipo_desc::varchar missione_tipo_desc,
   strut_bilancio.missione_code::varchar missione_code,
   strut_bilancio.missione_desc::varchar missione_desc,
   ''::varchar programma_tipo_code,
   strut_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
   strut_bilancio.programma_code::varchar programma_code,
   strut_bilancio.programma_desc::varchar programma_desc,
   ''::varchar titusc_tipo_code,
   strut_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
   strut_bilancio.titusc_code::varchar titusc_code,
   strut_bilancio.titusc_desc::varchar titusc_desc,
   ''::varchar macroag_tipo_code,
   strut_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
   strut_bilancio.macroag_code::varchar macroag_code,
   strut_bilancio.macroag_desc::varchar macroag_desc,
   capitoli.elem_code::varchar bil_ele_code,
   capitoli.elem_desc::varchar bil_ele_desc,
   capitoli.elem_code2::varchar bil_ele_code2,
   capitoli.elem_desc2::varchar bil_ele_desc2,
   capitoli.elem_id::integer bil_ele_id,
   capitoli.elem_id_padre::integer bil_ele_id_padre,
-- 14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.   
   (COALESCE(imp_residui_anno.importo,0) +
    COALESCE(variaz_residui_anno.importo_residui,0))::numeric stanziamento_prev_res_anno,   
   COALESCE(imp_res_anno_prec.importo,0)::numeric stanziamento_anno_prec,
   (COALESCE(imp_cassa_anno.importo,0) +
    COALESCE(variaz_cassa_anno.importo_cassa,0))::numeric stanziamento_prev_cassa_anno,
   (COALESCE(imp_comp_anno.importo,0) +
    COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric stanziamento_prev_anno,
   (COALESCE(imp_comp_anno1.importo,0) +
    COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric stanziamento_prev_anno1,
   (COALESCE(imp_comp_anno2.importo,0) +
    COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric stanziamento_prev_anno2,
   0::numeric impegnato_anno,
   0::numeric impegnato_anno1,
   0::numeric impegnato_anno2,
   COALESCE(imp_res_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec,
   (COALESCE(imp_comp_fpv_anno.importo,0) +
    COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric stanziamento_fpv_anno,
   (COALESCE(imp_comp_fpv_anno1.importo,0) +
    COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric stanziamento_fpv_anno1,
   (COALESCE(imp_comp_fpv_anno2.importo,0) +
    COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric stanziamento_fpv_anno2,
   pdc_capitolo.pdc_code::varchar pdc,
   display_error::varchar display_error      
from strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id    
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id
    LEFT JOIN imp_residui_anno on capitoli.elem_id = imp_residui_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno on capitoli.elem_id = imp_comp_fpv_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno1 on capitoli.elem_id = imp_comp_fpv_anno1.elem_id
    LEFT JOIN imp_comp_fpv_anno2 on capitoli.elem_id = imp_comp_fpv_anno2.elem_id
    LEFT JOIN imp_res_anno_prec on capitoli.elem_id = imp_res_anno_prec.elem_id
    LEFT JOIN imp_res_fpv_anno_prec on capitoli.elem_id = imp_res_fpv_anno_prec.elem_id
    LEFT JOIN variaz_stanz_anno on capitoli.elem_id = variaz_stanz_anno.elem_id
    LEFT JOIN variaz_stanz_anno1 on capitoli.elem_id = variaz_stanz_anno1.elem_id
    LEFT JOIN variaz_stanz_anno2 on capitoli.elem_id = variaz_stanz_anno2.elem_id
    LEFT JOIN variaz_cassa_anno on capitoli.elem_id = variaz_cassa_anno.elem_id
    LEFT JOIN variaz_residui_anno on capitoli.elem_id = variaz_residui_anno.elem_id;

delete from siac_rep_var_spese where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;            
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-7877 - Maurizio - FINE


--SIAC-7875 - Maurizio - INIZIO

--aggiorno la posizione dei report a partire da BILR064
update siac_t_report a
set data_modifica=now(),
	login_operazione = login_operazione|| ' - SIAC-7875',
    rep_ordina_elenco_variab=rep_ordina_elenco_variab + 1
where a.rep_ordina_elenco_variab >= (SELECT t_rep.rep_ordina_elenco_variab
  					from siac_t_report t_rep
                    where t_rep.ente_proprietario_id=a.ente_proprietario_id
                    	and t_rep.rep_codice='BILR064')
	and  login_operazione not like '%SIAC-7875';  
    
insert into siac_t_report(
rep_codice,  rep_desc,  rep_birt_codice,
  validita_inizio, ente_proprietario_id,  data_creazione,
  data_modifica,  login_operazione,  rep_ordina_elenco_variab)
select 'BILR242', 'Assestamento - Variazioni - Quadro Generale Riassuntivo (BILR242)',
  'BILR242_Variazioni_Quadro_Generale_Riassuntivo',
  now(), ente.ente_proprietario_id, now(),
  now(), 'SIAC-7875', (select t_rep.rep_ordina_elenco_variab - 1
  					from siac_t_report t_rep
                    where t_rep.ente_proprietario_id=ente.ente_proprietario_id
                    	and t_rep.rep_codice='BILR064')
from siac_t_ente_proprietario ente  
where ente.data_cancellazione IS NULL
	and not exists (select 1
    				from siac_t_report a
                    where a.ente_proprietario_id=ente.ente_proprietario_id
                    	and a.rep_codice='BILR242'
                        and a.data_cancellazione IS NULL);     
						

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ant_liq_rend_novar',
        'Entrate - Utilizzo avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita''',
        0,
        'N',
        1, 
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7875'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_rend_novar');
      

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_fondo_ant_liq_spese_rend_novar',
        'Spese - Rimborso Prestiti - di cui Fondo anticipazioni di liquidita''',
        0,
        'N',
        2, 
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7875'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2020'
and c.periodo_tipo_code='SY'
and b2.anno in('2020','2021','2022')
and c2.periodo_tipo_code='SY'
and a.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fondo_ant_liq_spese_rend_novar');	      	
      

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR242'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_ant_liq_rend_novar')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR242'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
                
                
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR242'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
2 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7865' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_fondo_ant_liq_spese_rend_novar')
and c.anno='2020'
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR242'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));	


insert into bko_t_report_importi(
	rep_codice, rep_desc,  repimp_codice ,  repimp_desc,
  repimp_importo,  repimp_modificabile,  repimp_progr_riga, posizione_stampa)
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,
	0, b.repimp_modificabile, b.repimp_progr_riga, c.posizione_stampa
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e  
where a.rep_id=c.rep_id
	and b.repimp_id =c.repimp_id
    and b.bil_id=d.bil_id
    and d.periodo_id=e.periodo_id
    and a.rep_codice in('BILR242')
    and e.anno='2020'
    and a.data_cancellazione IS NULL 
    and b.data_cancellazione IS NULL 
    and c.data_cancellazione IS NULL
    and not exists (select 1
				    from bko_t_report_importi
                    where rep_codice = a.rep_codice
                    and repimp_codice=b.repimp_codice);
					
					
CREATE OR REPLACE FUNCTION siac."BILR242_variazioni_quadro_generale_riassuntivo_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titent_tipo_code varchar,
  titent_tipo_desc varchar,
  titent_code varchar,
  titent_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
titoloe_tipo_code varchar;
titoloe_TIPO_DESC varchar;
titoloe_CODE varchar;
titoloe_DESC varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
strApp VARCHAR;
intApp INTEGER;
x_array VARCHAR [];
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';

contaParVarPeg integer;
contaParVarBil integer;
id_bil integer;

BEGIN

/*
	16/12/2020. 
    Funzione nata per la SIAC-7875 per il nuovo report BILR242
    "Variazioni - Quadro Generale Riassuntivo".
    La funzione estrae gli stessi dati della "BILR112_Allegato_9_bill_gest_quadr_riass_gen_entrate"
    ma e' stata rivista per ragioni prestazionali.
    La differenza fra le 2 funzioni e' che questa estrae solo gli importi delle variazioni
    indicate in input, NON sono considerati gli importi dei capitoli.    
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione
contaParVarPeg:=0;
contaParVarBil:=0;

bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;


display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;

END IF;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

    
select fnc_siac_random_user()
into	user_table;
 	
-- carico su tabella di appoggio i dati delle variazioni
sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio          
     where r_variazione_stato.variazione_id	=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id 	   
    and	testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') 
    and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';

    sql_query=sql_query||' and	r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null 
     group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	cl.classif_id categoria_id,
                p_anno anno_bilancio,
                e.*
		from 	siac_r_bil_elem_class rc, 
            siac_t_bil_elem e, 
            siac_d_class_tipo ct,
            siac_t_class cl,
            siac_d_bil_elem_tipo tipo_elemento,          
            siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
            siac_d_bil_elem_categoria cat_del_capitolo,
            siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id=cl.classif_tipo_id
        and cl.classif_id=rc.classif_id 
        and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
        and e.elem_id=rc.elem_id        
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and e.ente_proprietario_id=p_ente_prop_id
        and e.bil_id= id_bil
        and ct.classif_tipo_code='CATEGORIA'
        and tipo_elemento.elem_tipo_code = elemTipoCode
        and	stato_capitolo.elem_stato_code	=	'VA'
        and	cat_del_capitolo.elem_cat_code	=	'STD'
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
        and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
        and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
        and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())),   
   imp_comp_anno as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
     imp_comp_anno1 as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp1
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
	imp_comp_anno2 as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp2
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
    imp_cassa_anno as (
        select 		capitolo_importi.elem_id,
                    capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                    capitolo_importi.ente_proprietario_id,   
                    sum(capitolo_importi.elem_det_importo) importo  
        from 		siac_t_bil_elem_det capitolo_importi,
                    siac_d_bil_elem_det_tipo capitolo_imp_tipo,
                    siac_t_periodo capitolo_imp_periodo,
                    siac_t_bil_elem capitolo,
                    siac_d_bil_elem_tipo tipo_elemento,
                    siac_d_bil_elem_stato stato_capitolo, 
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo, 
                    siac_r_bil_elem_categoria r_cat_capitolo
            where 	capitolo.elem_id					=	capitolo_importi.elem_id 
                and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
                and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
                and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
                and	capitolo.elem_id					=	r_capitolo_stato.elem_id
                and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
                and	capitolo.elem_id					=	r_cat_capitolo.elem_id
                and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
                and capitolo.bil_id 					= id_bil
                and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
                and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
                and	stato_capitolo.elem_stato_code		=	'VA'
                and	capitolo_imp_periodo.anno = annoCapImp
                and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA
                and	cat_del_capitolo.elem_cat_code	in ('STD')
                and	capitolo_importi.data_cancellazione 	is null
                and	capitolo_imp_tipo.data_cancellazione 	is null
                and	capitolo_imp_periodo.data_cancellazione is null
                and	capitolo.data_cancellazione 			is null
                and	tipo_elemento.data_cancellazione 		is null
                and	stato_capitolo.data_cancellazione 		is null
                and	r_capitolo_stato.data_cancellazione 	is null
                and	cat_del_capitolo.data_cancellazione 	is null
                and	r_cat_capitolo.data_cancellazione 		is null
                and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
                and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
                and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
                and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
                and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
                and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
                and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
                and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
                and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
                group by capitolo_importi.elem_id,
                capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
    variaz_stanz_anno_pos as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
            and a.importo >= 0
        group by a.elem_id),
	variaz_stanz_anno_neg as (
        select a.elem_id, sum(a.importo) importo_stanz
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp
            and a.importo < 0
        group by a.elem_id),        
    variaz_stanz_anno1_pos as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
            and a.importo >= 0
        group by a.elem_id),
    variaz_stanz_anno1_neg as (
        select a.elem_id, sum(a.importo) importo_stanz1
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp1
            and a.importo < 0
        group by a.elem_id),
    variaz_stanz_anno2_pos as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
            and a.importo >= 0
        group by a.elem_id),  
    variaz_stanz_anno2_neg as (
        select a.elem_id, sum(a.importo) importo_stanz2
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpComp --STA Competenza
            and a.periodo_anno = annoCapImp2
            and a.importo < 0
        group by a.elem_id),
	variaz_cassa_anno_pos as (
        select a.elem_id, sum(a.importo) importo_cassa
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpCassa --SCA Cassa
            and a.periodo_anno = annoCapImp
            and a.importo >= 0
        group by a.elem_id),
	variaz_cassa_anno_neg as (
        select a.elem_id, sum(a.importo) importo_cassa
        from siac_rep_var_entrate a
        where a.ente_proprietario= p_ente_prop_id
            and a.utente=user_table
            and a.tipologia = TipoImpCassa --SCA Cassa
            and a.periodo_anno = annoCapImp
            and a.importo < 0
        group by a.elem_id)                          
select capitoli.anno_bilancio::varchar bil_anno,
		''::varchar titent_tipo_code,
		strut_bilancio.classif_tipo_desc1::varchar titent_tipo_desc,
        strut_bilancio.titolo_code::varchar titent_code,
        strut_bilancio.titolo_desc::varchar titent_desc,
        ''::varchar tipologia_tipo_code,
        strut_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
        strut_bilancio.tipologia_code::varchar tipologia_code,
        strut_bilancio.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        strut_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
        strut_bilancio.categoria_code::varchar categoria_code,
        strut_bilancio.categoria_desc::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        -- gli importi sono relativi solo alle variazioni
        (COALESCE(variaz_cassa_anno_pos.importo_cassa,0) +
         COALESCE(variaz_cassa_anno_neg.importo_cassa,0))::numeric stanziamento_prev_cassa_anno,
        (COALESCE(variaz_stanz_anno_pos.importo_stanz,0) +
         COALESCE(variaz_stanz_anno_neg.importo_stanz,0))::numeric stanziamento_prev_anno,
        (COALESCE(variaz_stanz_anno1_pos.importo_stanz1,0) +
         COALESCE(variaz_stanz_anno1_neg.importo_stanz1,0))::numeric stanziamento_prev_anno1,
        (COALESCE(variaz_stanz_anno2_pos.importo_stanz2,0) +
    	 COALESCE(variaz_stanz_anno2_neg.importo_stanz2,0))::numeric stanziamento_prev_anno2,
        ''::varchar display_error
from strut_bilancio
	LEFT JOIN capitoli on capitoli.categoria_id = strut_bilancio.categoria_id  
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id    
    LEFT JOIN variaz_stanz_anno_pos on capitoli.elem_id = variaz_stanz_anno_pos.elem_id
    LEFT JOIN variaz_stanz_anno_neg on capitoli.elem_id = variaz_stanz_anno_neg.elem_id
    LEFT JOIN variaz_stanz_anno1_pos on capitoli.elem_id = variaz_stanz_anno1_pos.elem_id
    LEFT JOIN variaz_stanz_anno1_neg on capitoli.elem_id = variaz_stanz_anno1_neg.elem_id
    LEFT JOIN variaz_stanz_anno2_pos on capitoli.elem_id = variaz_stanz_anno2_pos.elem_id
    LEFT JOIN variaz_stanz_anno2_neg on capitoli.elem_id = variaz_stanz_anno2_neg.elem_id
    LEFT JOIN variaz_cassa_anno_pos on capitoli.elem_id = variaz_cassa_anno_pos.elem_id
    LEFT JOIN variaz_cassa_anno_neg on capitoli.elem_id = variaz_cassa_anno_neg.elem_id;                               
            
delete from siac_rep_var_entrate where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;                
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR242_variazioni_quadro_generale_riassuntivo_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
x_array VARCHAR [];
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

contaParVarPeg integer;
contaParVarBil integer;
id_bil integer;
strQuery varchar;

BEGIN

/*
	16/12/2020. 
    Funzione nata per la SIAC-7875 per il nuovo report BILR242
    "Variazioni - Quadro Generale Riassuntivo".
    La funzione estrae gli stessi dati della "BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese"
    ma e' stata rivista per ragioni prestazionali.
    La differenza fra le 2 funzioni e' che questa estrae solo gli importi delle variazioni
    indicate in input, NON sono considerati gli importi dei capitoli. 
    NON sono considerati gli importi dei capitoli.    
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
contaParVarPeg:=0;
contaParVarBil:=0;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

select fnc_siac_random_user()
into	user_table;

IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importi.anno	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno				in 	('''||annoCapImp||''','''||annoCapImp1||''','''||annoCapImp2||''')									
        and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id,
                    anno_importi.anno';                    

	raise notice 'Query variazioni spesa = %', strQuery;
    execute  strQuery;
end if;

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio, cat_del_capitolo.elem_cat_code tipo_cap,
       		capitolo.*
		from 
     		siac_d_class_tipo programma_tipo,
     		siac_t_class programma,
     		siac_d_class_tipo macroaggr_tipo,
     		siac_t_class macroaggr,
	 		siac_t_bil_elem capitolo,
	 		siac_d_bil_elem_tipo tipo_elemento,
     		siac_r_bil_elem_class r_capitolo_programma,
     		siac_r_bil_elem_class r_capitolo_macroaggr,
     		siac_d_bil_elem_stato stato_capitolo, 
     		siac_r_bil_elem_stato r_capitolo_stato,
	 		siac_d_bil_elem_categoria cat_del_capitolo,
     		siac_r_bil_elem_categoria r_cat_capitolo
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),        
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --'STR'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_fpv_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
variaz_stanz_anno_pos as (
	select a.elem_id, sum(a.importo) importo_stanz
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp
        and a.importo >= 0
    group by a.elem_id),
variaz_stanz_anno_neg as (
	select a.elem_id, sum(a.importo) importo_stanz
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp
        and a.importo < 0
    group by a.elem_id),    
variaz_stanz_anno1_pos as (
	select a.elem_id, sum(a.importo) importo_stanz1
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp1
        and a.importo >= 0
    group by a.elem_id),
variaz_stanz_anno1_neg as (
	select a.elem_id, sum(a.importo) importo_stanz1
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp1
        and a.importo < 0
    group by a.elem_id),    
variaz_stanz_anno2_pos as (
	select a.elem_id, sum(a.importo) importo_stanz2
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp2
        and a.importo >= 0
    group by a.elem_id),    
variaz_stanz_anno2_neg as (
	select a.elem_id, sum(a.importo) importo_stanz2
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp2
        and a.importo < 0
    group by a.elem_id),              
variaz_cassa_anno_pos as (
	select a.elem_id, sum(a.importo) importo_cassa
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpCassa --SCA Cassa
        and a.periodo_anno = annoCapImp
        and a.importo >= 0
    group by a.elem_id),  
variaz_cassa_anno_neg as (
	select a.elem_id, sum(a.importo) importo_cassa
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpCassa --SCA Cassa
        and a.periodo_anno = annoCapImp
        and a.importo < 0
    group by a.elem_id),     
variaz_residui_anno_pos as (
	select a.elem_id, sum(a.importo) importo_residui
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpRes --STR Residui
        and a.periodo_anno = annoCapImp
        and a.importo >= 0
    group by a.elem_id),
variaz_residui_anno_neg as (
	select a.elem_id, sum(a.importo) importo_residui
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpRes --STR Residui
        and a.periodo_anno = annoCapImp
        and a.importo < 0
    group by a.elem_id)                                                                                                             
select 
   capitoli.anno_bilancio::varchar bil_anno,
   ''::varchar missione_tipo_code,
   strut_bilancio.missione_tipo_desc::varchar missione_tipo_desc,
   strut_bilancio.missione_code::varchar missione_code,
   strut_bilancio.missione_desc::varchar missione_desc,
   ''::varchar programma_tipo_code,
   strut_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
   strut_bilancio.programma_code::varchar programma_code,
   strut_bilancio.programma_desc::varchar programma_desc,
   ''::varchar titusc_tipo_code,
   strut_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
   strut_bilancio.titusc_code::varchar titusc_code,
   strut_bilancio.titusc_desc::varchar titusc_desc,
   ''::varchar macroag_tipo_code,
   strut_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
   strut_bilancio.macroag_code::varchar macroag_code,
   strut_bilancio.macroag_desc::varchar macroag_desc,
   capitoli.elem_code::varchar bil_ele_code,
   capitoli.elem_desc::varchar bil_ele_desc,
   capitoli.elem_code2::varchar bil_ele_code2,
   capitoli.elem_desc2::varchar bil_ele_desc2,
   capitoli.elem_id::integer bil_ele_id,
   capitoli.elem_id_padre::integer bil_ele_id_padre,
  -- gli importi sono relativi solo alle variazioni  
   (COALESCE(variaz_residui_anno_pos.importo_residui,0) +
    COALESCE(variaz_residui_anno_neg.importo_residui,0))::numeric stanziamento_prev_res_anno,   
   COALESCE(imp_res_anno_prec.importo,0)::numeric stanziamento_anno_prec,
   (COALESCE(variaz_cassa_anno_pos.importo_cassa,0) +
    COALESCE(variaz_cassa_anno_neg.importo_cassa,0))::numeric stanziamento_prev_cassa_anno,
   	--gli importi delle variazioni degli stanziamenti sono caricati solo se i capitoli
    -- NON sono FPV.
   case when capitoli.tipo_cap not in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno_pos.importo_stanz,0) +
    	 COALESCE(variaz_stanz_anno_neg.importo_stanz,0))::numeric
   else 0::numeric end stanziamento_prev_anno,
   case when capitoli.tipo_cap not in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno1_pos.importo_stanz1,0) +
    	 COALESCE(variaz_stanz_anno1_neg.importo_stanz1,0))::numeric 
   else 0::numeric end stanziamento_prev_anno1,
   case when capitoli.tipo_cap not in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno2_pos.importo_stanz2,0) +
    	 COALESCE(variaz_stanz_anno2_neg.importo_stanz2,0))::numeric 
   else 0::numeric end stanziamento_prev_anno2,
   0::numeric impegnato_anno,
   0::numeric impegnato_anno1,
   0::numeric impegnato_anno2,
   COALESCE(imp_res_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec,
   --gli importi delle variazioni degli stanziamenti FPV sono caricati solo se i capitoli
    -- sono FPV.
   case when capitoli.tipo_cap in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno_pos.importo_stanz,0) +
    	 COALESCE(variaz_stanz_anno_neg.importo_stanz,0))::numeric 
   else 0::numeric end stanziamento_fpv_anno,
   case when capitoli.tipo_cap in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno1_pos.importo_stanz1,0) +
    	 COALESCE(variaz_stanz_anno1_neg.importo_stanz1,0))::numeric 
   else 0::numeric end stanziamento_fpv_anno1,
   case when capitoli.tipo_cap in('FPV', 'FPVC') then
   		(COALESCE(variaz_stanz_anno2_pos.importo_stanz2,0) +
    	 COALESCE(variaz_stanz_anno2_neg.importo_stanz2,0))::numeric 
   else 0::numeric end stanziamento_fpv_anno2,
   display_error::varchar display_error      
from strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id
    LEFT JOIN imp_residui_anno on capitoli.elem_id = imp_residui_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno on capitoli.elem_id = imp_comp_fpv_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno1 on capitoli.elem_id = imp_comp_fpv_anno1.elem_id
    LEFT JOIN imp_comp_fpv_anno2 on capitoli.elem_id = imp_comp_fpv_anno2.elem_id
    LEFT JOIN imp_res_anno_prec on capitoli.elem_id = imp_res_anno_prec.elem_id
    LEFT JOIN imp_res_fpv_anno_prec on capitoli.elem_id = imp_res_fpv_anno_prec.elem_id
    LEFT JOIN variaz_stanz_anno_pos on capitoli.elem_id = variaz_stanz_anno_pos.elem_id
    LEFT JOIN variaz_stanz_anno_neg on capitoli.elem_id = variaz_stanz_anno_neg.elem_id
    LEFT JOIN variaz_stanz_anno1_pos on capitoli.elem_id = variaz_stanz_anno1_pos.elem_id
    LEFT JOIN variaz_stanz_anno1_neg on capitoli.elem_id = variaz_stanz_anno1_neg.elem_id
    LEFT JOIN variaz_stanz_anno2_pos on capitoli.elem_id = variaz_stanz_anno2_pos.elem_id
    LEFT JOIN variaz_stanz_anno2_neg on capitoli.elem_id = variaz_stanz_anno2_neg.elem_id
    LEFT JOIN variaz_cassa_anno_pos on capitoli.elem_id = variaz_cassa_anno_pos.elem_id
    LEFT JOIN variaz_cassa_anno_neg on capitoli.elem_id = variaz_cassa_anno_neg.elem_id
    LEFT JOIN variaz_residui_anno_pos on capitoli.elem_id = variaz_residui_anno_pos.elem_id
    LEFT JOIN variaz_residui_anno_neg on capitoli.elem_id = variaz_residui_anno_neg.elem_id;

delete from siac_rep_var_spese where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
      return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;                    
    when others  THEN
      RTN_MESSAGGIO:='struttura bilancio altro errore';
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
				

--SIAC-7875 - Maurizio - FINE

--SIAC-7557 -FL - INIZIO

CREATE TABLE IF NOT EXISTS siac.sirfel_t_dati_ritenuta (
  id_ritenuta SERIAL, 
  ente_proprietario_id INTEGER NOT NULL,
  id_fattura INTEGER NOT NULL,
  tipo VARCHAR(4) NOT NULL,
  importo NUMERIC(15,2) NOT NULL,
  aliquota NUMERIC(6,2) NOT NULL,
  causale_pagamento VARCHAR(4),
  validita_inizio timestamp without time zone NOT NULL,
  validita_fine timestamp without time zone,
  data_creazione timestamp without time zone NOT NULL DEFAULT now(),
  data_modifica timestamp without time zone NOT NULL DEFAULT now(),
  data_cancellazione timestamp without time zone,
  login_operazione character varying(200),
  CONSTRAINT pk_sirfel_t_dati_ritenuta PRIMARY KEY (id_ritenuta),
  CONSTRAINT sirfel_t_dati_ritenuta_fk1 FOREIGN KEY (id_fattura, ente_proprietario_id)
  REFERENCES siac.sirfel_t_fattura(id_fattura, ente_proprietario_id)
) ;

/*CREATE SEQUENCE IF NOT EXISTS siac.sirfel_t_dati_ritenuta_num_id_seq
  INCREMENT 1 MINVALUE 1
  MAXVALUE 9223372036854775807 START 1
  CACHE 1;
ALTER SEQUENCE siac.sirfel_t_dati_ritenuta_num_id_seq RESTART WITH 2;*/


CREATE OR REPLACE VIEW siac.siac_v_dwh_datiritenuta_sirfel
 AS
select siac.sirfel_t_fattura.id_fattura, siac.sirfel_t_dati_ritenuta.aliquota, siac.sirfel_t_dati_ritenuta.importo, siac.sirfel_t_dati_ritenuta.tipo
from siac.sirfel_t_dati_ritenuta, siac.sirfel_t_fattura
where siac.sirfel_t_fattura.id_fattura = siac.sirfel_t_dati_ritenuta.id_fattura 
and siac.sirfel_t_fattura.ente_proprietario_id = siac.sirfel_t_dati_ritenuta.ente_proprietario_id
and siac.sirfel_t_dati_ritenuta.data_cancellazione is null;

GRANT SELECT ON siac.siac_v_dwh_datiritenuta_sirfel TO siac_dwh; 

insert into siac.sirfel_t_dati_ritenuta 
( id_fattura, ente_proprietario_id, tipo, importo, aliquota, validita_inizio, data_creazione, data_modifica, login_operazione, causale_pagamento)  
select 
 id_fattura, ente_proprietario_id, tipo_ritenuta, importo_ritenuta, aliquota_ritenuta, now(), data_inserimento, now(), 'SIAC-7557', causale_pagamento 
from siac.sirfel_t_fattura where tipo_ritenuta is not null;

drop table if exists siac.sirfel_t_fattura_bck;

create table IF NOT EXISTS siac.sirfel_t_fattura_bck as select * from siac.sirfel_t_fattura;

update siac.sirfel_t_fattura 
set tipo_ritenuta = null, aliquota_ritenuta = null, causale_pagamento = null, importo_ritenuta = null
where tipo_ritenuta is not null;


ALTER TABLE siac.sirfel_d_natura ALTER COLUMN codice TYPE varchar(4);
ALTER TABLE siac.sirfel_t_riepilogo_beni ALTER COLUMN natura TYPE VARCHAR(4);
ALTER TABLE siac.sirfel_t_cassa_previdenziale ALTER COLUMN natura TYPE VARCHAR(4);

/*
* N2.X Campi non soggetti
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.1',
'non soggette ad IVA ai sensi degli articoli da 7 a 7- septies del D.P.R. n. 633/1972'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N2.2',
'non soggette - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N2.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N3.X Campi non imponibili
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.1',
'non imponibili - esportazioni'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.2',
'non imponibili - cessioni intracomunitarie'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.3',
'non imponibili - cessioni verso San Marino'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.4',
'non imponibili - operazioni assimilate alle cessioni all''esportazione'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.5',
'non imponibili - a seguito di dichiarazioni d''intento'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);


insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N3.6',
'non imponibili - altre operazioni che non concorrono alla formazione del plafond'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N3.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

/*
* N6.X Campi inversione contabile
*/	
insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.1',
'inversione contabile - cessione di rottami e altri materiali di recupero'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.1'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.2',
'inversione contabile - cessione di oro e argento puro'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.2'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.3',
'inversione contabile - subappalto nel settore edile'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.3'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.4',
'inversione contabile - cessione di fabbricati'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.4'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.5',
'inversione contabile - cessione di telefoni cellulari'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.5'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.6',
'inversione contabile - cessione di prodotti elettronici'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.6'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.7',
'inversione contabile - prestazioni comparto edile e settori connessi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.7'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.8',
'inversione contabile - operazioni settore energetico'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.8'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);

insert into siac.sirfel_d_natura
(
 ente_proprietario_id, 
 codice,
 descrizione
)
select
ente.ente_proprietario_id,
'N6.9',
'inversione contabile - altri casi'
from siac.siac_t_ente_proprietario ente
where NOT EXISTS (
  SELECT 1
  FROM siac.sirfel_d_natura z
  WHERE z.codice = 'N6.9'
  AND z.ente_proprietario_id = ente.ente_proprietario_id
);





insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,15,3)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD20',
'Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD20'
and   tipoDOC.descrizione='Autofattura per regolarizzazione e integrazione delle fatture (ex art.6 c.8 d.lgs.471/97 o art.46 c.5 D.L. 331/93'
);

 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	
	
insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD16',
'Integrazione fattura reverse charge interno',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD16'
and   tipoDOC.descrizione='Integrazione fattura reverse charge interno'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD17',
'Integrazione/autofattura per acquisto servizi dall''estero',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD17'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto servizi dall''estero'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD18',
'Integrazione per acquisto di beni intracomunitari',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD18'
and   tipoDOC.descrizione='Integrazione per acquisto di beni intracomunitari'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD19',
'Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD19'
and   tipoDOC.descrizione='Integrazione/autofattura per acquisto di beni ex art.17 c.2 DPR 633/72'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD21',
'Autofattura per splafonamento',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD21'
and   tipoDOC.descrizione='Autofattura per splafonamento'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD22',
'Estrazione benida Deposito IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD22'
and   tipoDOC.descrizione='Estrazione benida Deposito IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD23',
'Estrazione beni da Deposito IVA con versamento dell'' IVA',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD23'
and   tipoDOC.descrizione='Estrazione beni da Deposito IVA con versamento dell'' IVA'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD24',
'Fattura differita di cui all''art.21, comma 4, lett. a)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD24'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, lett. a)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD25',
'Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD25'
and   tipoDOC.descrizione='Fattura differita di cui all''art.21, comma 4, terzo periodo lett. b)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD26',
'Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD26'
and   tipoDOC.descrizione='Cessione di beni ammortizzabili e per passaggi interni (ex art.36 DPR 633/72)'
);

insert into sirfel_d_tipo_documento
(
 ente_proprietario_id, 
 codice,
 descrizione, 
 flag_bilancio
)
select
ente.ente_proprietario_id,
'TD27',
'Fattura per autoconsumo o per cessioni gratuite senza rivalsa',
  'S'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,15,4,5,10,11,14,16)
and not exists
(
select 1
from sirfel_d_tipo_documento tipoDOC
where tipoDOC.ente_proprietario_id=ente.ente_proprietario_id
and   tipoDOC.codice='TD27'
and   tipoDOC.descrizione='Fattura per autoconsumo o per cessioni gratuite senza rivalsa'
);




insert into siac.sirfel_d_modalita_pagamento(ente_proprietario_id, codice, descrizione)
	select ente.ente_proprietario_id, 'MP23', 'PagoPA'
	from siac.siac_t_ente_proprietario ente
	where NOT EXISTS (
		SELECT 1 FROM siac.sirfel_d_modalita_pagamento z WHERE z.codice = 'MP23' AND z.ente_proprietario_id = ente.ente_proprietario_id);
		
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.az_code, tmp.az_desc, ta.azione_tipo_id, ga.gruppo_azioni_id, tmp.az_url, to_timestamp('01/01/2017','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
from siac_d_azione_tipo ta
join siac_t_ente_proprietario e on (ta.ente_proprietario_id = e.ente_proprietario_id)
join siac_d_gruppo_azioni ga on (ga.ente_proprietario_id = e.ente_proprietario_id)
join (values
	('OP-COM-visTipoDocumento', 'Ricerca Tipo Documento FEL - Contabilia', 'ATTIVITA_SINGOLA', 'FIN_BASE2', '/../siacbilapp/azioneRichiesta.do'),
	('OP-COM-gestTipoDocumento', 'Inserisci Tipo Documento FEL - Contabilia', 'ATTIVITA_SINGOLA', 'FIN_BASE2', '/../siacbilapp/azioneRichiesta.do')
) as tmp (az_code, az_desc, az_tipo, az_gruppo, az_url) on (tmp.az_tipo = ta.azione_tipo_code and tmp.az_gruppo = ga.gruppo_azioni_code)
where not exists (
	select 1
	from siac_t_azione z
	where z.azione_tipo_id = ta.azione_tipo_id
	and z.azione_code = tmp.az_code
);


SELECT * FROM  fnc_dba_add_column_params ( 'siac_t_iva_aliquota', 'codice', 'varchar(4)');

COMMENT ON COLUMN siac.siac_t_iva_aliquota.codice IS 'Codice Natura';

SELECT * FROM  fnc_dba_add_fk_constraint('siac_t_iva_aliquota', 'siac_t_iva_aliquota_sirfel_d_natura', 'codice,ente_proprietario_id', 'sirfel_d_natura', 'codice,ente_proprietario_id');



--NUOVE COLONNE ALLA TABELLA TIPO DOCUMENTO FEL: SIRFEL_D_TIPO_DOCUMENTO
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_e_id', 'integer');
SELECT * FROM  fnc_dba_add_column_params ( 'sirfel_d_tipo_documento', 'doc_tipo_s_id', 'integer');

COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_e_id IS 'Tipo Documento CONTABILIA entrata';
COMMENT ON COLUMN siac.sirfel_d_tipo_documento.doc_tipo_s_id IS 'Tipo Documento CONTABILIA spesa';

SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_e_sirfel_d_tipo_documento', 'doc_tipo_e_id', 'siac_d_doc_tipo', 'doc_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint('sirfel_d_tipo_documento', 'siac_d_doc_tipo_s_sirfel_d_tipo_documento', 'doc_tipo_s_id', 'siac_d_doc_tipo', 'doc_tipo_id');




update siac_t_iva_aliquota   ia
set codice =  (select codice from sirfel_d_natura where codice =  'N2.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc = 'ART. 74 C.1 LETT. C DPR 633/72 (LIBRI)';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N3.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc ='ART. 72 C.3 N.3 D.P.R. 633/72 TRATTATI INTERNAZ.';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N4' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc in ('4% - Esente', '10% - Esente', '22% - Esente');

update siac_t_iva_aliquota  ia
set codice = (select codice from sirfel_d_natura where codice =  'N6.9' and ia.ente_proprietario_id =ente_proprietario_id) 
where ivaaliquota_desc in ('4% - ART.17-TER SCISSIONE PAGAMENTI','10% - ART.17-TER SCISSIONE PAGAMENTI',
'22% - ART.17-TER SCISSIONE PAGAMENTI');



update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FTV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD01') and ente_proprietario_id in (2,3,15,4,5,10,11,14,16);


update sirfel_d_tipo_documento dtd
set doc_tipo_e_id =  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCV' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'E' and ente_proprietario_id =dtd.ente_proprietario_id)),
	doc_tipo_s_id = (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NCD' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD04') and ente_proprietario_id in (2,3,15,4,5,10,11,14,16);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FAT' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  (
'TD01',
'TD02',
'TD22',
'TD23',
'TD24',
'TD25',
'TD26'
)
and  ente_proprietario_id in (2,3,15,4,5,10,11,14,16);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD03')
and  ente_proprietario_id in (2,3,15,4,5,10,11,14,16);


update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'NTE' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD05')
and  ente_proprietario_id in (2,3,15,4,5,10,11,14,16);

update sirfel_d_tipo_documento dtd
set doc_tipo_s_id=  (select doc_tipo_id from siac_d_doc_tipo where doc_tipo_code =  'FPR' and ente_proprietario_id =dtd.ente_proprietario_id and doc_fam_tipo_id = (SELECT doc_fam_tipo_id
	 FROM siac.siac_d_doc_fam_tipo
	where doc_fam_tipo_code = 'S' and ente_proprietario_id =dtd.ente_proprietario_id))
where codice in  ('TD06')
and  ente_proprietario_id in (2,3,15,4,5,10,11,14,16);
--SIAC-7557 -FL - FINE

--SIAC-7556 -FL - INIZIO
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-CRUSCOTTO-PAGOPA','Ricerca Elaborazioni PagoPA',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'FUN_ACCESSORIE'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-CRUSCOTTO-PAGOPA'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
--SIAC-7556 -FL - FINE




-- 7846 inizio


select fnc_siac_bko_inserisci_azione('OP-BKOF017-definisciVariazioneSenzaBonita', 'Variazioni - Backoffice definisci variazione senza Bonita', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	
	
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_definisci_variazione(annobilancio integer, variazionenum integer, enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
  DECLARE
   strmessaggio       VARCHAR(1500):='';
   strmessaggiofinale VARCHAR(1500):='';
   codresult          INTEGER:=NULL;
   recResult record;

  messaggiorisultato text:=null;
  begin


    strMessaggioFinale:='Variazione bilancio - definizione.';
    raise notice 'strMessaggioFinale=%',strMessaggioFinale;

    raise notice 'annoBilancio=%', quote_nullable(annoBilancio::varchar);
    raise notice 'variazioneNum=%', quote_nullable(variazioneNum::varchar);

    if coalesce(annoBilancio::varchar,'0')='0'  or  coalesce(variazioneNum::varchar,'0')='0' then
    	strmessaggio:=' Anno bilancio o numero variazione non valorizzati. Impossibile determinare variazioni da trattare.';
        raise exception ' ';
    end if;

	codResult:=0;
    strMessaggio:='Esecuzione fnc_siac_bko_gestisci_variazione variazione_num='||variazioneNum::varchar||'.';
    raise notice 'strMessaggio=%',strMessaggio;

    select * into recResult
    from fnc_siac_bko_gestisci_variazione
    (
    enteProprietarioId,
    annoBilancio,
    variazioneNum,
    true,
    'D',
    true,
    loginOperazione,
    dataElaborazione
    );

    if recResult.codiceRisultato::integer=0 then
        strMessaggio:=strMessaggio||' Definizione effettuata.';
        codResult:=0;
    else
        strMessaggio:=strMessaggio||recResult.messaggioRisultato;
		codResult:=recResult.codiceRisultato::integer;
    end if;


    if codResult=0 then
		messaggioRisultato:=('0|'||strMessaggioFinale||strMessaggio)::text;
        
    else
	    messaggioRisultato:=('-1|'||strMessaggioFinale||strMessaggio)::text;
    end if;    
    
    raise notice 'messaggioRisultato=%',messaggioRisultato;



    RETURN messaggioRisultato;
  EXCEPTION
  WHEN raise_exception THEN

    messaggiorisultato:=(
    '-1'||
    strmessaggiofinale
    ||strmessaggio
    ||'ERRORE :'
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500))::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    RETURN messaggioRisultato;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=
    ('-1'||
     strmessaggiofinale
     ||strmessaggio
     ||'Nessun elemento trovato.' )::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN messaggiorisultato;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=
    ('-1'||
    strmessaggiofinale
    ||strmessaggio
    ||'Errore DB '
    ||SQLSTATE
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500))::text ;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN messaggioRisultato;
  END;
  $function$
;


-- 7846 fine


-- 7672 inizio  Haitham 17/12/2020

-- Sofia - 17.12.2020
CREATE TABLE IF NOT EXISTS siac.pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_id SERIAL,
  pagopa_elab_svecchia_tipo_code VARCHAR(50) NOT NULL,
  pagopa_elab_svecchia_tipo_desc VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  pagopa_elab_svecchia_tipo_fl_attivo boolean default false not null,
  pagopa_elab_svecchia_tipo_fl_back boolean default true not null,
  pagopa_elab_svecchia_delta_giorni integer,
  CONSTRAINT pk_pagopa_d_elaborazione_svecchia_tipo PRIMARY KEY(pagopa_elab_svecchia_tipo_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_elaborazione_svecchia_tipo FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_d_elaborazione_svecchia_tipo
IS 'Tipologie di svecchiamenti PAGOPA.';

alter table siac.pagopa_d_elaborazione_svecchia_tipo owner to siac;

CREATE TABLE IF NOT EXISTS siac.pagopa_t_elaborazione_svecchia
(
  pagopa_elab_svecchia_id SERIAL,
  pagopa_elab_svecchia_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_svecchia_note VARCHAR(1500) NOT NULL,
  pagopa_elab_svecchia_tipo_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione_svecchia PRIMARY KEY(pagopa_elab_svecchia_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione_svecchia FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_svecchia_pagopa_t_elaborazione_svecchia FOREIGN KEY (pagopa_elab_svecchia_tipo_id)
    REFERENCES siac.pagopa_d_elaborazione_svecchia_tipo(pagopa_elab_svecchia_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.pagopa_t_elaborazione_svecchia
IS 'Elaborazioni di svecchiamento PAGOPA.';

alter table siac.pagopa_t_elaborazione_svecchia owner to siac;


insert into pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_code,
  pagopa_elab_svecchia_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  pagopa_elab_svecchia_tipo_fl_attivo,
  pagopa_elab_svecchia_tipo_fl_back
)
select
  'PUNTUALE',
  'SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE',
   now(),
   ente.ente_proprietario_id,
   'SIAC-7672',
   false,
   true

from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select  1
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.pagopa_elab_svecchia_tipo_code ='PUNTUALE'
);

insert into pagopa_d_elaborazione_svecchia_tipo
(
  pagopa_elab_svecchia_tipo_code,
  pagopa_elab_svecchia_tipo_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  pagopa_elab_svecchia_tipo_fl_attivo,
  pagopa_elab_svecchia_tipo_fl_back,
  pagopa_elab_svecchia_delta_giorni
)
select
  'PERIODICO',
  'SVECCHIAMENTO PERIODICO ELAB. CONCLUSE CON SUCCESSO',
   now(),
   ente.ente_proprietario_id,
   'SIAC-7672',
   false,
   true,
   30
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select  1
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.pagopa_elab_svecchia_tipo_code ='PERIODICO'
);

create table IF NOT EXISTS siac.pagopa_t_bck_riconciliazione_doc
(
  pagopa_bck_ric_doc_id serial,
  pagopa_ric_doc_id integer,
  pagopa_ric_doc_data TIMESTAMP,
  pagopa_ric_doc_voce_code VARCHAR,
  pagopa_ric_doc_voce_desc VARCHAR,
  pagopa_ric_doc_voce_tematica VARCHAR,
  pagopa_ric_doc_sottovoce_code VARCHAR,
  pagopa_ric_doc_sottovoce_desc VARCHAR,
  pagopa_ric_doc_sottovoce_importo NUMERIC,
  pagopa_ric_doc_anno_esercizio INTEGER,
  pagopa_ric_doc_anno_accertamento INTEGER,
  pagopa_ric_doc_num_accertamento INTEGER,
  pagopa_ric_doc_num_capitolo INTEGER,
  pagopa_ric_doc_num_articolo INTEGER,
  pagopa_ric_doc_pdc_v_fin VARCHAR,
  pagopa_ric_doc_titolo VARCHAR,
  pagopa_ric_doc_tipologia VARCHAR,
  pagopa_ric_doc_categoria VARCHAR,
  pagopa_ric_doc_codice_benef VARCHAR,
  pagopa_ric_doc_str_amm VARCHAR,
  pagopa_ric_doc_subdoc_id INTEGER,
  pagopa_ric_doc_provc_id INTEGER,
  pagopa_ric_doc_movgest_ts_id INTEGER,
  pagopa_ric_doc_stato_elab VARCHAR,
  pagopa_ric_errore_id INTEGER,
  pagopa_ric_id INTEGER,
  pagopa_elab_flusso_id INTEGER,
  file_pagopa_id INTEGER NOT NULL,
  pagopa_elab_svecchia_id integer not null,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  pagopa_ric_doc_ragsoc_benef VARCHAR,
  pagopa_ric_doc_nome_benef VARCHAR,
  pagopa_ric_doc_cognome_benef VARCHAR,
  pagopa_ric_doc_codfisc_benef VARCHAR,
  pagopa_ric_doc_soggetto_id INTEGER,
  pagopa_ric_doc_flag_dett BOOLEAN,
  pagopa_ric_doc_flag_con_dett BOOLEAN ,
  pagopa_ric_doc_tipo_code VARCHAR,
  pagopa_ric_doc_tipo_id INTEGER,
  pagopa_ric_det_id INTEGER,
  pagopa_ric_doc_iuv VARCHAR(100),
  pagopa_ric_doc_data_operazione TIMESTAMP,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_pagopa_bck_pagopa_t_riconciliazione_doc PRIMARY KEY(pagopa_bck_ric_doc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_riconc_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table IF NOT EXISTS siac.pagopa_t_bck_elaborazione_flusso
(
  pagopa_bck_elab_flusso_id serial,
  pagopa_elab_flusso_id integer,
  pagopa_elab_flusso_data TIMESTAMP,
  pagopa_elab_flusso_stato_id INTEGER,
  pagopa_elab_flusso_note VARCHAR(750),
  pagopa_elab_ric_flusso_id VARCHAR,
  pagopa_elab_flusso_nome_mittente VARCHAR,
  pagopa_elab_ric_flusso_data VARCHAR,
  pagopa_elab_flusso_tot_pagam NUMERIC,
  pagopa_elab_flusso_anno_esercizio INTEGER,
  pagopa_elab_flusso_anno_provvisorio INTEGER,
  pagopa_elab_flusso_num_provvisorio INTEGER,
  pagopa_elab_flusso_provc_id INTEGER,
  pagopa_elab_id INTEGER,
  pagopa_elab_svecchia_id integer,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_pagopa_t_elaborazione_flusso PRIMARY KEY(pagopa_bck_elab_flusso_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_elab_flusso FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_pagopa_t_elaborazione_flusso FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table IF NOT EXISTS siac.pagopa_r_bck_elaborazione_file
(
  pagopa_bck_r_elab_id serial,
  pagopa_r_elab_id integer,
  pagopa_elab_id INTEGER,
  file_pagopa_id INTEGER,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  pagopa_elab_svecchia_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_pagopa_bck_pagopa_r_elaborazione_file PRIMARY KEY(pagopa_bck_r_elab_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_r_elaborazione_file FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_r_elaborazione_file FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

create table IF NOT EXISTS siac.pagopa_t_bck_elaborazione
(
  pagopa_bck_elab_id Serial,
  pagopa_elab_id integer,
  pagopa_elab_data TIMESTAMP,
  pagopa_elab_stato_id INTEGER,
  pagopa_elab_note VARCHAR(1500),
  pagopa_elab_file_id VARCHAR(250),
  pagopa_elab_file_ora VARCHAR(250),
  pagopa_elab_file_ente VARCHAR(250),
  pagopa_elab_file_fruitore VARCHAR(250),
  file_pagopa_id INTEGER,
  pagopa_elab_errore_id INTEGER,
  pagopa_elab_svecchia_id integer,
  bck_validita_inizio TIMESTAMP,
  bck_validita_fine TIMESTAMP,
  bck_data_creazione TIMESTAMP,
  bck_data_modifica TIMESTAMP,
  bck_data_cancellazione TIMESTAMP,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
CONSTRAINT pk_pagopa_bck_pagopa_t_elaborazione PRIMARY KEY(pagopa_bck_elab_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_pagopa_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
CONSTRAINT pagopa_t_elab_svecchia_pagopa_bck_t_elaborazione FOREIGN KEY (pagopa_elab_svecchia_id)
    REFERENCES siac.pagopa_t_elaborazione_svecchia(pagopa_elab_svecchia_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);
-- Sofia - 17.12.2020

CREATE TABLE IF NOT EXISTS siac.siac_t_bck_file_pagopa (
	file_bck_pagopa_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	file_pagopa_id int4 NULL,
	file_pagopa_size numeric NOT NULL,
	file_pagopa bytea NULL,
	file_pagopa_code varchar NOT NULL,
	file_pagopa_note varchar NULL,
	file_pagopa_anno int4 NOT NULL,
	file_pagopa_stato_id int4 NOT NULL,
	file_pagopa_errore_id int4 NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	file_pagopa_id_psp varchar NULL,
	file_pagopa_id_flusso varchar null
   );	
   

CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_riconciliazione (
	pagopa_ric_bck_ric_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_ric_id int4 NOT NULL,
	pagopa_ric_data timestamp NOT NULL DEFAULT now(),
	pagopa_ric_file_id varchar NULL, 
	pagopa_ric_file_ora timestamp NULL, 
	pagopa_ric_file_ente varchar NULL, 
	pagopa_ric_file_fruitore varchar NULL, 
	pagopa_ric_file_num_flussi int4 NULL, 
	pagopa_ric_file_tot_flussi numeric NULL, 
	pagopa_ric_flusso_id varchar NULL, 
	pagopa_ric_flusso_nome_mittente varchar NULL,
	pagopa_ric_flusso_data timestamp NULL,
	pagopa_ric_flusso_tot_pagam numeric NULL,
	pagopa_ric_flusso_anno_esercizio int4 NULL, 
	pagopa_ric_flusso_anno_provvisorio int4 NULL, 
	pagopa_ric_flusso_num_provvisorio int4 NULL,
	pagopa_ric_flusso_voce_code varchar NULL, 
	pagopa_ric_flusso_voce_desc varchar NULL,
	pagopa_ric_flusso_tematica varchar NULL,
	pagopa_ric_flusso_sottovoce_code varchar NULL, 
	pagopa_ric_flusso_sottovoce_desc varchar NULL,
	pagopa_ric_flusso_sottovoce_importo numeric NULL, 
	pagopa_ric_flusso_anno_accertamento int4 NULL, 
	pagopa_ric_flusso_num_accertamento int4 NULL, 
	pagopa_ric_flusso_num_capitolo int4 NULL,
	pagopa_ric_flusso_num_articolo int4 NULL,
	pagopa_ric_flusso_pdc_v_fin varchar NULL,
	pagopa_ric_flusso_titolo varchar NULL,
	pagopa_ric_flusso_tipologia varchar NULL,
	pagopa_ric_flusso_categoria varchar NULL,
	pagopa_ric_flusso_codice_benef varchar NULL,
	pagopa_ric_flusso_str_amm varchar NULL,
	file_pagopa_id int4 NOT NULL, 
	pagopa_ric_flusso_stato_elab varchar NOT NULL DEFAULT 'N'::character varying,
	pagopa_ric_errore_id int4 NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	pagopa_ric_flusso_ragsoc_benef varchar NULL,
	pagopa_ric_flusso_nome_benef varchar NULL,
	pagopa_ric_flusso_cognome_benef varchar NULL,
	pagopa_ric_flusso_codfisc_benef varchar null
	);
	
	

CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_riconciliazione_det (
	pagopa_ric_bck_det_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_ric_det_id int4 NOT NULL,
	pagopa_det_anag_cognome varchar NULL,
	pagopa_det_anag_nome varchar NULL,
	pagopa_det_anag_ragione_sociale varchar NULL,
	pagopa_det_anag_codice_fiscale varchar NULL,
	pagopa_det_anag_indirizzo varchar NULL,
	pagopa_det_anag_civico varchar NULL,
	pagopa_det_anag_cap varchar(5) NULL,
	pagopa_det_anag_localita varchar NULL,
	pagopa_det_anag_provincia varchar NULL,
	pagopa_det_anag_nazione varchar NULL,
	pagopa_det_anag_email varchar NULL,
	pagopa_det_causale_versamento_desc varchar NULL,
	pagopa_det_causale varchar NULL,
	pagopa_det_data_pagamento timestamp NULL,
	pagopa_det_esito_pagamento varchar NULL,
	pagopa_det_importo_versamento numeric NULL,
	pagopa_det_indice_versamento int4 NULL,
	pagopa_det_transaction_id varchar NULL,
	pagopa_det_versamento_id varchar NULL,
	pagopa_det_riscossione_id varchar NULL,
	pagopa_ric_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT null
	);
	
	
	
CREATE TABLE IF NOT EXISTS siac.pagopa_t_bck_elaborazione_log (
	pagopa_elab_bck_log_id serial NOT NULL,
	pagopa_elab_svecchia_id int4 NULL,
	pagopa_elab_log_id int4 NOT NULL,
	pagopa_elab_id int4 NULL,
	pagopa_elab_file_id int4 NULL,
	pagopa_elab_log_operazione varchar(2500) NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	ente_proprietario_id int4 NOT NULL,
	login_operazione varchar(200) NOT null
	);

-- Sofia - 17.12.2020
alter table siac.pagopa_t_bck_riconciliazione_doc owner to siac;
alter table siac.pagopa_t_bck_elaborazione_flusso owner to siac;
alter table siac.pagopa_r_bck_elaborazione_file owner to siac;
alter table siac.pagopa_t_bck_elaborazione owner to siac;
alter table siac.siac_t_bck_file_pagopa owner to siac;
alter table siac.pagopa_t_bck_riconciliazione owner to siac;
alter table siac.pagopa_t_bck_riconciliazione_det owner to siac;
alter table siac.pagopa_t_bck_elaborazione_log owner to siac;
-- Sofia - 17.12.2020




CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_svecchia(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT svecchiapagopaelabid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE

	strMessaggio VARCHAR(2500):='';
    strMessaggioBck  VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';


    pagoPaRec record;


	codResult integer:=null;
    countDel  integer:=null;
    
    altri_record integer:=null;
   
    pagopaElabSvecchiaId integer:=null;

    nCountoRecordPrima integer:=null;
    nCountoRecordDopo integer:=null;

    pagopaElabSvecchiaTipoflagAttivo boolean:=null;
    pagopaElabSvecchiaTipoflagBack boolean:=null;
    pagopaElabSvecchiaTipoDeltaGG  integer:=null;
	dataSvecchia timestamp:=null;
    dataSvecchiaSqlQuery varchar(200):=null;

	SVECCHIA_CODE_PERIODICO CONSTANT  varchar :='PERIODICO';
BEGIN

   codiceRisultato:=0;
   messaggioRisultato:='';
   svecchiaPagoPaElabId:=null;


   strMessaggioFinale:='Elaborazione svecchiamento '||SVECCHIA_CODE_PERIODICO||' rinconciliazione PAGOPA.';

   strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_svecchia - '||strMessaggioFinale;
  
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

   

   strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PERIODICO||'].';
   select tipo.pagopa_elab_svecchia_tipo_fl_attivo, tipo.pagopa_elab_svecchia_tipo_fl_back, coalesce(tipo.pagopa_elab_svecchia_delta_giorni,0)
   into   pagopaElabSvecchiaTipoflagAttivo,pagopaElabSvecchiaTipoflagBack,pagopaElabSvecchiaTipoDeltaGG
   from pagopa_d_elaborazione_svecchia_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO;
   if pagopaElabSvecchiaTipoflagAttivo is null or pagopaElabSvecchiaTipoflagBack is null then
    	codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
   end if;

   if pagopaElabSvecchiaTipoflagAttivo=false then
    	messaggioRisultato:=strMessaggio||' Tipo svecchiamento non attivo.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   if   pagopaElabSvecchiaTipoDeltaGG<=0 then
	    messaggioRisultato:=strMessaggio||' Delta day di svecchiamento non impostato correttamente.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PERIODICO||']. Calcolo data di svecchiamento.';
   dataSvecchiaSqlQuery:='select date_trunc(''DAY'','''||dataElaborazione||'''::timestamp)- interval '''||pagopaElabSvecchiaTipoDeltaGG||' day'' ';
   raise notice 'dataSvecchiaSqlQuery=%',dataSvecchiaSqlQuery;
   execute dataSvecchiaSqlQuery into dataSvecchia;
   if dataSvecchia is null then
   		messaggioRisultato:=strMessaggio||' Errore in calcolo.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   strMessaggioFinale:='Elaborazione svecchiamento periodico rinconciliazione PAGOPA per '||
                       ' dataSvecchia='||to_char(dataSvecchia,'dd/mm/yyyy')||'.';
   raise notice 'dataSvecchia=%',dataSvecchia;

   strMessaggio:='Inserimento elaborazione id svecchiamento [pagopa_t_elaborazione_svecchia].';
   insert into pagopa_t_elaborazione_svecchia
   (
	    pagopa_elab_svecchia_data,
	    pagopa_elab_svecchia_note,
	    pagopa_elab_svecchia_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
   )
   select
       clock_timestamp(),
       upper('INIZIO '||tipo.pagopa_elab_svecchia_tipo_desc||'. Data svecchiamento='||to_char(dataSvecchia,'dd/mm/yyyy')||'.'),
       tipo.pagopa_elab_svecchia_tipo_id,
       clock_timestamp(),
       loginOperazione,
       tipo.ente_proprietario_id
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO
    returning pagopa_elab_svecchia_id into pagopaElabSvecchiaId;
    if pagopaElabSvecchiaId is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in inserimento.'||strMessaggioFinale;
        return;
    end if;
    raise notice '---------- ELEABORAZIONE IN CORSO --------------';

countDel:=0;


--pagopa_t_elaborazione (A) 
      if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
        strMessaggio:='Backup  pagopa_t_elaborazione.';
	    raise notice 'strMessaggio= backup pagopa_t_elaborazione - ';
        codResult:=0;   
insert into pagopa_t_bck_elaborazione
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_id,
              pagopa_elab_data,
              pagopa_elab_stato_id,
              pagopa_elab_note,
              pagopa_elab_file_id,
              pagopa_elab_file_ora,
              pagopa_elab_file_ente,
              pagopa_elab_file_fruitore,
              file_pagopa_id,
              pagopa_elab_errore_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              elab.pagopa_elab_id,
              elab.pagopa_elab_data,
              elab.pagopa_elab_stato_id,
              elab.pagopa_elab_note,
              elab.pagopa_elab_file_id,
              elab.pagopa_elab_file_ora,
              elab.pagopa_elab_file_ente,
              elab.pagopa_elab_file_fruitore,
              elab.file_pagopa_id,
              elab.pagopa_elab_errore_id,
              elab.validita_inizio,
              elab.validita_fine,
              elab.data_creazione,
              elab.data_modifica,
              elab.data_cancellazione,
              elab.login_operazione,
              clock_timestamp(),
              loginOperazione,
              elab.ente_proprietario_id            
     from pagopa_t_elaborazione elab, 
          pagopa_d_elaborazione_stato stato
     where stato.ente_proprietario_id=enteproprietarioid
       and stato.pagopa_elab_stato_code='ELABORATO_OK'
       and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
       and elab.pagopa_elab_data < dataSvecchia::timestamp;
        --returning pagopa_bck_elab_id into codResult;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;




--	pagopa_t_elaborazione_flusso (B)   
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_elaborazione_flusso.';
	  raise notice 'strMessaggio= backup pagopa_t_elaborazione_flusso - ';
      codResult:=0;   
      insert into pagopa_t_bck_elaborazione_flusso
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_flusso_id,
              pagopa_elab_flusso_data,
              pagopa_elab_flusso_stato_id,
              pagopa_elab_flusso_note,
              pagopa_elab_ric_flusso_id,
              pagopa_elab_flusso_nome_mittente,
              pagopa_elab_ric_flusso_data,
              pagopa_elab_flusso_tot_pagam,
              pagopa_elab_flusso_anno_esercizio,
              pagopa_elab_flusso_anno_provvisorio,
              pagopa_elab_flusso_num_provvisorio,
              pagopa_elab_flusso_provc_id,
              pagopa_elab_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              fl.pagopa_elab_flusso_id,
              fl.pagopa_elab_flusso_data,
              fl.pagopa_elab_flusso_stato_id,
              fl.pagopa_elab_flusso_note,
              fl.pagopa_elab_ric_flusso_id,
              fl.pagopa_elab_flusso_nome_mittente,
              fl.pagopa_elab_ric_flusso_data,
              fl.pagopa_elab_flusso_tot_pagam,
              fl.pagopa_elab_flusso_anno_esercizio,
              fl.pagopa_elab_flusso_anno_provvisorio,
              fl.pagopa_elab_flusso_num_provvisorio,
              fl.pagopa_elab_flusso_provc_id,
              fl.pagopa_elab_id,
              fl.validita_inizio,
              fl.validita_fine,
              fl.data_creazione,
              fl.data_modifica,
              fl.data_cancellazione,
              fl.login_operazione,
              clock_timestamp(),
              loginOperazione,
              fl.ente_proprietario_id
        from pagopa_t_elaborazione elab, 
             pagopa_d_elaborazione_stato stato,
             pagopa_t_elaborazione_flusso fl
        where stato.ente_proprietario_id=enteproprietarioid
          and stato.pagopa_elab_stato_code='ELABORATO_OK'
          and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
          and elab.pagopa_elab_data < dataSvecchia::timestamp
          and elab.pagopa_elab_id = fl.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;





--	pagopa_t_riconciliazione_doc  (C) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione_doc.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione_doc - ';
      codResult:=0;   
insert into pagopa_t_bck_riconciliazione_doc
        (
          pagopa_elab_svecchia_id,
          pagopa_ric_doc_id,
          pagopa_ric_doc_data,
          pagopa_ric_doc_voce_code,
          pagopa_ric_doc_voce_desc,
          pagopa_ric_doc_voce_tematica,
          pagopa_ric_doc_sottovoce_code,
          pagopa_ric_doc_sottovoce_desc,
          pagopa_ric_doc_sottovoce_importo,
          pagopa_ric_doc_anno_esercizio,
          pagopa_ric_doc_anno_accertamento,
          pagopa_ric_doc_num_accertamento,
          pagopa_ric_doc_num_capitolo,
          pagopa_ric_doc_num_articolo,
          pagopa_ric_doc_pdc_v_fin,
          pagopa_ric_doc_titolo,
          pagopa_ric_doc_tipologia,
          pagopa_ric_doc_categoria,
          pagopa_ric_doc_codice_benef,
          pagopa_ric_doc_str_amm,
          pagopa_ric_doc_subdoc_id,
          pagopa_ric_doc_provc_id,
          pagopa_ric_doc_movgest_ts_id,
          pagopa_ric_doc_stato_elab,
          pagopa_ric_errore_id,
          pagopa_ric_id,
          pagopa_elab_flusso_id,
          file_pagopa_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          pagopa_ric_doc_ragsoc_benef,
          pagopa_ric_doc_nome_benef,
          pagopa_ric_doc_cognome_benef,
          pagopa_ric_doc_codfisc_benef,
          pagopa_ric_doc_soggetto_id,
          pagopa_ric_doc_flag_dett,
          pagopa_ric_doc_flag_con_dett,
          pagopa_ric_doc_tipo_code,
          pagopa_ric_doc_tipo_id,
          pagopa_ric_det_id,
          pagopa_ric_doc_iuv,
          pagopa_ric_doc_data_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        select
          pagopaElabSvecchiaId,
          ric_doc.pagopa_ric_doc_id,
          ric_doc.pagopa_ric_doc_data,
          ric_doc.pagopa_ric_doc_voce_code,
          ric_doc.pagopa_ric_doc_voce_desc,
          ric_doc.pagopa_ric_doc_voce_tematica,
          ric_doc.pagopa_ric_doc_sottovoce_code,
          ric_doc.pagopa_ric_doc_sottovoce_desc,
          ric_doc.pagopa_ric_doc_sottovoce_importo,
          ric_doc.pagopa_ric_doc_anno_esercizio,
          ric_doc.pagopa_ric_doc_anno_accertamento,
          ric_doc.pagopa_ric_doc_num_accertamento,
          ric_doc.pagopa_ric_doc_num_capitolo,
          ric_doc.pagopa_ric_doc_num_articolo,
          ric_doc.pagopa_ric_doc_pdc_v_fin,
          ric_doc.pagopa_ric_doc_titolo,
          ric_doc.pagopa_ric_doc_tipologia,
          ric_doc.pagopa_ric_doc_categoria,
          ric_doc.pagopa_ric_doc_codice_benef,
          ric_doc.pagopa_ric_doc_str_amm,
          ric_doc.pagopa_ric_doc_subdoc_id,
          ric_doc.pagopa_ric_doc_provc_id,
          ric_doc.pagopa_ric_doc_movgest_ts_id,
          ric_doc.pagopa_ric_doc_stato_elab,
          ric_doc.pagopa_ric_errore_id,
          ric_doc.pagopa_ric_id,
          ric_doc.pagopa_elab_flusso_id,
          ric_doc.file_pagopa_id,
          ric_doc.validita_inizio,
          ric_doc.validita_fine,
          ric_doc.data_creazione,
          ric_doc.data_modifica,
          ric_doc.data_cancellazione,
          ric_doc.login_operazione,
          ric_doc.pagopa_ric_doc_ragsoc_benef,
          ric_doc.pagopa_ric_doc_nome_benef,
          ric_doc.pagopa_ric_doc_cognome_benef,
          ric_doc.pagopa_ric_doc_codfisc_benef,
          ric_doc.pagopa_ric_doc_soggetto_id,
          ric_doc.pagopa_ric_doc_flag_dett,
          ric_doc.pagopa_ric_doc_flag_con_dett,
          ric_doc.pagopa_ric_doc_tipo_code,
          ric_doc.pagopa_ric_doc_tipo_id,
          ric_doc.pagopa_ric_det_id,
          ric_doc.pagopa_ric_doc_iuv,
          ric_doc.pagopa_ric_doc_data_operazione,
          clock_timestamp(),
          loginOperazione,
          ric_doc.ente_proprietario_id          
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_t_elaborazione_flusso fl,
			 pagopa_t_riconciliazione ric,
			 pagopa_t_riconciliazione_doc ric_doc
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = fl.pagopa_elab_id
		  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
		  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
		  and ric_doc.pagopa_ric_doc_stato_elab='S'
		  and (ric_doc.pagopa_ric_doc_flag_con_dett=false  or ric_doc.pagopa_ric_doc_flag_dett=true);
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;
  
  



--	pagopa_r_elaborazione_file     (D)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_r_elaborazione_file.';
	  raise notice 'strMessaggio= backup pagopa_r_elaborazione_file - ';
      codResult:=0;   
insert into pagopa_r_bck_elaborazione_file
            (
              pagopa_elab_svecchia_id,
              pagopa_r_elab_id,
              pagopa_elab_id,
              file_pagopa_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              rf.pagopa_r_elab_id,
              rf.pagopa_elab_id,
              rf.file_pagopa_id,
              rf.validita_inizio,
              rf.validita_fine,
              rf.data_creazione,
              rf.data_modifica,
              rf.data_cancellazione,
              rf.login_operazione,
              clock_timestamp(),
              loginOperazione,
              rf.ente_proprietario_id              
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;



--	siac_t_file_pagopa   (E)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  siac_t_file_pagopa.';
	  raise notice 'strMessaggio= backup siac_t_file_pagopa - ';
      codResult:=0;   
		insert into siac_t_bck_file_pagopa (
			pagopa_elab_svecchia_id,
			file_pagopa_id,
			file_pagopa_size,
			file_pagopa,
			file_pagopa_code,
			file_pagopa_note,
			file_pagopa_anno,
			file_pagopa_stato_id,
			file_pagopa_errore_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione,
			file_pagopa_id_psp,
			file_pagopa_id_flusso
		   )	
		 select 
			pagopaElabSvecchiaId,
			file.file_pagopa_id,
			file.file_pagopa_size,
			file.file_pagopa,
			file.file_pagopa_code,
			file.file_pagopa_note,
			file.file_pagopa_anno,
			file.file_pagopa_stato_id,
			file.file_pagopa_errore_id,
			file.validita_inizio,
			file.validita_fine,
			file.ente_proprietario_id,
			file.data_creazione,
			file.data_modifica,
			file.data_cancellazione,
			file.login_operazione,
			file.file_pagopa_id_psp,
			file.file_pagopa_id_flusso 
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 siac_t_file_pagopa file
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = file.file_pagopa_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;




--	pagopa_t_riconciliazione   (F)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione - ';
      codResult:=0;   
     insert into pagopa_t_bck_riconciliazione (
			pagopa_elab_svecchia_id,
			pagopa_ric_id,
			pagopa_ric_data,
			pagopa_ric_file_id,
			pagopa_ric_file_ora,
			pagopa_ric_file_ente,
			pagopa_ric_file_fruitore,
			pagopa_ric_file_num_flussi,
			pagopa_ric_file_tot_flussi,
			pagopa_ric_flusso_id,
			pagopa_ric_flusso_nome_mittente,
			pagopa_ric_flusso_data,
			pagopa_ric_flusso_tot_pagam,
			pagopa_ric_flusso_anno_esercizio,
			pagopa_ric_flusso_anno_provvisorio,
			pagopa_ric_flusso_num_provvisorio,
			pagopa_ric_flusso_voce_code,
			pagopa_ric_flusso_voce_desc,
			pagopa_ric_flusso_tematica,
			pagopa_ric_flusso_sottovoce_code,
			pagopa_ric_flusso_sottovoce_desc,
			pagopa_ric_flusso_sottovoce_importo,
			pagopa_ric_flusso_anno_accertamento,
			pagopa_ric_flusso_num_accertamento,
			pagopa_ric_flusso_num_capitolo,
			pagopa_ric_flusso_num_articolo,
			pagopa_ric_flusso_pdc_v_fin,
			pagopa_ric_flusso_titolo,
			pagopa_ric_flusso_tipologia,
			pagopa_ric_flusso_categoria,
			pagopa_ric_flusso_codice_benef,
			pagopa_ric_flusso_str_amm,
			file_pagopa_id,
			pagopa_ric_flusso_stato_elab,
			pagopa_ric_errore_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione,
			pagopa_ric_flusso_ragsoc_benef,
			pagopa_ric_flusso_nome_benef,
			pagopa_ric_flusso_cognome_benef,
			pagopa_ric_flusso_codfisc_benef
			)
		select 
			pagopaElabSvecchiaId,
			ric.pagopa_ric_id,
			ric.pagopa_ric_data,
			ric.pagopa_ric_file_id,
			ric.pagopa_ric_file_ora,
			ric.pagopa_ric_file_ente,
			ric.pagopa_ric_file_fruitore,
			ric.pagopa_ric_file_num_flussi,
			ric.pagopa_ric_file_tot_flussi,
			ric.pagopa_ric_flusso_id,
			ric.pagopa_ric_flusso_nome_mittente,
			ric.pagopa_ric_flusso_data,
			ric.pagopa_ric_flusso_tot_pagam,
			ric.pagopa_ric_flusso_anno_esercizio,
			ric.pagopa_ric_flusso_anno_provvisorio,
			ric.pagopa_ric_flusso_num_provvisorio,
			ric.pagopa_ric_flusso_voce_code,
			ric.pagopa_ric_flusso_voce_desc,
			ric.pagopa_ric_flusso_tematica,
			ric.pagopa_ric_flusso_sottovoce_code,
			ric.pagopa_ric_flusso_sottovoce_desc,
			ric.pagopa_ric_flusso_sottovoce_importo,
			ric.pagopa_ric_flusso_anno_accertamento,
			ric.pagopa_ric_flusso_num_accertamento,
			ric.pagopa_ric_flusso_num_capitolo,
			ric.pagopa_ric_flusso_num_articolo,
			ric.pagopa_ric_flusso_pdc_v_fin,
			ric.pagopa_ric_flusso_titolo,
			ric.pagopa_ric_flusso_tipologia,
			ric.pagopa_ric_flusso_categoria,
			ric.pagopa_ric_flusso_codice_benef,
			ric.pagopa_ric_flusso_str_amm,
			ric.file_pagopa_id,
			ric.pagopa_ric_flusso_stato_elab,
			ric.pagopa_ric_errore_id,
			ric.validita_inizio,
			ric.validita_fine,
			ric.ente_proprietario_id,
			ric.data_creazione,
			ric.data_modifica,
			ric.data_cancellazione,
			ric.login_operazione,
			ric.pagopa_ric_flusso_ragsoc_benef,
			ric.pagopa_ric_flusso_nome_benef,
			ric.pagopa_ric_flusso_cognome_benef,
			ric.pagopa_ric_flusso_codfisc_benef 
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 pagopa_t_riconciliazione ric
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = ric.file_pagopa_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;






--	pagopa_t_riconciliazione_det  (G) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione_det.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione_det - ';
      codResult:=0;   
      insert into pagopa_t_bck_riconciliazione_det (
			pagopa_elab_svecchia_id,
			pagopa_ric_det_id,
			pagopa_det_anag_cognome,
			pagopa_det_anag_nome,
			pagopa_det_anag_ragione_sociale,
			pagopa_det_anag_codice_fiscale,
			pagopa_det_anag_indirizzo,
			pagopa_det_anag_civico,
			pagopa_det_anag_cap,
			pagopa_det_anag_localita,
			pagopa_det_anag_provincia,
			pagopa_det_anag_nazione,
			pagopa_det_anag_email,
			pagopa_det_causale_versamento_desc,
			pagopa_det_causale,
			pagopa_det_data_pagamento,
			pagopa_det_esito_pagamento,
			pagopa_det_importo_versamento,
			pagopa_det_indice_versamento,
			pagopa_det_transaction_id,
			pagopa_det_versamento_id,
			pagopa_det_riscossione_id,
			pagopa_ric_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione
			)
		select 
			pagopaElabSvecchiaId,
			det.pagopa_ric_det_id,
			det.pagopa_det_anag_cognome,
			det.pagopa_det_anag_nome,
			det.pagopa_det_anag_ragione_sociale,
			det.pagopa_det_anag_codice_fiscale,
			det.pagopa_det_anag_indirizzo,
			det.pagopa_det_anag_civico,
			det.pagopa_det_anag_cap,
			det.pagopa_det_anag_localita,
			det.pagopa_det_anag_provincia,
			det.pagopa_det_anag_nazione,
			det.pagopa_det_anag_email,
			det.pagopa_det_causale_versamento_desc,
			det.pagopa_det_causale,
			det.pagopa_det_data_pagamento,
			det.pagopa_det_esito_pagamento,
			det.pagopa_det_importo_versamento,
			det.pagopa_det_indice_versamento,
			det.pagopa_det_transaction_id,
			det.pagopa_det_versamento_id,
			det.pagopa_det_riscossione_id,
			det.pagopa_ric_id,
			det.validita_inizio,
			det.validita_fine,
			det.ente_proprietario_id,
			det.data_creazione,
			det.data_modifica,
			det.data_cancellazione,
			det.login_operazione
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 pagopa_t_riconciliazione ric,
			 pagopa_t_riconciliazione_det det
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = ric.file_pagopa_id
		  and ric.pagopa_ric_id = det.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;


  --	pagopa_t_elaborazione_log    (I) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_elaborazione_log.';
	  raise notice 'strMessaggio= backup pagopa_t_elaborazione_log - ';
      codResult:=0;   
      insert into pagopa_t_bck_elaborazione_log (
			pagopa_elab_svecchia_id,
			pagopa_elab_log_id,
			pagopa_elab_id,
			pagopa_elab_file_id,
			pagopa_elab_log_operazione,
			data_creazione,
			ente_proprietario_id,
			login_operazione
			)
		select 
			pagopaElabSvecchiaId,
			lg.pagopa_elab_log_id,
			lg.pagopa_elab_id,
			lg.pagopa_elab_file_id,
			lg.pagopa_elab_log_operazione,
			lg.data_creazione,
			lg.ente_proprietario_id,
			lg.login_operazione
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_t_elaborazione_log lg
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = lg.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;



 raise notice '---------- INIZIO FASE CANCELLAZIONE --------------';
    
countDel:=0;

  --	pagopa_bck_t_registrounico_doc    (L12) 
strMessaggio:='Cancellazione pagopa_bck_t_registrounico_doc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_registrounico_doc - ';
codResult:=0;
delete from pagopa_bck_t_registrounico_doc reg
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
 and stato.pagopa_elab_stato_code='ELABORATO_OK'
 and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
 and elab.pagopa_elab_data < dataSvecchia::timestamp
 and elab.pagopa_elab_id = reg.pagopa_elab_id;
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;
 
   
   
   

  
 --	pagopa_bck_t_doc_class    (L11) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_class.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_class - ';
codResult:=0;
delete from pagopa_bck_t_doc_class cl
using pagopa_t_elaborazione elab, 
     pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = cl.pagopa_elab_id;   
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  

  --	pagopa_bck_t_doc_attr    (L10) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_attr.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_attr - ';
codResult:=0;
delete from pagopa_bck_t_doc_attr attr
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = attr.pagopa_elab_id; 
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
  

 

  --	pagopa_bck_t_doc_sog    (L9) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_sog.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_sog - ';
codResult:=0;
delete from pagopa_bck_t_doc_sog sog
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = sog.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;


 
 

  --	pagopa_bck_t_subdoc_num    (L8) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_num.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_num - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_num num
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = num.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
  

  --	pagopa_bck_t_doc_stato    (L7) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_stato.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_stato - ';
codResult:=0;
delete from pagopa_bck_t_doc_stato stdoc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = stdoc.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  

  --	pagopa_bck_t_doc    (L6) 
strMessaggio:='Cancellazione pagopa_bck_t_doc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc - ';
codResult:=0;
delete from  pagopa_bck_t_doc doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = doc.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 

  --	pagopa_bck_t_subdoc_movgest_ts    (L5) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_movgest_ts.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_movgest_ts - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_movgest_ts ts
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = ts.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
   
 
  --	pagopa_bck_t_subdoc_prov_cassa    (L4) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_prov_cassa.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_prov_cassa - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_prov_cassa prov
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = prov.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
  --	pagopa_bck_t_subdoc_atto_amm    (L3) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_atto_amm.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_atto_amm - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_atto_amm amm
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = amm.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;

 
 
  --	pagopa_bck_t_subdoc_attr    (L2) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_attr.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_attr - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_attr attr
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = attr.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
  --	pagopa_bck_t_subdoc    (L1) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc - ';
codResult:=0;
delete from pagopa_bck_t_subdoc sub
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = sub.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
 
  
  --	pagopa_t_elaborazione_log    (I) 
strMessaggio:='Cancellazione pagopa_t_elaborazione_log.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_log - ';
codResult:=0;
delete from pagopa_t_elaborazione_log lg 
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = lg.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;

  
--	pagopa_t_riconciliazione_det  (G) 
strMessaggio:='Cancellazione pagopa_t_riconciliazione_det.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_det - ';
codResult:=0;
delete from pagopa_t_riconciliazione_det det
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_r_elaborazione_file rf,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = ric.file_pagopa_id
  and ric.pagopa_ric_id = det.pagopa_ric_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
--	pagopa_t_riconciliazione_doc   (C)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl--,
    --  pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id;
 --and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
 -- and ric_doc.pagopa_ric_doc_stato_elab='S' 
 -- and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
--	pagopa_t_riconciliazione_doc   (C)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc. eventuali elborazioni precedenti andate male';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab != 'S' 
  and ric_doc.pagopa_ric_doc_flag_con_dett=false 
  and  ric_doc.pagopa_ric_doc_flag_dett=true;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 

 
--	pagopa_t_riconciliazione           (F)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione - ';
codResult:=0;
delete from pagopa_t_riconciliazione ric
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_r_elaborazione_file rf,
      pagopa_t_riconciliazione_doc ric_doc
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = ric.file_pagopa_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab='S'
  and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
      


 
--	pagopa_t_elaborazione_flusso (B)   
strMessaggio:='Cancellazione pagopa_t_elaborazione_flusso.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_flusso (B) - ';
codResult:=0;
delete from pagopa_t_elaborazione_flusso fl
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
      --,      
      --pagopa_t_riconciliazione_doc ric_doc,
      --pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id;
  --and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  --and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  --and ric_doc.pagopa_ric_doc_stato_elab='S' 
  --and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
 
 
--	pagopa_r_elaborazione_file     (D)  
strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
codResult:=0;
delete from pagopa_r_elaborazione_file rf
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id ;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 


--	siac_t_file_pagopa   (E)  
strMessaggio:='Cancellazione siac_t_file_pagopa.';
raise notice 'strMessaggio= cancellazione siac_t_file_pagopa - ';
codResult:=0;
delete from siac_t_file_pagopa file
using pagopa_t_elaborazione elab, 
     pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file rf
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = file.file_pagopa_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 

--	pagopa_t_riconciliazione_doc   (H)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (H)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab='S' 
  and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult; 
 

--	pagopa_t_riconciliazione_doc   (H)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
--  and ric_doc.pagopa_ric_doc_stato_elab='S'
  and ric_doc.pagopa_ric_doc_flag_con_dett=true   
  and ric_doc.pagopa_ric_doc_flag_dett=false;    
 GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult; 
 
 
 
 select count(*) into altri_record 
 from pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl
 where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id;
  raise notice 'altri_record=%',altri_record;

 if altri_record = 0 then
 --	pagopa_r_elaborazione_file   
strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
codResult:=0;
delete from pagopa_r_elaborazione_file rf
using pagopa_t_elaborazione elab, 
      pagopa_t_elaborazione_flusso fl,
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and rf.pagopa_elab_id = fl.pagopa_elab_id;
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'pagopa_r_elaborazione_file cancellati=%',codResult;
  countDel:=countDel+codResult;
 

 end if;
 
 
 
--	pagopa_t_modifica_elab    
strMessaggio:='Cancellazione pagopa_t_modifica_elab.';
raise notice 'strMessaggio= cancellazione pagopa_t_modifica_elab - ';
codResult:=0;
delete from pagopa_t_modifica_elab modif
using pagopa_t_elaborazione elab,
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and modif.pagopa_elab_id = elab.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
 
--	pagopa_t_elaborazione (A)   
strMessaggio:='Cancellazione pagopa_t_elaborazione.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione - ';
codResult:=0;
delete from pagopa_t_elaborazione elab
using pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
 
 

 raise notice 'countDel=%',countDel;


 
 
   codResult:=null;
   strMessaggio:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia - '
                  ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                  ||' Chiusura elaborazione [pagopa_t_elaborazione_svecchia].';
    raise notice 'strMessaggio=%',strMessaggio;
    update pagopa_t_elaborazione_svecchia elab
    set    data_modifica=clock_timestamp(),
           validita_fine=clock_timestamp(),
           pagopa_elab_svecchia_note=
           upper('FINE '||tipo.pagopa_elab_svecchia_tipo_desc||'. Data svecchiamento='||to_char(dataSvecchia,'dd/mm/yyyy')||'.'
           ||' Cancellati complessivamente '||coalesce(countDel,0)::varchar||' pagopa_t_riconciliazione_doc.')
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO
    and   elab.pagopa_elab_svecchia_id=pagopaElabSvecchiaId
    returning pagopa_elab_svecchia_id into codResult;
    if codResult is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in aggiornamento.'||strMessaggioFinale;
        return;
    end if;
   raise notice '---------- ELABORAZIONE TERMINATA --------------';

  

    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia - '
                          ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                          ||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
    codResult:=null;
    insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;  
  
  
   svecchiaPagoPaElabId:=pagopaElabSvecchiaId;
   messaggioRisultato:=strMessaggioFinale;
   return;

  exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
   		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	return;

END;
$function$
;

-- Sofia - 17.12.2020
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out svecchiaPagoPaElabId        integer,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
-- SIAC-7961 Sofia 19.01.2021
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out svecchiaPagoPaElabId        integer,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
	codResult integer:=null;
    countDel  integer:=null;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

    SVECCHIA_CODE_PUNTUALE CONSTANT  varchar :='PUNTUALE';

    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;


    annoBilancio integer:=null;



    fncRec record;
    pagoPaRec record;
	pagopaElabSvecchiaId integer :=null;
    pagopaElabSvecchiaTipoflagAttivo boolean:=false;
    pagopaElabSvecchiaTipoflagBack boolean:=false;

BEGIN
	strMessaggioFinale:='Elaborazione svecchiamento puntuale rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';
    svecchiaPagoPaElabId:=null;



    strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PUNTUALE||'].';
    select tipo.pagopa_elab_svecchia_tipo_fl_attivo, tipo.pagopa_elab_svecchia_tipo_fl_back
    into   pagopaElabSvecchiaTipoflagAttivo,pagopaElabSvecchiaTipoflagBack
	from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE;
    if pagopaElabSvecchiaTipoflagAttivo is null or pagopaElabSvecchiaTipoflagBack is null then
    	codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
    end if;

    if pagopaElabSvecchiaTipoflagAttivo=false then
    	messaggioRisultato:=strMessaggio||' Tipo svecchiamento non attivo.'||strMessaggioFinale;
        return;
    end if;


    strMessaggio:='Verifica esistenza dati da svecchiare.';
    -- elaborazione deve essere ELABORATO_KO, ELABORATO_ERRATO, ELABORATO_SCARTATO
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
    and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null;
    raise notice 'strMessaggio  %',strMessaggio;
    raise notice 'codResult %',codResult;
    if codResult is null then
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
    end if;


	strMessaggio:='Inserimento elaborazione id svecchiamento [pagopa_t_elaborazione_svecchia].';
    insert into pagopa_t_elaborazione_svecchia
    (
	    pagopa_elab_svecchia_data,
	    pagopa_elab_svecchia_note,
	    pagopa_elab_svecchia_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select
       clock_timestamp(),
       'INIZIO '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar||'.',
       tipo.pagopa_elab_svecchia_tipo_id,
       clock_timestamp(),
       loginOperazione,
       tipo.ente_proprietario_id
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE
    returning pagopa_elab_svecchia_id into pagopaElabSvecchiaId;
    if pagopaElabSvecchiaId is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in inserimento.'||strMessaggioFinale;
        return;
    end if;

    -- se elaborazione_KO  o ERRATO, SCARTATO
    -- ricercare pagopa_t_riconciliazione_doc in N,X
	-- quindi cercare per lo stesso pagopa_t_riconciliazione
	-- precedenti elaborazioni in errore ( stesse condizioni )
	-- se trovate procedere con la cancellazione dei dati di elaborazione
	-- sino  a cancellare tutti i dati coinvolti in elaborazione se non esiste altro sotto
    strMessaggio:='Apertura cursore dati di riconciliazione da cancellare.';

    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio||' '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
    codResult:=null;
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    countDel:=0;
    for pagoPaRec in
    (
	 select flusso.pagopa_elab_id,doc.*
	 from  pagopa_t_elaborazione_flusso flusso,
           pagopa_t_riconciliazione_doc doc
	 where flusso.pagopa_elab_id<filePagoPaElabId
     --and   flusso.pagopa_elab_id>=235
	 and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_stato_elab !='S'
	 and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
     and   exists
     (
     	 select 1
		 from  pagopa_t_elaborazione_flusso flusso_cur,
               pagopa_t_riconciliazione_doc doc_cur
   	     where flusso_cur.pagopa_elab_id=filePagoPaElabId
	 	 and   doc_cur.pagopa_elab_flusso_id=flusso_cur.pagopa_elab_flusso_id
		 and   doc_cur.pagopa_ric_doc_stato_elab !='S'
         and   doc_cur.pagopa_ric_id=doc.pagopa_ric_id
		 and   ( doc_cur.pagopa_ric_doc_flag_con_dett=false  or doc_cur.pagopa_ric_doc_flag_dett=true)
		 and   doc_cur.data_cancellazione is null
		 and   flusso_cur.data_cancellazione is null
     )
     and   flusso.pagopa_elab_id>=
     (
      select distinct elab_prec.pagopa_elab_id
      from  pagopa_t_elaborazione elab_prec, pagopa_d_elaborazione_stato stato_prec,
      pagopa_t_elaborazione_flusso flusso_prec, pagopa_t_riconciliazione_doc doc_prec
      where doc_prec.pagopa_ric_id=doc.pagopa_ric_id
      and   (doc_prec.pagopa_ric_doc_flag_con_dett=false  or doc_prec.pagopa_ric_doc_flag_dett=true)
      and   doc_prec.pagopa_ric_doc_stato_elab !='S'
      and   flusso_prec.pagopa_elab_flusso_id=doc_prec.pagopa_elab_flusso_id
      and   elab_prec.pagopa_elab_id=flusso_prec.pagopa_elab_id
      and   stato_prec.pagopa_elab_stato_id=elab_prec.pagopa_elab_stato_id
      and   stato_prec.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
      and   stato_prec.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
      and   elab_prec.pagopa_elab_id<filePagoPaElabId
      and   doc_prec.data_cancellazione is null
      and   flusso_prec.data_cancellazione is null
      and   elab_prec.data_cancellazione is null
      order by elab_prec.pagopa_elab_id desc
      limit 1
     )
	 and   doc.data_cancellazione is null
	 and   flusso.data_cancellazione is null
	 order by flusso.pagopa_elab_id, doc.pagopa_ric_id
    )
    loop

      -- delete
      -- pagopa_t_riconciliazione_doc
      -- x pagopa_ric_doc_id
      raise notice '@@@@@@@@ pagoPaRec.pagopa_elab_id=%',pagoPaRec.pagopa_elab_id;
      if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
        strMessaggio:='Backup  pagopa_t_riconciliazione_doc.';
	    raise notice 'strMessaggio= backup pagopa_t_riconciliazione_doc - ';
        codResult:=0;
        insert into pagopa_t_bck_riconciliazione_doc
        (
          pagopa_elab_svecchia_id,
          pagopa_ric_doc_id,
          pagopa_ric_doc_data,
          pagopa_ric_doc_voce_code,
          pagopa_ric_doc_voce_desc,
          pagopa_ric_doc_voce_tematica,
          pagopa_ric_doc_sottovoce_code,
          pagopa_ric_doc_sottovoce_desc,
          pagopa_ric_doc_sottovoce_importo,
          pagopa_ric_doc_anno_esercizio,
          pagopa_ric_doc_anno_accertamento,
          pagopa_ric_doc_num_accertamento,
          pagopa_ric_doc_num_capitolo,
          pagopa_ric_doc_num_articolo,
          pagopa_ric_doc_pdc_v_fin,
          pagopa_ric_doc_titolo,
          pagopa_ric_doc_tipologia,
          pagopa_ric_doc_categoria,
          pagopa_ric_doc_codice_benef,
          pagopa_ric_doc_str_amm,
          pagopa_ric_doc_subdoc_id,
          pagopa_ric_doc_provc_id,
          pagopa_ric_doc_movgest_ts_id,
          pagopa_ric_doc_stato_elab,
          pagopa_ric_errore_id,
          pagopa_ric_id,
          pagopa_elab_flusso_id,
          file_pagopa_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          pagopa_ric_doc_ragsoc_benef,
          pagopa_ric_doc_nome_benef,
          pagopa_ric_doc_cognome_benef,
          pagopa_ric_doc_codfisc_benef,
          pagopa_ric_doc_soggetto_id,
          pagopa_ric_doc_flag_dett,
          pagopa_ric_doc_flag_con_dett,
          pagopa_ric_doc_tipo_code,
          pagopa_ric_doc_tipo_id,
          pagopa_ric_det_id,
          pagopa_ric_doc_iuv,
          pagopa_ric_doc_data_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        select
          pagopaElabSvecchiaId,
          del.pagopa_ric_doc_id,
          del.pagopa_ric_doc_data,
          del.pagopa_ric_doc_voce_code,
          del.pagopa_ric_doc_voce_desc,
          del.pagopa_ric_doc_voce_tematica,
          del.pagopa_ric_doc_sottovoce_code,
          del.pagopa_ric_doc_sottovoce_desc,
          del.pagopa_ric_doc_sottovoce_importo,
          del.pagopa_ric_doc_anno_esercizio,
          del.pagopa_ric_doc_anno_accertamento,
          del.pagopa_ric_doc_num_accertamento,
          del.pagopa_ric_doc_num_capitolo,
          del.pagopa_ric_doc_num_articolo,
          del.pagopa_ric_doc_pdc_v_fin,
          del.pagopa_ric_doc_titolo,
          del.pagopa_ric_doc_tipologia,
          del.pagopa_ric_doc_categoria,
          del.pagopa_ric_doc_codice_benef,
          del.pagopa_ric_doc_str_amm,
          del.pagopa_ric_doc_subdoc_id,
          del.pagopa_ric_doc_provc_id,
          del.pagopa_ric_doc_movgest_ts_id,
          del.pagopa_ric_doc_stato_elab,
          del.pagopa_ric_errore_id,
          del.pagopa_ric_id,
          del.pagopa_elab_flusso_id,
          del.file_pagopa_id,
          del.validita_inizio,
          del.validita_fine,
          del.data_creazione,
          del.data_modifica,
          del.data_cancellazione,
          del.login_operazione,
          del.pagopa_ric_doc_ragsoc_benef,
          del.pagopa_ric_doc_nome_benef,
          del.pagopa_ric_doc_cognome_benef,
          del.pagopa_ric_doc_codfisc_benef,
          del.pagopa_ric_doc_soggetto_id,
          del.pagopa_ric_doc_flag_dett,
          del.pagopa_ric_doc_flag_con_dett,
          del.pagopa_ric_doc_tipo_code,
          del.pagopa_ric_doc_tipo_id,
          del.pagopa_ric_det_id,
          del.pagopa_ric_doc_iuv,
          del.pagopa_ric_doc_data_operazione,
          clock_timestamp(),
          loginOperazione,
          del.ente_proprietario_id
        from pagopa_t_riconciliazione_doc del
        where del.pagopa_ric_doc_id=pagoPaRec.pagopa_ric_doc_id
        returning pagopa_bck_ric_doc_id into codResult;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
        raise notice '%',strMessaggioLog;
        codResult:=null;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
      end if;

	  strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
      raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - ';
      codResult:=0;
      delete from pagopa_t_riconciliazione_doc del
      where del.pagopa_ric_doc_id=pagoPaRec.pagopa_ric_doc_id;
      GET DIAGNOSTICS codResult = ROW_COUNT;
      if codResult is null then codResult:=0; end if;
      raise notice 'pagoPaRec.pagopa_ric_doc_id=%',pagoPaRec.pagopa_ric_doc_id;
      raise notice 'pagoPaRec.pagopa_ric_id=%',pagoPaRec.pagopa_ric_id;
      raise notice 'cancellati=%',codResult;
      countDel:=countDel+codResult;

      strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
      raise notice '%',strMessaggioLog;
      codResult:=null;
	  insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

      -- x pagopa_ric_id and pagopa_ric_doc_flag_con_dett=true
      strMessaggio:='Verifica esistenza pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true.';
      raise notice 'strMessaggio= verifica esistenza pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true - ';
      codResult:=0;
      select coalesce(count(*),0) into codResult
      from pagopa_t_riconciliazione_doc del
      where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
      and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
      and   del.pagopa_ric_doc_flag_con_dett=true;
      raise notice 'esistenti=%',codResult;
      if codResult!=0 then
        codResult:=0;
        select coalesce(count(*),0) into codResult
        from pagopa_t_riconciliazione_doc del
        where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
        and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
        and   del.pagopa_ric_doc_flag_dett=true
        and   del.pagopa_ric_doc_id!=pagoPaRec.pagopa_ric_doc_id;
        if codResult=0 then
          if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
            strMessaggio:='Backup  pagopa_t_riconciliazione_doc.';
            raise notice 'strMessaggio= backup pagopa_t_riconciliazione_doc - ';
            codResult:=0;
            insert into pagopa_t_bck_riconciliazione_doc
            (
              pagopa_elab_svecchia_id,
              pagopa_ric_doc_id,
              pagopa_ric_doc_data,
              pagopa_ric_doc_voce_code,
              pagopa_ric_doc_voce_desc,
              pagopa_ric_doc_voce_tematica,
              pagopa_ric_doc_sottovoce_code,
              pagopa_ric_doc_sottovoce_desc,
              pagopa_ric_doc_sottovoce_importo,
              pagopa_ric_doc_anno_esercizio,
              pagopa_ric_doc_anno_accertamento,
              pagopa_ric_doc_num_accertamento,
              pagopa_ric_doc_num_capitolo,
              pagopa_ric_doc_num_articolo,
              pagopa_ric_doc_pdc_v_fin,
              pagopa_ric_doc_titolo,
              pagopa_ric_doc_tipologia,
              pagopa_ric_doc_categoria,
              pagopa_ric_doc_codice_benef,
              pagopa_ric_doc_str_amm,
              pagopa_ric_doc_subdoc_id,
              pagopa_ric_doc_provc_id,
              pagopa_ric_doc_movgest_ts_id,
              pagopa_ric_doc_stato_elab,
              pagopa_ric_errore_id,
              pagopa_ric_id,
              pagopa_elab_flusso_id,
              file_pagopa_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              pagopa_ric_doc_ragsoc_benef,
              pagopa_ric_doc_nome_benef,
              pagopa_ric_doc_cognome_benef,
              pagopa_ric_doc_codfisc_benef,
              pagopa_ric_doc_soggetto_id,
              pagopa_ric_doc_flag_dett,
              pagopa_ric_doc_flag_con_dett,
              pagopa_ric_doc_tipo_code,
              pagopa_ric_doc_tipo_id,
              pagopa_ric_det_id,
              pagopa_ric_doc_iuv,
              pagopa_ric_doc_data_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              del.pagopa_ric_doc_id,
              del.pagopa_ric_doc_data,
              del.pagopa_ric_doc_voce_code,
              del.pagopa_ric_doc_voce_desc,
              del.pagopa_ric_doc_voce_tematica,
              del.pagopa_ric_doc_sottovoce_code,
              del.pagopa_ric_doc_sottovoce_desc,
              del.pagopa_ric_doc_sottovoce_importo,
              del.pagopa_ric_doc_anno_esercizio,
              del.pagopa_ric_doc_anno_accertamento,
              del.pagopa_ric_doc_num_accertamento,
              del.pagopa_ric_doc_num_capitolo,
              del.pagopa_ric_doc_num_articolo,
              del.pagopa_ric_doc_pdc_v_fin,
              del.pagopa_ric_doc_titolo,
              del.pagopa_ric_doc_tipologia,
              del.pagopa_ric_doc_categoria,
              del.pagopa_ric_doc_codice_benef,
              del.pagopa_ric_doc_str_amm,
              del.pagopa_ric_doc_subdoc_id,
              del.pagopa_ric_doc_provc_id,
              del.pagopa_ric_doc_movgest_ts_id,
              del.pagopa_ric_doc_stato_elab,
              del.pagopa_ric_errore_id,
              del.pagopa_ric_id,
              del.pagopa_elab_flusso_id,
              del.file_pagopa_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              del.pagopa_ric_doc_ragsoc_benef,
              del.pagopa_ric_doc_nome_benef,
              del.pagopa_ric_doc_cognome_benef,
              del.pagopa_ric_doc_codfisc_benef,
              del.pagopa_ric_doc_soggetto_id,
              del.pagopa_ric_doc_flag_dett,
              del.pagopa_ric_doc_flag_con_dett,
              del.pagopa_ric_doc_tipo_code,
              del.pagopa_ric_doc_tipo_id,
              del.pagopa_ric_det_id,
              del.pagopa_ric_doc_iuv,
              del.pagopa_ric_doc_data_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_riconciliazione_doc del
            where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
          	and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
	        and   del.pagopa_ric_doc_flag_con_dett=true
            returning pagopa_bck_ric_doc_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
            raise notice '%',strMessaggioLog;
            codResult:=null;
            insert into pagopa_t_elaborazione_log
            (
             pagopa_elab_id,
             pagopa_elab_file_id,
             pagopa_elab_log_operazione,
             ente_proprietario_id,
             login_operazione,
             data_creazione
            )
            values
            (
             filePagoPaElabId,
             null,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
            );
            GET DIAGNOSTICS codResult = ROW_COUNT;
          end if;


          strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true.';
          raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true - ';
          delete from pagopa_t_riconciliazione_doc del
          where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
          and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
          and   del.pagopa_ric_doc_flag_con_dett=true;
          GET DIAGNOSTICS codResult = ROW_COUNT;
          if codResult is null then codResult:=0; end if;
          raise notice 'cancellati=%',codResult;
          countDel:=countDel+codResult;

          strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
          raise notice '%',strMessaggioLog;
          codResult:=null;
          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );
          GET DIAGNOSTICS codResult = ROW_COUNT;
       end if;
      end if;





	  -- delete
      -- pagopa_t_elaborazione_flusso
      strMessaggio:='Verifica esistenza diversi dati di riconciliazione per lo stesso flusso-elaborazione-file [pagopa_t_elaborazione_flusso].';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=0;
      select coalesce(count(*),0)  into codResult
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id;
--      and   doc.pagopa_ric_id!=pagoPaRec.pagopa_ric_id;
      raise notice 'pagoPaRec.pagopa_elab_flusso_id=%',pagoPaRec.pagopa_elab_flusso_id;
      raise notice 'esistenti=%',codResult;
      if codresult=0 then
        if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
            strMessaggio:='Backup  pagopa_t_elaborazione_flusso.';
            raise notice 'strMessaggio= backup pagopa_t_elaborazione_flusso - ';
            codResult:=0;
            insert into pagopa_t_bck_elaborazione_flusso
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_flusso_id,
              pagopa_elab_flusso_data,
              pagopa_elab_flusso_stato_id,
              pagopa_elab_flusso_note,
              pagopa_elab_ric_flusso_id,
              pagopa_elab_flusso_nome_mittente,
              pagopa_elab_ric_flusso_data,
              pagopa_elab_flusso_tot_pagam,
              pagopa_elab_flusso_anno_esercizio,
              pagopa_elab_flusso_anno_provvisorio,
              pagopa_elab_flusso_num_provvisorio,
              pagopa_elab_flusso_provc_id,
              pagopa_elab_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              del.pagopa_elab_flusso_id,
              del.pagopa_elab_flusso_data,
              del.pagopa_elab_flusso_stato_id,
              del.pagopa_elab_flusso_note,
              del.pagopa_elab_ric_flusso_id,
              del.pagopa_elab_flusso_nome_mittente,
              del.pagopa_elab_ric_flusso_data,
              del.pagopa_elab_flusso_tot_pagam,
              del.pagopa_elab_flusso_anno_esercizio,
              del.pagopa_elab_flusso_anno_provvisorio,
              del.pagopa_elab_flusso_num_provvisorio,
              del.pagopa_elab_flusso_provc_id,
              del.pagopa_elab_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_elaborazione_flusso del
            where del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
            returning pagopa_bck_elab_flusso_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
            raise notice '%',strMessaggioLog;
            codResult:=null;
            insert into pagopa_t_elaborazione_log
            (
             pagopa_elab_id,
             pagopa_elab_file_id,
             pagopa_elab_log_operazione,
             ente_proprietario_id,
             login_operazione,
             data_creazione
            )
            values
            (
             filePagoPaElabId,
             null,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
            );
            GET DIAGNOSTICS codResult = ROW_COUNT;
        end if;

      	-- delete  pagopa_t_elaborazione_flusso
        strMessaggio:='Cancellazione pagopa_t_elaborazione_flusso.';
        raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_flusso - ';
        codResult:=0;
        delete from pagopa_t_elaborazione_flusso del where del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
      	raise notice 'cancellati=%',codResult;

      	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     	||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
      	raise notice '%',strMessaggioLog;
      	codResult:=null;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;

        strMessaggio:='Verifica esistenza diversi flussi per elaborazione-file [pagopa_r_elaborazione_file].';
        raise notice 'strMessaggio=%',strMessaggio;
        -- delete
        -- pagopa_r_elaborazione_file
        codResult:=0;
        select coalesce(count(*),0)  into codResult
        from pagopa_t_elaborazione_flusso flusso,pagopa_r_elaborazione_file rfile,
             pagopa_t_riconciliazione_doc doc,pagopa_t_riconciliazione ric
        where flusso.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_flusso_id!=pagoPaRec.pagopa_elab_flusso_id
        and   rfile.pagopa_elab_id=flusso.pagopa_elab_id
        and   rfile.file_pagopa_id=pagoPaRec.file_pagopa_id
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   ric.pagopa_ric_id=doc.pagopa_ric_id
        and   ric.file_pagopa_id=rfile.file_pagopa_id;
        raise notice 'esistenti=%',codResult;
        if codResult=0 then
          if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
            strMessaggio:='Backup  pagopa_r_elaborazione_file.';
            raise notice 'strMessaggio= backup pagopa_r_elaborazione_file - ';
            codResult:=0;
            insert into pagopa_r_bck_elaborazione_file
            (
              pagopa_elab_svecchia_id,
              pagopa_r_elab_id,
              pagopa_elab_id,
              file_pagopa_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              del.pagopa_r_elab_id,
              del.pagopa_elab_id,
              del.file_pagopa_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_r_elaborazione_file del
            where del.file_pagopa_id=pagoPaRec.file_pagopa_id
            and   del.pagopa_elab_id=pagoPaRec.pagopa_elab_id
            returning pagopa_bck_r_elab_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
            raise notice '%',strMessaggioLog;
            codResult:=null;
            insert into pagopa_t_elaborazione_log
            (
             pagopa_elab_id,
             pagopa_elab_file_id,
             pagopa_elab_log_operazione,
             ente_proprietario_id,
             login_operazione,
             data_creazione
            )
            values
            (
             filePagoPaElabId,
             null,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
            );
            GET DIAGNOSTICS codResult = ROW_COUNT;
          end if;

          strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
          raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
          -- delete pagopa_r_elaborazione_file
          delete from pagopa_r_elaborazione_file del
          where del.file_pagopa_id=pagoPaRec.file_pagopa_id
          and   del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
          GET DIAGNOSTICS codResult = ROW_COUNT;
          if codResult is null then codResult:=0; end if;
          raise notice 'cancellati=%',codResult;

          strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
          raise notice '%',strMessaggioLog;
          codResult:=null;
          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );
          GET DIAGNOSTICS codResult = ROW_COUNT;

        end if;

      end if;

      -- delete
	  -- pagopa_t_elaborazione
      strMessaggio:='Verifica esistenza relazioni con altri file per elaborazione [pagopa_r_elaborazione_file].';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=0;
      select coalesce(count(*),0) into codResult
      from pagopa_t_elaborazione  elab,pagopa_r_elaborazione_file r
      where elab.pagopa_elab_id=pagoPaRec.pagopa_elab_id
      and   r.pagopa_elab_id=elab.pagopa_elab_id;
      raise notice 'esistenti=%',codResult;
      if codResult = 0 then
        strMessaggio:='Verifica esistenza relazioni con altri flussi per elaborazione [pagopa_t_elaborazione_flusso].';
	    raise notice 'strMessaggio=%',strMessaggio;
        codResult:=0;
        select coalesce(count(*),0) into codResult
        from pagopa_t_elaborazione  elab,pagopa_t_elaborazione_flusso flusso
        where elab.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_flusso_id!=pagoPaRec.pagopa_elab_flusso_id;
        raise notice 'esistenti=%',codResult;

      end if;


      -- posso cancellare pagopa_t_elaborazione
      if codResult = 0 then

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
        ||strMessaggio
        ||' Inizio cancellazione pagopa_t_elaborazione. '
        ||strMessaggioFinale;

        raise notice '%',strMessaggioLog;
        codResult:=null;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;


		-- pagopa_bck_t_subdoc
    	strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_subdoc_attr
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_attr';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_attr del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_atto_amm
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_atto_amm';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_atto_amm del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_subdoc_prov_cassa
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_prov_cassa';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_prov_cassa del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_movgest_ts
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_movgest_ts';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_movgest_ts del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_stato
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_stato';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_stato del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_num
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_num';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_num del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_sog
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_sog';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_sog del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_doc_attr
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_attr';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_attr del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_class
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_class';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_class del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

        -- pagopa_bck_t_registrounico_doc
		strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_registrounico_doc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_registrounico_doc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

        -- delete pagopa_t_elaborazione_log
        strMessaggio:='Cancellazione dati elaborazione - pagopa_t_elaborazione_log';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_t_elaborazione_log del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

        if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
            strMessaggio:='Backup  pagopa_t_elaborazione.';
            raise notice 'strMessaggio= backup pagopa_t_elaborazione - ';
            codResult:=0;
            insert into pagopa_t_bck_elaborazione
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_id,
              pagopa_elab_data,
              pagopa_elab_stato_id,
              pagopa_elab_note,
              pagopa_elab_file_id,
              pagopa_elab_file_ora,
              pagopa_elab_file_ente,
              pagopa_elab_file_fruitore,
              file_pagopa_id,
              pagopa_elab_errore_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              del.pagopa_elab_id,
              del.pagopa_elab_data,
              del.pagopa_elab_stato_id,
              del.pagopa_elab_note,
              del.pagopa_elab_file_id,
              del.pagopa_elab_file_ora,
              del.pagopa_elab_file_ente,
              del.pagopa_elab_file_fruitore,
              del.file_pagopa_id,
              del.pagopa_elab_errore_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_elaborazione del
            where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id
            returning pagopa_bck_elab_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
            raise notice '%',strMessaggioLog;
            codResult:=null;
            insert into pagopa_t_elaborazione_log
            (
             pagopa_elab_id,
             pagopa_elab_file_id,
             pagopa_elab_log_operazione,
             ente_proprietario_id,
             login_operazione,
             data_creazione
            )
            values
            (
             filePagoPaElabId,
             null,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
            );
            GET DIAGNOSTICS codResult = ROW_COUNT;
          end if;

       	-- delete pagopa_t_elaborazione
        strMessaggio:='Cancellazione dati elaborazione - pagopa_t_elaborazione';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_t_elaborazione del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

 		strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                          ||' Fine cancellazione pagopa_t_elaborazione. '||strMessaggioFinale;
        raise notice '%',strMessaggioLog;
        codResult:=null;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;

      end if;

    end loop;



    codResult:=null;
    strMessaggio:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
                  ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                  ||'  pagopa_t_riconciliazione_doc. Chiusura elaborazione [pagopa_t_elaborazione_svecchia].';
    raise notice 'strMessaggio=%',strMessaggio;
    update pagopa_t_elaborazione_svecchia elab
    set    data_modifica=clock_timestamp(),
           validita_fine=clock_timestamp(),
           pagopa_elab_svecchia_note=
           upper('FINE '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar
           ||' Cancellati complessivamente '||coalesce(countDel,0)::varchar||' pagopa_t_riconciliazione_doc.')
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE
    and   elab.pagopa_elab_svecchia_id=pagopaElabSvecchiaId
    returning pagopa_elab_svecchia_id into codResult;
    if codResult is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in aggiornamento.'||strMessaggioFinale;
        return;
    end if;


    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
                          ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                          ||'  pagopa_t_riconciliazione_doc. '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
    codResult:=null;
    insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

    svecchiaPagoPaElabId:=pagopaElabSvecchiaId;
    codiceRisultato:=0;
    messaggioRisultato:='SVECCHIAMENTO TERMINATO - '
        ||' CANCELLATI COMPLESSIVAMENTE '||countDel::varchar||' pagopa_t_riconciliazione_doc.'
        ||upper(strMessaggioFinale);
    raise notice 'messaggioRisultato=%',messaggioRisultato;


    return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'') ;
       	codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
		messaggioRisultato:=upper(messaggioRisultato);
   		raise notice 'messaggioRisultato=%',messaggioRisultato;
		raise notice 'codiceRisultato=%',codiceRisultato;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
    	raise notice 'messaggioRisultato=%',messaggioRisultato;
		raise notice 'codiceRisultato=%',codiceRisultato;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
    	raise notice 'codiceRisultato=%',codiceRisultato;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
	    raise notice 'messaggioRisultato=%',messaggioRisultato;
        raise notice 'codiceRisultato=%',codiceRisultato;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;
	annoBilancio integer:=null;
    annoBilancio_ini integer:=null;

    filePagoPaElabId integer:=null;
    filePagoPaElabPrecId integer:=null;

    elabRec record;
    elabResRec record;
    annoRec record;
    elabEsecResRec record;

    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti


	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
	-- 18.01.2021 Sofia jira SIAC-7962
	ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo
	
	---- 28.10.2020 Sofia SIAC-7672
    elabSvecchiaRec record;
BEGIN

	strMessaggioFinale:='Elaborazione PAGOPA.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    outPagoPaElabPrecId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza elaborazione acquisita, in corso.';
    select 1 into codResult
    from pagopa_t_elaborazione pagopa, pagopa_d_elaborazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   pagopa.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is not null then
         outPagoPaElabId:=-1;
         outPagoPaElabPrecId:=-1;
         messaggioRisultato:=upper(strMessaggioFinale||' Elaborazione acquisita, in corso esistente.');
         strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	     insert into pagopa_t_elaborazione_log
         (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	     )
	     values
	     (
	      null,
	      strMessaggioLog,
	 	  enteProprietarioId,
     	  loginOperazione,
          clock_timestamp()
    	 );

         codiceRisultato:=-1;
    	 return;
    end if;




    annoBilancio:=extract('YEAR' from now())::integer;
    annoBilancio_ini:=annoBilancio;
    strMessaggio:='Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select 1 into codResult
    from siac_t_bil bil,siac_t_periodo per,
         siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where per.ente_proprietario_id=enteProprietarioid
    and   per.anno::integer=annoBilancio-1
    and   bil.periodo_id=per.periodo_id
    and   r.bil_id=bil.bil_id
    and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_id=r.fase_operativa_id
    -- 18.01.2021 Sofia jira SIAC-7962
--    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
    if codResult is not null then
    	annoBilancio_ini:=annoBilancio-1;
    end if;


    strMessaggio:='Verifica esistenza file da elaborare.';
    select 1 into codResult
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File da elaborare non esistenti.');
           codiceRisultato:=-1;
           strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	       insert into pagopa_t_elaborazione_log
           (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	       )
	       values
	       (
	        null,
	        strMessaggioLog,
	 	    enteProprietarioId,
     	    loginOperazione,
            clock_timestamp()
    	   );

           return;
    end if;

   codResult:=null;
   strMessaggio:='Inizio elaborazioni anni.';
   strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
   raise notice 'strMessaggioLog=%',strMessaggioLog;
   insert into pagopa_t_elaborazione_log
   (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
   )
   values
   (
    null,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   for annoRec in
   (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    where codiceRisultato=0
    order by 1
   )
   loop

    if annoRec.anno_elab>annoBilancio_ini then
    	filePagoPaElabPrecId:=filePagoPaElabId;
    end if;
    filePagoPaElabId:=null;
    strMessaggio:='Inizio elaborazione file PAGOPA per annoBilancio='||annoRec.anno_elab::varchar||'.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
    raise notice 'strMessaggioLog=%',strMessaggioLog;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

    for  elabRec in
    (
      select pagopa.*
      from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
      and   pagopa.file_pagopa_anno=annoRec.anno_elab
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null
      and   codiceRisultato=0
      order by pagopa.file_pagopa_id
    )
    loop
       strMessaggio:='Elaborazione File PAGOPA ID='||elabRec.file_pagopa_id||' Identificativo='||coalesce(elabRec.file_pagopa_code,' ')
                      ||' annoBilancio='||annoRec.anno_elab::varchar||'.';

       strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
       raise notice '1strMessaggioLog=%',strMessaggioLog;
	   insert into pagopa_t_elaborazione_log
   	   (
	      pagopa_elab_id,
          pagopa_elab_file_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	   )
	   values
	   (
    	null,
        elabRec.file_pagopa_id,
	    strMessaggioLog,
	    enteProprietarioId,
	    loginOperazione,
        clock_timestamp()
	   );
       raise notice '2strMessaggioLog=%',strMessaggioLog;

       select * into elabResRec
       from fnc_pagopa_t_elaborazione_riconc_insert
       (
          elabRec.file_pagopa_id,
          null,--filepagopaFileXMLId     varchar,
          null,--filepagopaFileOra       varchar,
          null,--filepagopaFileEnte      varchar,
          null,--filepagopaFileFruitore  varchar,
          filePagoPaElabId,
          annoRec.anno_elab,
          enteProprietarioId,
          loginOperazione,
          dataElaborazione
       );
              raise notice '2strMessaggioLog dopo=%',elabResRec.messaggiorisultato;

       if elabResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabResRec.codiceRisultato;
          strMessaggio:=elabResRec.messaggiorisultato;
       else
          filePagoPaElabId:=elabResRec.outPagoPaElabId;
       end if;

		raise notice 'codiceRisultato=%',codiceRisultato;
        raise notice 'strMessaggio=%',strMessaggio;
    end loop;

	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
    	strMessaggio:='Elaborazione documenti  annoBilancio='||annoRec.anno_elab::varchar
                      ||' Identificativo elab='||coalesce((filePagoPaElabId::varchar),' ')||'.';
        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
        raise notice 'strMessaggioLog=%',strMessaggioLog;
	    insert into pagopa_t_elaborazione_log
   	    (
	      pagopa_elab_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	    )
	    values
	    (
     	  filePagoPaElabId,
	      strMessaggioLog,
	      enteProprietarioId,
	      loginOperazione,
          clock_timestamp()
	    );

        select * into elabEsecResRec
       	from fnc_pagopa_t_elaborazione_riconc_esegui
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabEsecResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabEsecResRec.codiceRisultato;
          strMessaggio:=elabEsecResRec.messaggiorisultato;
        end if;
    end if;

    -- 28.10.2020 Sofia SIAC-7672 - inizio
	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
        select * into elabSvecchiaRec
       	from fnc_pagopa_t_elaborazione_riconc_svecchia_err
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabSvecchiaRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabSvecchiaRec.codiceRisultato;
          strMessaggio:=elabSvecchiaRec.messaggiorisultato;
        end if;
    end if;
    -- 28.10.2020 Sofia SIAC-7672 - fine

   end loop;

   if codiceRisultato=0 then
	    outPagoPaElabId:=filePagoPaElabId;
        outPagoPaElabPrecId:=filePagoPaElabPrecId;
    	messaggioRisultato:=upper(strMessaggioFinale||' TERMINE OK.');
   else
    	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
    	messaggioRisultato:=upper(strMessaggioFinale||'TERMINE KO.'||strMessaggio);
   end if;

   strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
   insert into pagopa_t_elaborazione_log
   (
    pagopa_elab_id,
    pagopa_elab_log_operazione,
    ente_proprietario_id,
    login_operazione,
    data_creazione
   )
   values
   (
    filePagoPaElabId ,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui (
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
    -- 18.01.2021 Sofia Jira SIAC-7962
    ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
    -- 06.02.2020 Sofia jira siac-7375
    docDataOperazione timestamp:=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '2222%',strMessaggioLog;
    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
    raise notice '2222strMessaggio  %',strMessaggio;
    raise notice '2222strMessaggio CodResult %',codResult;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
    raise notice '22229998@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
         raise notice '22229997@@%',strMessaggio;

	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     -- 18.01.2021 Sofia Jira SIAC-7962
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';
    raise notice '22229996@@%',strMessaggio;

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	  pagopa_ric_errore_id=err.pagopa_ric_errore_id,
              data_modifica=clock_timestamp(),
--               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
--          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
          login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
     raise notice 'strMessaggioStrErrore=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
     from  pagopa_r_elaborazione_file r,
           siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id,           -- siac-6720
          doc.pagopa_ric_doc_iuv     pagopa_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
          doc.pagopa_ric_doc_data_operazione pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id, -- siac-6720
            doc.pagopa_ric_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
            doc.pagopa_ric_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720
           pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
            pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;
		docIUV:=null;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );

         /* select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
             ),
             sogg as
             (
             select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
             from siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   sog.data_cancellazione is null
             and   sog.validita_fine is null
             )
             select pagopa.*,
                    sogg.soggetto_id,
                    sogg.soggetto_desc
             from pagopa
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
             ),
             accertamenti_sogg as
             (
             with
             accertamenti as
             (
              select mov.movgest_anno::integer, mov.movgest_numero::integer,
                     mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov , siac_d_movgest_tipo tipo,
                   siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.movgest_tipo_code='A'
              and   mov.movgest_tipo_id=tipo.movgest_tipo_id
              and   mov.bil_id=bilancioId
              and   ts.movgest_id=mov.movgest_id
              and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   tipots.movgest_ts_tipo_code='T'
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   stato.movgest_stato_id=rs.movgest_stato_id
              and   stato.movgest_stato_code='D'
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
             ),
             soggetto_acc as
             (
             select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
             from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   rsog.soggetto_id=sog.soggetto_id
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             )
             select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;*/

        -- 06.02.2020 Sofia jira siac-7375
        docIUV:=pagoPaFlussoRec.pagopa_doc_iuv;
        raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=pagoPaFlussoRec.pagopa_doc_data_operazione;
        raise notice 'IUUUUUUUUUV docDataOperazione=%',docDataOperazione;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'
                          ||lpad(extract ( month from dataElaborazione)::varchar,2,'0')
                          ||'-'||extract ( year from dataElaborazione)
                          -- ||' ' 20.04.2020 Sofia jira	SIAC-7586
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id,
            IUV, -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
            doc_data_operazione -- 06.02.2020 Sofia jira siac-7375
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV,   -- 12.08.2019 Sofia SIAC-6978 - fine
               docDataOperazione -- 06.02.2020 Sofia jira siac-7375
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
       end if;


	   if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
raise notice 'prima di quote berrore=%',berrore;
        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                 coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                             login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
--               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
--               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;
		raise notice 'dnumQuote %',dnumQuote;
	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                --login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar      -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                  coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar             -- 04.02.2020 Sofia SIAC-7375
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar          -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp()--, 26.08.2020 Sofia Jira SIAC-7747
         -- login_operazione=num.login_operazione||'-'||loginOperazione 26.08.2020 Sofia Jira SIAC-7747
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
--              login_operazione=file.login_operazione||'-'||loginOperazione
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) owner to siac;

alter function
siac.fnc_pagopa_t_elaborazione_riconc
(
 integer,
 varchar,
 timestamp,
 out integer,
 out integer,
 out integer,
 out varchar
) OWNER to siac;
-- Sofia - 17.12.2020

-- Sofia - 19.01.2021  - siac-7962
alter function
siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
   integer,
   integer,
   integer,
   varchar,
   timestamp,
   out  integer,
   out  varchar
) OWNER to siac;

-- 7672 fine   Haitham 17/12/2020

-- SIAC-7913 FL Inizio
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (
  id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  annocompetenza varchar,
  impegnatoEffettivo numeric
) AS
$body$

DECLARE
annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;
importoAttuale numeric:=0;
elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_A     constant varchar:='A';
STATO_P     constant varchar:='P';
TIPO_IMP    constant varchar:='I';
movGestStatoIdAnnullato integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTipoId integer:=0;
IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;
STATO_MOD_V  constant varchar:='V';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
importoCurAttuale numeric:=0;
esisteRmovgestidelemid INTEGER:=0;
impegniDaRibaltamento integer:=0;
pluriennaliDaRibaltamento integer:=0;
flagNMaggioreNPiu2 integer:=0;
importoImpegnato integer:=0;

strMessaggio varchar(1500):=null;
BEGIN


    strMessaggio:='Calcolo totale impegnato effettivo per elem_id='||id_in||'.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Lettura anno di bilancio del capitolo UP.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;


	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio di calcolato. Calcolo bilancioId e elem_tipo_code.';
	 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem,
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;

	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato. Calcolo fase operativa per bilancioId='||bilancioId||' , per ente='||enteProprietarioId||' e per elem_id='||id_in||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND THEN
	   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato effettivo elem_id='||id_in||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

	 strMessaggio:='Calcolo impegnato effettivo  competenza elem_id='||id_in||
				  '. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO'
				  '. Calcolo movGestTsStatoIdProvvisorio per movgest_stato_code=PROVVISORIO';

	 select movGestStato.movgest_stato_id into strict movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_P;

	 strMessaggio:='Calcolo impegnato effettivo competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT; --'A'

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||
				  '. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE; --'I'


	importoCurAttuale:=0;
	annoMovimento=anno_in;
	annoEsercizio=annoBilancio;

	strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';

	select bil.bil_id into strict bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.anno=annoEsercizio
	  and per.ente_proprietario_id=enteProprietarioId
	  and bil.periodo_id=per.periodo_id
	  and perTipo.periodo_tipo_id=per.periodo_tipo_id
	  and perTipo.periodo_tipo_code='SY';
	
    -- SIAC-7913 FL Inizio  
	  -- lettura elemIdGestEq
--	 strMessaggio:='Calcolo impegnato effettivo competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
--				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
--
--	 select bilelem.elem_id into elemIdGestEq
--	 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
--	 where bilElem.elem_code=elemCode
--	   and bilElem.elem_code2=elemCode2
--	   and bilElem.elem_code3=elemCode3
--	   and bilElem.ente_proprietario_id=enteProprietarioId
--	   and bilElem.data_cancellazione is null
--	   and bilElem.validita_fine is null
--	   and bilElem.bil_id=bilIdElemGestEq
--	   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
--	   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;
	   


--	if NOT FOUND THEN
--		impegnatoEffettivo:=0;
--	else
	-- SIAC-7913 FL Fine
		-- SIAC-7349 GS 16/07/2020 - INIZIO - Aggiunta la logica dei "ribaltamenti non presenti" usata nella function usata per il calcolo dell'impegnato della componente 
		-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
		--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione e anno movimento N e anno esercizio N
		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
		--		Sommatoria di tutti gli Impegni assunti sul capitolo in questione e anno movimento N e anno esercizio N-1 >>

		-- Verifica se presenti i movimenti di gestione provenienti dal ribaltamento
		-- Per "ribaltamento" si intende  il batch di ribaltamento residui che gira prima del ROR 
		--		e che "copia" gli impegni dell anno N-1 nel bilancio dell'anno N (di solito il 2 gennaio)
		-- Per verificare che il batch di ribaltamento sia stato eseguito controllo le seguenti tabelle
		-- 		fase_bil_t_gest_apertura_liq_imp per gli impegni residui
		--  	fase_bil_t_gest_apertura_pluri per i pluriennli (sia impegni che accertamenti)
		-- In entrambe si trova sia il bil_id che il bil_id_orig ovvero l'anno nuovo su cui si stanno ribaltando i movimenti e l'anno prec
		-- si trova anche un campo fl_elab che ti dice se i dati sono stati elaborati con scarto o con successo 
		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
					 '.Verifica se presenti i movimenti di gestione provenienti dal ribaltamento per anno di esercizio N.';

		impegniDaRibaltamento:=0;
		pluriennaliDaRibaltamento:=0;

		select  count(*) into impegniDaRibaltamento 
		from fase_bil_t_gest_apertura_liq_imp fb 
		where 
		fb.movgest_Ts_id is not null
		and fb.bil_id = bilIdElemGestEq
		and fb.data_cancellazione is null
		and fb.validita_fine is null;

		select  count(*) into  pluriennaliDaRibaltamento
		from fase_bil_t_gest_apertura_pluri fb 
		where 
		fb.movgest_Ts_id is not null
		and fb.bil_id = bilIdElemGestEq
		and fb.data_cancellazione is null
		and fb.validita_fine is null;

		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
						' impegniDaRibaltamento='||impegniDaRibaltamento||
						' pluriennaliDaRibaltamento='||pluriennaliDaRibaltamento||
						'.';

		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then

			-- - Se presenti i movimenti gestione provenienti dal ribaltamento:
			--	ImpegnatoDefinitivo = 	Sommatoria di tutti gli Impegni assunti sul capitolo in questione  
			--			e anno movimento [N | N+1 | N+2] e anno esercizio N

			annoEsercizio:=annoBilancio;
			annoMovimento:=annoMovimento;
		else

			-- - Se non presenti i movimenti gestione provenienti dal ribaltamento
			--	ImpegnatoDefinitivo = Sommatoria di tutti gli Impegni assunti sul capitolo in questione  
			-- 			e anno movimento [N | N+1 | N+2] e anno esercizio N-1 >>

			annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
			annoMovimento:=annoMovimento;
		end if;--SIAC-7913	
			-- Determina nuovamente i valori di bilIdElemGestEq e elemIdGestEq

			strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||'. Determina capitolo di gestione equivalente in anno esercizio calcolato.';
			select bil.bil_id into strict bilIdElemGestEq
			from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
			where per.anno=annoEsercizio
			  and per.ente_proprietario_id=enteProprietarioId
			  and bil.periodo_id=per.periodo_id
			  and perTipo.periodo_tipo_id=per.periodo_tipo_id
			  and perTipo.periodo_tipo_code='SY';

			 strMessaggio:='Calcolo impegnato effettivo competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
						  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

			 select bilelem.elem_id into elemIdGestEq
			 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
			 where bilElem.elem_code=elemCode
			   and bilElem.elem_code2=elemCode2
			   and bilElem.elem_code3=elemCode3
			   and bilElem.ente_proprietario_id=enteProprietarioId
			   and bilElem.data_cancellazione is null
			   and bilElem.validita_fine is null
			   and bilElem.bil_id=bilIdElemGestEq
			   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
			   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

	  --SIAC-7913 FL Inizio modifica 
		--end if;
	  if NOT FOUND THEN
		impegnatoEffettivo:=0;
	  else		
	  --SIAC-7913 FL Fine
		strMessaggio:='Calcolo totale impegnato  bilIdElemGestEq='||bilIdElemGestEq||
						' annoEsercizio='||annoEsercizio||
						' annoMovimento='||annoMovimento||
						'.';

		-- SIAC-7349 GS 16/07/2020 - FINE - Aggiunta la logica dei "ribaltamenti non presenti" usata nella function usata per il calcolo dell'impegnato della componente 
	
	
	
	
		strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||
						'. Verifica che esistano movimenti di gestione per il capitolo e per la componente.';
		select el.elem_id into esisteRmovgestidelemid
		from siac_r_movgest_bil_elem el, siac_t_movgest mv
		where
			mv.movgest_id=el.movgest_id
			and el.elem_id=elemIdGestEq
			and mv.movgest_anno=annoMovimento::integer;

		if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

		if esisteRmovgestidelemid <>0 then
 			impegnatoEffettivo:=0;
			strMessaggio:='Calcolo totale impegnato effettivo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq||
				'. Inizio calcolo totale importo attuale impegni per annoMovimento='||annoMovimento||'.';

			importoCurAttuale:=0;
			select tb.importo into importoCurAttuale
			from (
			  select
				  coalesce(sum(e.movgest_ts_det_importo),0) importo, c.movgest_ts_tipo_id
			  from
				  siac_r_movgest_bil_elem a,
				  siac_t_movgest b,
				  siac_t_movgest_ts c,
				  siac_r_movgest_ts_stato d,
				  siac_t_movgest_ts_det e,
				  siac_d_movgest_ts_det_tipo f
			  where
				  b.movgest_id=a.movgest_id and
				  a.elem_id=elemIdGestEq  -- UID del capitolo di gestione equivalente
				  and b.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				  and b.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
				  and d.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO
				  and d.movgest_stato_id<>movGestStatoIdProvvisorio -- non PROVVISORIO
				  and b.movgest_anno = annoMovimento::integer -- anno dell impegno = annoMovimento
				  and c.movgest_id=b.movgest_id
				  and d.movgest_ts_id=c.movgest_ts_id
				  and d.validita_fine is null
				  and e.movgest_ts_id=c.movgest_ts_id
				  and a.data_cancellazione is null
				  and b.data_cancellazione is null
				  and c.data_cancellazione is null
				  and e.data_cancellazione is null
				  and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
				  and e.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
				  group by c.movgest_ts_tipo_id) tb, siac_d_movgest_ts_tipo t
			where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
			order by t.movgest_ts_tipo_code desc
			limit 1;

			-- 02.02.2016 Sofia JIRA 2947
			 if importoCurAttuale is null then importoCurAttuale:=0; end if;

		end if;
	end if;-- siac-7913 era gia' presente ma chiede un altro if

 importoAttuale:=importoAttuale+importoCurAttuale; -- 16.03.2017 Sofia JIRA-SIAC-4614

 annoCompetenza:=anno_in;
 impegnatoEffettivo:=importoAttuale;

 return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar)
  OWNER TO siac;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac_rw;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO PUBLIC;

--GRANT EXECUTE ON FUNCTION siac.fnc_siac_impegnatoeffettivoup_comp_anno (id_in integer, anno_in varchar) TO siac;
-- SIAC-7913 FL Fine

--elimino i vecchi record sulla tabella di appoggio
--delete from siac_t_elaborazioni_attive where data_creazione < (now() - '1 week'::interval);
-- se ci fossero delle elaborazioni iniziate prima dello spegnimento del server, le invalido (i processi che le hanno generate sono ormai morti) indicando la morivazione
--update siac_t_elaborazioni_attive set data_cancellazione = now(), validita_fine = now(), login_operazione = login_operazione || ' - riavvio del server' where data_cancellazione is null;
-- FINE



