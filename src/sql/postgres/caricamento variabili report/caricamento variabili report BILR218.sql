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
	and a.rep_codice='BILR218'
    and a.ente_proprietario_id=2;
	
ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	sono da escludere in questa configurazione.
	
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
SELECT 'BILR218',
	'All. 9 - All d) Limiti debito Regione Assestamento (BILR218)',
    'BILR218_Allegato_D_Limiti_indebitamento_regioni_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
	and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR218');    
	  

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
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
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
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

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
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

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
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
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
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
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
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

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
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

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
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

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
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

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
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

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
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
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
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');

	  

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
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
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
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

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
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

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
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
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
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
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
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

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
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

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
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

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
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

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
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

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
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
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
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');

	  

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
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
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
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

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
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

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
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
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
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
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
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

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
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

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
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

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
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

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
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

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
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
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
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
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
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');


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
where  d.rep_codice = 'BILR218'
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
where  a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
	and a.repimp_codice in ('amm_rate_prest_prec_assest',
	'amm_rate_prest_att_assest',
	'amm_rate_pot_deb_assest',
	'amm_rate_aut_legge_assest',
	'contr_erariali_assest',
	'amm_rate_debiti_assest',
	'deb_contratto_prec_assest',
	'deb_autoriz_att_assest',
	'deb_autoriz_legge_assest',
	'gar_princ_assest',
	'di_cui_gar_princ_assest',
	'garanzie_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR218', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR218');
    
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
	and a.rep_codice='BILR218'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);		  