/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*INSERT INTO SIAC_T_REPORT (rep_codice,
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
where a.data_cancellazione is  null;*/

INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,
 rep_competenza_anni)
VALUES 
('BILR143', 3);
 
INSERT INTO bko_t_report_importi
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_ecc_ncf',
 'Fondo pluriennale vincolato di entrata in conto capitale  al netto delle quote finanziate da debito (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 1);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_epf',
 'Fondo pluriennale vincolato di entrata per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 2);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'spazi_fin_acq',
 'SPAZI FINANZIARI ACQUISITI',
 0,
 'N',
 3);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fondo_cont',
 'Fondo contenzioso (destinato a confluire nel risultato di amministrazione)',
 0,
 'N',
 4);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'altri_acc',
 'Altri accantonamenti (destinati a confluire nel risultato di amministrazione)',
 0,
 'N',
 5);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'spese_incr_att_fin',
 'Titolo 3 - Spese per incremento di attività finanziaria al netto del fondo pluriennale vincolato',
 0,
 'N',
 6);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'fpv_part_fin',
 'Fondo pluriennale vincolato per partite finanziarie (dal 2020 quota finanziata da entrate finali)',
 0,
 'N',
 7);
 
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR143',
 'Allegato 9 - Prospetto verifica rispetto dei vincoli di finanza pubblica (BILR143)',
 'spazi_fin_ced',
 'SPAZI FINANZIARI CEDUTI',
 0,
 'N',
 8);