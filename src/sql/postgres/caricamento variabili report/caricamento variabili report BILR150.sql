/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* INSERIMENTO DEL REPORT BILR150 */
INSERT INTO SIAC_T_REPORT (rep_codice,
                           rep_desc,
                           rep_birt_codice,
                           validita_inizio,
                           validita_fine,
                           ente_proprietario_id,
                           data_creazione,
                           data_modifica,
                           data_cancellazione,
                           login_operazione)
select 'BILR150',
       'Allegato a) Risultato di amministrazione (BILR150)',
       'BILR150_prosp_dimos_ris_amm',
       to_date('01/01/2016','dd/mm/yyyy'),
       null,
       a.ente_proprietario_id,
       now(),
       now(),
       null,
       'admin'
from siac_t_ente_proprietario a
where a.data_cancellazione is  null;



/*
Giï¿½ esistenti:

Fondo crediti di dubbia esigibilitï¿½ al 31/12/ï¿½. (4)
Accantonamento residui perenti al 31/12/ï¿½. (solo per le regioni)  (5)
Fondo anticipazioni liquiditï¿½ DL 35 del 2013 e successive modifiche e rifinanziamenti
Fondo  perdite societï¿½ partecipate
Fondo contezioso
Altri accantonamenti

Codici:
ACCANT_FONDO_CREDITI
ACCANT_RESIDUI_PERENTI
ACCANT_FONDO_ANTICIP
ACCANT_FONDO_PERDITE
ACCANT_FONDO_CONTENZ
ACCANT_ALTRI


Vincoli derivanti da leggi e dai principi contabili
Vincoli derivanti da trasferimenti
Vincoli derivanti dalla contrazione di mutui 
Vincoli formalmente attribuiti dall'ente 
Altri vincoli 

Codici:
VINCOL_ALTRI
VINCOL_DA_LEGGI
VINCOL_DA_MUTUI
VINCOL_DA_TRASF
VINCOL_ATTR_ENTE



Parte Investimenti - Totale destinata agli investimenti

Codici:
INVEST_TOTALE

NUOVE:
PAGAMENTI per azioni esecutive non regolarizzate al 31 dicembre
   di cui derivanti da accertamenti di tributi effettuati sulla base della stima del dipartimento delle finanze
   
   
*/

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
      select distinct
      (select d.rep_id
      from   siac_t_report d
      where  d.rep_codice = 'BILR150'
      and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
       a.repimp_id,
      1 posizione_stampa,
      to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
      null::timestamp validita_fine,
      a.ente_proprietario_id ente_proprietario_id,
      now() data_creazione,
      now() data_modifica,
      null::timestamp  data_cancellazione,
      'admin' login_operazione
      from   siac_t_report_importi a, siac_r_report_importi b,
      		siac_t_report c, siac_t_ente_proprietario d,            
          siac_t_bil t_bil, 
          siac_t_periodo bb, siac_d_periodo_tipo cc,
          siac_t_periodo b2, siac_d_periodo_tipo c2                                                  
      where  a.repimp_id=b.repimp_id
      and b.rep_id=c.rep_id
      and d.ente_proprietario_id=a.ente_proprietario_id
      and t_bil.periodo_id = bb.periodo_id
        and cc.periodo_tipo_id=bb.periodo_tipo_id
        and b2.ente_proprietario_id=bb.ente_proprietario_id
        and c2.periodo_tipo_id=b2.periodo_tipo_id
        and t_bil.ente_proprietario_id=d.ente_proprietario_id
        and a.periodo_id=bb.periodo_id
        and a.bil_id=t_bil.bil_id
        and   bb.anno = '2016'
        and cc.periodo_tipo_code='SY'
        and  b2.anno = '2016'
        and c2.periodo_tipo_code='SY'  
	  and a.repimp_codice IN('ACCANT_FONDO_CREDITI','ACCANT_RESIDUI_PERENTI',
'ACCANT_FONDO_ANTICIP','ACCANT_FONDO_PERDITE','ACCANT_FONDO_CONTENZ',
'ACCANT_ALTRI', 'VINCOL_ALTRI','VINCOL_DA_LEGGI','VINCOL_DA_MUTUI',
'VINCOL_DA_TRASF','VINCOL_ATTR_ENTE','INVEST_TOTALE')
      		and c.rep_codice='BILR013'
            and a.data_cancellazione is null
            and b.data_cancellazione is null
            and c.data_cancellazione is null  
            and d.data_cancellazione is null         
          and a.repimp_id not in (select repimp_id 
          						from SIAC_R_REPORT_IMPORTI aa,
                                	siac_t_report bb
                                where aa.rep_id=bb.rep_id
                                	and bb.rep_codice = 'BILR150'
                                	and aa.data_cancellazione is null
                                    and bb.data_cancellazione is null) ;
									
									
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
      select distinct
      (select d.rep_id
      from   siac_t_report d
      where  d.rep_codice = 'BILR150'
      and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
       a.repimp_id,
      1 posizione_stampa,
      to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
      null::timestamp validita_fine,
      a.ente_proprietario_id ente_proprietario_id,
      now() data_creazione,
      now() data_modifica,
      null::timestamp  data_cancellazione,
      'admin' login_operazione
      from   siac_t_report_importi a, siac_r_report_importi b,
      		siac_t_report c, siac_t_ente_proprietario d,            
          siac_t_bil t_bil, 
          siac_t_periodo bb, siac_d_periodo_tipo cc,
          siac_t_periodo b2, siac_d_periodo_tipo c2                                                  
      where  a.repimp_id=b.repimp_id
      and b.rep_id=c.rep_id
      and d.ente_proprietario_id=a.ente_proprietario_id
      and t_bil.periodo_id = bb.periodo_id
        and cc.periodo_tipo_id=bb.periodo_tipo_id
        and b2.ente_proprietario_id=bb.ente_proprietario_id
        and c2.periodo_tipo_id=b2.periodo_tipo_id
        and t_bil.ente_proprietario_id=d.ente_proprietario_id
        and a.periodo_id=bb.periodo_id
        and a.bil_id=t_bil.bil_id
        and   bb.anno = '2017'
        and cc.periodo_tipo_code='SY'
        and  b2.anno = '2017'
        and c2.periodo_tipo_code='SY'  
	  and a.repimp_codice IN('ACCANT_FONDO_CREDITI','ACCANT_RESIDUI_PERENTI',
'ACCANT_FONDO_ANTICIP','ACCANT_FONDO_PERDITE','ACCANT_FONDO_CONTENZ',
'ACCANT_ALTRI', 'VINCOL_ALTRI','VINCOL_DA_LEGGI','VINCOL_DA_MUTUI',
'VINCOL_DA_TRASF','VINCOL_ATTR_ENTE','INVEST_TOTALE')
      		and c.rep_codice='BILR013'
            and a.data_cancellazione is null
            and b.data_cancellazione is null
            and c.data_cancellazione is null  
            and d.data_cancellazione is null         
          and a.repimp_id not in (select repimp_id 
          						from SIAC_R_REPORT_IMPORTI aa,
                                	siac_t_report bb
                                where aa.rep_id=bb.rep_id
                                	and bb.rep_codice = 'BILR150'
                                	and aa.data_cancellazione is null
                                    and bb.data_cancellazione is null) ;
									
 
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
select  'pagam_azioni_esecutive',
        'PAGAMENTI per azioni esecutive non regolarizzate al 31 dicembre',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2016'
and c.periodo_tipo_code='SY'
and  b2.anno = '2016'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null;       

 
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
select  'pagam_azioni_esecutive',
        'PAGAMENTI per azioni esecutive non regolarizzate al 31 dicembre',
        0,
        'N',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null;       
									

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
where  d.rep_codice = 'BILR150'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'pagam_azioni_esecutive';									
									
									
 
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
select  'di_cui_da_accertamenti',
        '   di cui derivanti da accertamenti di tributi effettuati sulla base della stima del dipartimento delle finanze',
        0,
        'N',
        2,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2016'
and c.periodo_tipo_code='SY'
and  b2.anno = '2016'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null;     


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
select  'di_cui_da_accertamenti',
        '   di cui derivanti da accertamenti di tributi effettuati sulla base della stima del dipartimento delle finanze',
        0,
        'N',
        2,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, siac_t_ente_proprietario a2,
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id=a2.ente_proprietario_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and a2.data_cancellazione is null;       									



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
where  d.rep_codice = 'BILR150'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'di_cui_da_accertamenti';