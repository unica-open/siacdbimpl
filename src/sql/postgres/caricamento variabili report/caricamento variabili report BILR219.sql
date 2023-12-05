/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*

select *
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR219'
    and a.ente_proprietario_id=2;
	
		ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	sono da INCLUDERE in questa configurazione.
	
	*/

INSERT INTO siac_t_report (
	rep_codice,  
	rep_desc,
  	rep_birt_codice ,
  	validita_inizio ,
  	validita_fine,
  	ente_proprietario_id,
  	data_creazione,
  	data_modifica,
  	data_cancellazione,
  	login_operazione)
SELECT 'BILR219',
	'All. 9 - Equilibri di Bilancio EELL Assestamento (BILR219)',
    'BILR219_Equilibri_bilancio_EELL_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where  a.data_cancellazione IS NULL
	and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR219');  
	  

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
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
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
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
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
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  


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
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

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
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');
	  


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
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
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
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

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
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
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
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
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
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
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
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
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
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
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
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
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
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
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
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

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
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  


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
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
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
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
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
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codicc,
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
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

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
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');

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
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
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
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

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
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
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
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
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
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
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
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
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
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
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
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
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
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
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
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

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
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  
	  


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
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
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
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
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
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  

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
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

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
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');

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
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
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
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidità (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2 b2iac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

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
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
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
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
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
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
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
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
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
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
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
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
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
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
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
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

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
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  
	  

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
where  d.rep_codice = 'BILR219'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and a.repimp_codice in ('A_assest',
'AA_assest',
'B_di_cui_assest',
'D_cui_fcde_assest',
'D_cui_fpv_assest',
'F_di_cui_ant_prest_assest',
'F_di_cui_fondo_assest',
'H_assest',
'H_di_cui_assest',
'I_assest',
'I_di_cui_assest',
'L_assest',
'M_assest',
'P_assest',
'Q_assest',
'U_di_cui_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR219', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR219');
    
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)    
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,0,
	b.repimp_modificabile, b.repimp_progr_riga
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR219'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);		  