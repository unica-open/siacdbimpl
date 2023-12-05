/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,
 rep_competenza_anni)
VALUES 
('BILR015', 3);


update BKO_T_REPORT_COMPETENZE
set rep_competenza_anni=3
where rep_codice='BILR015';

*/

INSERT INTO bko_t_report_importi
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR015',
 'Allegato D - Prospetto dimostrativo del rispetto dei vincoli di indebitamento (BILR015)',
 'ent_corr_nat_trib_tit1',
 '1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
 0,
 'N',
 12);
 

INSERT INTO bko_t_report_importi
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR015',
 'Allegato D - Prospetto dimostrativo del rispetto dei vincoli di indebitamento (BILR015)',
 'traf_correnti_tit2',
 '2) Trasferimenti correnti (titolo II)',
 0,
 'N',
 13);
 
 
 

INSERT INTO bko_t_report_importi
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
VALUES 
('BILR015',
 'Allegato D - Prospetto dimostrativo del rispetto dei vincoli di indebitamento (BILR015)',
 'ent_extratrib_tit3',
 '3) Entrate extratributarie (titolo III)',
 0,
 'N',
 14);
 
 