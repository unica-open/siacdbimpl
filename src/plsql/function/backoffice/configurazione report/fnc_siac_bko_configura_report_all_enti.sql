/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_configura_report_all_enti (
)
RETURNS void AS
$body$
DECLARE

/*function per aggiornare per tutti gli enti la tabella siac_t_report_importi dopo aver inserito i valori su bko_t_report_importi:

--1 insert

INSERT INTO
  siac.bko_t_report_importi
(
  rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga
)
values
('BILR001',
'Allegato 9 - Entrate: Riepilogo per Titolo - Tipologia (BILR001)',
'fpv_sc_prec',
'Anno Precedente - Fondo pluriennale vincolato per spese correnti ',
0,
'N',
'6');

--2 esecuzione function

select  * from fnc_siac_bko_configura_report_all_enti();

 */

rec record;

begin


for rec in 
select * from
siac_t_ente_proprietario
loop

perform fnc_siac_bko_configura_report_ente(rec.ente_proprietario_id);


end loop;



exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;

return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;