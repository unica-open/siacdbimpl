/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_configura_report_singolo (
rep_codice_in varchar 
)
RETURNS void AS
$body$
DECLARE

ciclo integer;
rec record;
competenza_anni integer;
login_operazione_loc text;

begin

login_operazione_loc:= 'fnc_siac_bko_configura_report';

delete from siac_r_report_importi where rep_id in (select rep_id from siac_t_report where rep_codice=rep_codice_in);
delete from siac_s_report_importi where repimp_id in (select repimp_id from siac_r_report_importi 
where rep_id in (select rep_id from siac_t_report where rep_codice=rep_codice_in));
delete from siac_t_report_importi where repimp_id in (select repimp_id from siac_r_report_importi 
where rep_id in (select rep_id from siac_t_report where rep_codice=rep_codice_in));


for rec in 
select * from siac_t_report 
where rep_codice_in=rep_codice_in and
data_cancellazione is null 
	loop


    --trovo competenza anni
    select 
    rep_competenza_anni into competenza_anni
    from bko_t_report_competenze where rep_codice=rec.rep_codice
    ;

      for i in 0 .. competenza_anni-1 
      loop



        --raise notice 'ente:% report :%', rec.ente_proprietario_id, rec.rep_codice;

        --raise notice 'i:%', i;

        INSERT INTO 
          siac.siac_t_report_importi
        (
          repimp_codice,
          repimp_desc,
          repimp_importo,
          repimp_modificabile,
          repimp_progr_riga,
          bil_id,
          periodo_id,
          validita_inizio,
          validita_fine,
          ente_proprietario_id,
          login_operazione
        )
        select distinct  
        bi.repimp_codice,
        bi.repimp_desc,
        bi.repimp_importo,
        bi.repimp_modificabile,
        bi.repimp_progr_riga, 
        bil.bil_id,
        per2.periodo_id,
        re.validita_inizio,
        re.validita_fine,
        re.ente_proprietario_id,
        login_operazione_loc
        from 
        bko_t_report_importi bi, siac_t_report re 
        ,siac_t_periodo per, siac_d_periodo_tipo pt,
        siac_t_bil bil
        , siac_t_periodo per2, siac_d_periodo_tipo pt2
        where 
        re.rep_codice=rep_codice_in and
        bi.rep_codice=re.rep_codice and
        per.ente_proprietario_id=re.ente_proprietario_id
        and pt.periodo_tipo_id=per.periodo_tipo_id
        and pt.periodo_tipo_code='SY'
        and per.periodo_id=bil.periodo_id
        and bil.data_cancellazione is null
        and bil.ente_proprietario_id=re.ente_proprietario_id
        and pt2.periodo_tipo_code='SY'
        and per2.ente_proprietario_id=per.ente_proprietario_id
        and pt2.periodo_tipo_id=per2.periodo_tipo_id
        and per2.anno::integer=per.anno::integer + i::integer
        and re.ente_proprietario_id=rec.ente_proprietario_id
        and re.rep_codice=rec.rep_codice
        and not exists (select 1 from siac_t_report_importi tt2 where
        tt2.repimp_codice=bi.repimp_codice and
        tt2.bil_id=bil.bil_id and
        tt2.periodo_id=per2.periodo_id and
        tt2.validita_inizio=re.validita_inizio and
        tt2.ente_proprietario_id=re.ente_proprietario_id )
        order by --re.rep_codice, 
        bil.bil_id,
        per2.periodo_id,
        bi.repimp_progr_riga,
        bi.repimp_codice;

	end loop;

end loop;

--inserico su R
INSERT INTO 
  siac.siac_r_report_importi
(
  rep_id,
  repimp_id,
  posizione_stampa,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select distinct re.rep_id,ri.repimp_id,1,ri.validita_inizio,ri.validita_fine,
ri.ente_proprietario_id, login_operazione_loc
from siac_t_report_importi ri, bko_t_report_importi ko, siac_t_report re
where re.rep_codice=ko.rep_codice
and ri.repimp_codice=ko.repimp_codice
and ri.ente_proprietario_id=re.ente_proprietario_id
and re.rep_codice=rep_codice_in
;


exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
--raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;