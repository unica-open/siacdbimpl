/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* aggiornamento  record per PARTE ACCANTONATA */
update siac_t_report_importi 
set repimp_codice='ACCANT_FONDO_CREDITI',
	repimp_desc='Parte Accantonata - Fondo crediti di dubbia esigibilità al',
	repimp_progr_riga=11,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=1
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');
    
update siac_t_report_importi 
set repimp_codice='ACCANT_RESIDUI_PERENTI',
	repimp_desc='Parte Accantonata - Accantonamento residui perenti al 2015',
	repimp_progr_riga=12,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=2
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');  
	
	
update siac_t_report_importi 
set repimp_codice='ACCANT_FONDO_ANTICIP',
	repimp_desc='Parte Accantonata - Fondo anticipazioni liquidità DL 35 del 2013 e successive modifiche e rifinanziamenti',
	repimp_progr_riga=13,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=3
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
update siac_t_report_importi 
set repimp_codice='ACCANT_FONDO_PERDITE',
	repimp_desc='Parte Accantonata - Fondo perdite società partecipate',
	repimp_progr_riga=14,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=4
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    

update siac_t_report_importi 
set repimp_codice='ACCANT_FONDO_CONTENZ',
	repimp_desc='Parte Accantonata - Fondo contenzioso',
	repimp_progr_riga=15,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=5
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    

update siac_t_report_importi 
set repimp_codice='ACCANT_ALTRI',
	repimp_desc='Parte Accantonata - Altri accantonamenti',
	repimp_progr_riga=16,
    repimp_modificabile='N',
	data_modifica = now()
where repimp_codice='PARTE ACCANTONATA'
    and repimp_progr_riga=6
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
/* caricamento record per PARTE VINCOLATA */
update siac_t_report_importi 
set repimp_codice='VINCOL_DA_LEGGI',
	repimp_desc='Parte Vincolata - Vincoli derivanti da leggi e dai principi contabili',
	repimp_progr_riga=17,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE VINCOLATA'
    and repimp_progr_riga=1
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
    
update siac_t_report_importi 
set repimp_codice='VINCOL_DA_TRASF',
	repimp_desc='Parte Vincolata - Vincoli derivanti da trasferimenti',
	repimp_progr_riga=18,
    repimp_modificabile='N',
	data_modifica = now()
where repimp_codice='PARTE VINCOLATA'
    and repimp_progr_riga=2
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
    
update siac_t_report_importi 
set repimp_codice='VINCOL_DA_MUTUI',
	repimp_desc='Parte Vincolata - Vincoli derivanti dalla contrazione di mutui',
	repimp_progr_riga=19,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE VINCOLATA'
    and repimp_progr_riga=3
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
        
update siac_t_report_importi 
set repimp_codice='VINCOL_ATTR_ENTE',
	repimp_desc='Parte Vincolata - Vincoli formalmente attribuiti dall''ente',
	repimp_progr_riga=20,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE VINCOLATA'
    and repimp_progr_riga=4
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
        
update siac_t_report_importi 
set repimp_codice='VINCOL_ALTRI',
	repimp_desc='Parte Vincolata - Altri Vincoli',
	repimp_progr_riga=21,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='PARTE VINCOLATA'
    and repimp_progr_riga=5
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
	/* caricamento record per PARTE INVESTIMENTI */
update siac_t_report_importi 
set repimp_codice='INVEST_TOTALE',
	repimp_desc='Parte Investimenti - Totale destinata agli investimenti',
	repimp_progr_riga=22,
    repimp_modificabile='N',
	data_modifica = now()
where repimp_codice='PARTE INVESTIMENTI'
    and repimp_progr_riga=1	
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
/* caricamento record per UTILIZZO QUOTA VINCOLATA */
update siac_t_report_importi 
set repimp_codice='QUOTA_VINC_LEGGI',
	repimp_desc='Utilizzo quota vincolata - Utilizzo vincoli derivanti da leggi e dai principi contabili',
	repimp_progr_riga=23,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='UTILIZZO QUOTA VINCOLATA'
    and repimp_progr_riga=1	
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
update siac_t_report_importi 
set repimp_codice='QUOTA_VINC_TRASF',
	repimp_desc='Utilizzo quota vincolata - Utilizzo vincoli derivanti da trasferimenti',
	repimp_progr_riga=24,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='UTILIZZO QUOTA VINCOLATA'
    and repimp_progr_riga=2	
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    	
	
