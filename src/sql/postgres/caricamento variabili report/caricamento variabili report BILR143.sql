/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/* INSERIMENTO DEL REPORT BILR043 */
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
select 'BILR143',
       'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
       'BILR143_equilibri_di_finanza_pubblica',
       to_date('01/01/2016','dd/mm/yyyy'),
       null,
       a.ente_proprietario_id,
       now(),
       now(),
       null,
       'admin'
from siac_t_ente_proprietario a
where a.data_cancellazione is  null;

/* 1) configurazione delle variabile 'Fondo pluriennale vincolato di entrata in conto capitale  al netto delle quote finanziate da debito' */
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
select  'fpv_ecc_ncf',
        'Fondo pluriennale vincolato di entrata in conto capitale  al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';


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
select  'fpv_ecc_ncf',
        'Fondo pluriennale vincolato di entrata in conto capitale  al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'fpv_ecc_ncf',
        'Fondo pluriennale vincolato di entrata in conto capitale  al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
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
where  a.repimp_codice = 'fpv_ecc_ncf';


/* 2) configurazione delle variabile 'Fondo pluriennale vincolato di entrata per partite finanziarie' */
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
select  'fpv_epf',
        'Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'fpv_epf',
        'Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'fpv_epf',
        'Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
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
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
2 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'fpv_epf';



/* 3) configurazione delle variabile 'SPAZI FINANZIARI ACQUISITI ' */
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
select  'spazi_fin_acq',
        'SPAZI FINANZIARI ACQUISITI',
        0,
        'N',
        3,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'spazi_fin_acq',
        'SPAZI FINANZIARI ACQUISITI',
        0,
        'N',
        3,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'spazi_fin_acq',
        'SPAZI FINANZIARI ACQUISITI',
        0,
        'N',
        3,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
3 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'spazi_fin_acq';


/* 4) configurazione delle variabile ' Fondo contenzioso (destinato a confluire nel risultato di amministrazione)' */
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
select  'fondo_cont',
        'Fondo contenzioso (destinato a confluire nel risultato di amministrazione)',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'fondo_cont',
        'Fondo contenzioso (destinato a confluire nel risultato di amministrazione)',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'fondo_cont',
        'Fondo contenzioso (destinato a confluire nel risultato di amministrazione)',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
4 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'fondo_cont';


/* 5) configurazione delle variabile 'Altri accantonamenti (destinati a confluire nel risultato di amministrazione)' */
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
select  'altri_acc',
        'Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'altri_acc',
        'Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'altri_acc',
        'Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
        0,
        'N',
        5,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
5 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'altri_acc';


/* 6) configurazione delle variabile 'Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato' */
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
select  'spese_incr_att_fin',
        'Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato',
        0,
        'N',
        6,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'spese_incr_att_fin',
        'Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato',
        0,
        'N',
        6,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'spese_incr_att_fin',
        'Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato',
        0,
        'N',
        6,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
6 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'spese_incr_att_fin';




/* 7) configurazione delle variabile 'Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)' */
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
select  'fpv_part_fin',
        'Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        7,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'fpv_part_fin',
        'Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        7,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'fpv_part_fin',
        'Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
        0,
        'N',
        7,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
7 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'fpv_part_fin';


/* 8) configurazione delle variabile 'SPAZI FINANZIARI CEDUTI' */
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
select  'spazi_fin_ced',
        'SPAZI FINANZIARI CEDUTI',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2017'
and c2.periodo_tipo_code='SY';

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
select  'spazi_fin_ced',
        'SPAZI FINANZIARI CEDUTI',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno = '2018'
and c2.periodo_tipo_code='SY';


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
select  'spazi_fin_ced',
        'SPAZI FINANZIARI CEDUTI',
        0,
        'N',
        8,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2017'
and c.periodo_tipo_code='SY'
and  b2.anno ='2019' 
and c2.periodo_tipo_code='SY';


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
where  d.rep_codice = 'BILR143'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
8 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'spazi_fin_ced';