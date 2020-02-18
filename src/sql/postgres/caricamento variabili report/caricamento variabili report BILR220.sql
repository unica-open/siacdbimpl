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
	and a.rep_codice='BILR220'
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
SELECT 'BILR220',
	'All. 9 - All d) Limiti debito EELL (BILR220)',
    'BILR220_Allegato_D_Limiti_indebitamento_EELL_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
	and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR220');  
	  

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
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
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
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
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
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
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
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
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
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
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
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
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
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
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
      and z.repimp_codice='inter_anno_prec_assest');

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
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
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
      and z.repimp_codice='inter_anno_assest');
	  
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
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
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
      and z.repimp_codice='contr_erariali1_assest');
	  
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
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
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
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
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
      and z.repimp_codice='deb_anno_prec_assest');
	  
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
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
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
      and z.repimp_codice='deb_aut_anno_assest');
	  
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
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='garanzie_prin_assest');
	  
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
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='di_cui_garanzie_assest');
	  
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
SELECT 'garanzie_lim_assest',
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
      and z.repimp_codice='garanzie_lim_assest');	  
	  
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
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
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
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
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
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
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
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
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
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
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
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
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
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
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
      and z.repimp_codice='inter_anno_prec_assest');

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
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
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
      and z.repimp_codice='inter_anno_assest');
	  
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
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
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
      and z.repimp_codice='contr_erariali1_assest');
	  
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
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
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
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
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
      and z.repimp_codice='deb_anno_prec_assest');
	  
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
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
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
      and z.repimp_codice='deb_aut_anno_assest');
	  
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
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='garanzie_prin_assest');
	  
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
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='di_cui_garanzie_assest');
	  
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
SELECT 'garanzie_lim_assest',
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
      and z.repimp_codice='garanzie_lim_assest');
	  
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
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
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
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
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
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
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
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
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
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
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
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
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
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
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
      and z.repimp_codice='inter_anno_prec_assest');

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
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
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
      and z.repimp_codice='inter_anno_assest');
	  
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
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
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
      and z.repimp_codice='contr_erariali1_assest');
	  
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
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
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
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
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
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
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
      and z.repimp_codice='deb_anno_prec_assest');
	  
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
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
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
      and z.repimp_codice='deb_aut_anno_assest');
	  
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
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='garanzie_prin_assest');
	  
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
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
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
      and z.repimp_codice='di_cui_garanzie_assest');
	  
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
SELECT 'garanzie_lim_assest',
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
      and z.repimp_codice='garanzie_lim_assest');
	  
	  
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
where  d.rep_codice = 'BILR220'
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
where a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and a.repimp_codice in ('ent_corr_nat_trib_tit1_assest',
'traf_correnti_tit2_assest',
'ent_extratrib_tit3_assest',
'inter_anno_prec_assest',
'inter_anno_assest',
'contr_erariali1_assest',
'inter_deb_esclusi_assest',
'deb_anno_prec_assest',
'deb_aut_anno_assest',
'garanzie_prin_assest',
'di_cui_garanzie_assest',
'garanzie_lim_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR220', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR220');
    
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
	and a.rep_codice='BILR220'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);		  	  