update siac_t_report_importi 
set repimp_codice='QUOTA_VINC_MUTUI',
	repimp_desc='Utilizzo quota vincolata - Utilizzo vincoli derivanti dalla contrazione di mutui',
	repimp_progr_riga=25,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='UTILIZZO QUOTA VINCOLATA'
    and repimp_progr_riga=3			
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
update siac_t_report_importi 
set repimp_codice='QUOTA_VINC_ENTE',
	repimp_desc='Utilizzo quota vincolata - Utilizzo vincoli formalmente attribuiti dall''ente',
	repimp_progr_riga=26,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='UTILIZZO QUOTA VINCOLATA'
    and repimp_progr_riga=4			
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
	
update siac_t_report_importi 
set repimp_codice='QUOTA_VINC_ALTRI',
	repimp_desc='Utilizzo quota vincolata - Utilizzo altri vincoli',
	repimp_progr_riga=27,
    repimp_modificabile='N',
	data_modifica = now()
where  repimp_codice='UTILIZZO QUOTA VINCOLATA'
    and repimp_progr_riga=5			
    and repimp_id in (select b.repimp_id
    	from siac_t_report a,
        	siac_r_report_importi b
        where b.rep_id=a.rep_id
        	and a.rep_codice='BILR013');    
			


/* CANCELLAZIONE dei record inseriti e REINSERIMENTO nell'ordine in cui devono essere visualizzati */
/*
select a.* from siac_t_report_importi a,  siac_t_report b, siac_r_report_importi
c
where a.repimp_id=c.repimp_id
and b.rep_id=c.rep_id
and b.rep_codice='BILR013'
and a.ente_proprietario_id=5
order by a.repimp_progr_riga*/

UPDATE
  siac.siac_t_report_importi
SET
  data_cancellazione = now(),
  login_operazione = 'ADEGUAMENTO BDAP'
WHERE
	data_cancellazione IS NULL AND
  repimp_id in
  (
      select a.repimp_id from siac_t_report_importi a,  siac_t_report b,
			siac_r_report_importi c
      where a.repimp_id=c.repimp_id
      and b.rep_id=c.rep_id
      and b.rep_codice='BILR013'	  
    --  and a.ente_proprietario_id=5
      --and a.repimp_modificabile='N'
      --and a.bil_id=157
      order by a.repimp_progr_riga
  );
 
UPDATE
  siac.siac_r_report_importi
SET
  data_cancellazione = now(),
  login_operazione = 'ADEGUAMENTO BDAP'
WHERE
	data_cancellazione IS NULL AND
  reprimp_id in (
      select c.reprimp_id from siac_t_report_importi a,  siac_t_report b,
siac_r_report_importi c
      where a.repimp_id=c.repimp_id
      and b.rep_id=c.rep_id
      and b.rep_codice='BILR013'
     -- and a.ente_proprietario_id=5
      --and a.repimp_modificabile='N'
      --and a.bil_id=157
      order by a.repimp_progr_riga
  );
 

INSERT INTO
  siac.siac_t_report_importi
(
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga,
  bil_id,
  periodo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select a.repimp_codice, a.repimp_desc, a.repimp_importo, a.repimp_modificabile,
a.repimp_progr_riga, a.bil_id,
a.periodo_id, a.validita_inizio, a.ente_proprietario_id,
'ADEGUAMENTO BDAP' from siac_t_report_importi a,  siac_t_report b,
siac_r_report_importi c
where a.repimp_id=c.repimp_id
and b.rep_id=c.rep_id
and b.rep_codice='BILR013'
--and a.ente_proprietario_id=5
and a.repimp_modificabile='N'
and a.login_operazione= 'ADEGUAMENTO BDAP'
--and a.bil_id=157
order by a.repimp_progr_riga;


INSERT INTO
  siac.siac_r_report_importi
(
  rep_id,
  repimp_id,
  posizione_stampa,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select a.rep_id, b.repimp_id, 1, b.validita_inizio, a.ente_proprietario_id,
'ADEGUAMENTO BDAP' from siac_t_report a, siac_t_report_importi b
where a.rep_codice = 'BILR013'
--and a.ente_proprietario_id=5
and b.login_operazione= 'ADEGUAMENTO BDAP'
and b.data_cancellazione is null;
			