/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
select 'BILR147',
       'Allegato b – Fondo Pluriennale Vincolato (BILR147)',
       'BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend',
       to_date('01/01/2016','dd/mm/yyyy'),
       null,
       a.ente_proprietario_id,
       now(),
       now(),
       null,
       'mauri'
from siac_t_ente_proprietario a
where a.data_cancellazione is  null;

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
select  'IMPORTI FPV PER MISSIONE/PROGRAMMA ANNO PRECEDENTE',
        '',
        0,
        'S',
        1,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'mauri'
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
where  d.rep_codice = 'BILR147'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'mauri' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice = 'IMPORTI FPV PER MISSIONE/PROGRAMMA';

select *
from SIAC_T_REPORT_IMPORTI a
where a.repimp_codice= 'IMPORTI FPV PER MISSIONE/PROGRAMMA'

select d.rep_id,d.ente_proprietario_id
from   siac_t_report d
where  d.rep_codice = 'BILR147'

delete from SIAC_T_REPORT_IMPORTI
where repimp_codice= 'IMPORTI FPV PER MISSIONE/PROGRAMMA'