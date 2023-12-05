/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--siac-task-issues #87 - Maurizio - INIZIO

--Imposto la posizione delle variabili esistenti.
update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=1
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>1
and rep_imp.repimp_codice='ava_amm_sc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=2
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>2
and rep_imp.repimp_codice='rip_dis_prec'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=3
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>3
and rep_imp.repimp_codice='fpv_vinc_sc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=4
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>4
and rep_imp.repimp_codice='ent_est_prestiti_cc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=5
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>5
and rep_imp.repimp_codice='ent_est_prestiti'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=6
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>6
and rep_imp.repimp_codice='ent_disp_legge'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=7
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>7
and rep_imp.repimp_codice='di_cui_fondo_ant_liq_spese'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=8
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>8
and rep_imp.repimp_codice='di_cui_est_ant_pre'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=9
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>9
and rep_imp.repimp_codice='ava_amm_si'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=10
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>10
and rep_imp.repimp_codice='fpv_vinc_cc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=11
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>11
and rep_imp.repimp_codice='disava_pregr'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=12
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>12
and rep_imp.repimp_codice='ava_amm_af'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=13
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>13
and rep_imp.repimp_codice='fpv_incr_att_fin_inscr_ent'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=15
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>15
and rep_imp.repimp_codice='s_fpv_sc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=16
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>16
and rep_imp.repimp_codice='s_entrate_tit123_vinc_dest'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=17
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>17
and rep_imp.repimp_codice='s_entrate_tit123_ssn'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=18
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>18
and rep_imp.repimp_codice='s_spese_vinc_dest'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=19
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>19
and rep_imp.repimp_codice='s_fpv_pc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=20
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>20
and rep_imp.repimp_codice='s_sc_ssn'
and r_rep_imp.data_cancellazione IS NULL);
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
SELECT 'util_ris_amm_fin_spese_corr',
	'Utilizzo risultato di amministrazione destinato al finanziamento di spese correnti e al rimborso di prestiti al netto del Fondo anticipazione di liquidita''',
	NULL,
	'N',
	22,
	bil.bil_id,
    per2.periodo_id,
	now(),
	NULL,
	bil.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'siac-task-issue#87'
from  siac_t_bil bil, 
siac_t_periodo per, siac_d_periodo_tipo tipo_per,
siac_t_periodo per2, siac_d_periodo_tipo tipo_per2
where bil.periodo_id = per.periodo_id
and tipo_per.periodo_tipo_id=per.periodo_tipo_id
and per2.ente_proprietario_id=per.ente_proprietario_id
and tipo_per2.periodo_tipo_id=per2.periodo_tipo_id
and bil.ente_proprietario_id  in (2,4,5,10,11,14,16)
and per.anno::integer >= 2022  --anno di bilancio
and tipo_per.periodo_tipo_code='SY'
and per2.anno in (per.anno)  --anno della variabile
and tipo_per2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=bil.ente_proprietario_id 
	  and z.bil_id = bil.bil_id
	  and z.periodo_id = per2.periodo_id
      and z.repimp_codice='util_ris_amm_fin_spese_corr');

--Inserisco la nuova variabile in posizione 14.

      
      

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
where  d.rep_codice = 'BILR006'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
14 posizione_stampa, 
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'siac-task-issue#87' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('util_ris_amm_fin_spese_corr')
and c.anno::INTEGER>=2022
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR006'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));  
				

--correggo la descrizione di 2 variabili per i caratteri accentati.
update siac_t_report_importi
set repimp_desc='Utilizzo risultato presunto di amministrazione per il finanziamento di spese d''investimento',
	data_modifica=now(),
	login_operazione=login_operazione || ' - siac-task-issue#87'
where repimp_codice in('ava_amm_si')
and repimp_id in(select r_rep_imp.repimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.rep_codice='BILR006'
    and per.anno::INTEGER >= 2022);    

update siac_t_report_importi
set repimp_desc='Utilizzo risultato presunto di amministrazione al finanziamento di attivia'' finanziarie',
	data_modifica=now(),
	login_operazione=login_operazione || ' - siac-task-issue#87'
where repimp_codice in('ava_amm_af')
and repimp_id in(select r_rep_imp.repimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.rep_codice='BILR006'
    and per.anno::INTEGER >= 2022);    
	
--aggiorno la tabella di appoggio la configurazione delle variabili.
delete from bko_t_report_importi rep
where rep.rep_codice in('BILR006');

insert into bko_t_report_importi(
	rep_codice, rep_desc,  repimp_codice ,  repimp_desc,
  repimp_importo,  repimp_modificabile,  repimp_progr_riga, posizione_stampa)
select DISTINCT rep.rep_codice, rep.rep_desc, rep_imp.repimp_codice,
rep_imp.repimp_desc, case when rep_imp.repimp_codice ='util_ris_amm_fin_spese_corr' then NULL else 0 end, 
rep_imp.repimp_modificabile,
rep_imp.repimp_progr_riga, r_rep_imp.posizione_stampa
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
    and per.anno='2022'
    and rep.rep_codice in('BILR006')
    and rep.data_cancellazione IS NULL
    and rep_imp.data_cancellazione IS NULL
    and r_rep_imp.data_cancellazione IS NULL
	and not exists (select 1
				    from bko_t_report_importi
                    where rep_codice = rep.rep_codice
                    and repimp_codice=rep_imp.repimp_codice); 

					
					
--siac-task-issues #87 - Maurizio - FINE  