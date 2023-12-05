/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_migr_provvedimento_clean (
  enteproprietarioid integer,
  loginoperazione varchar,
  idmin integer,
  idmax integer,
  out codresult varchar,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggioFinale VARCHAR(1500):='';
	v_count integer :=0;
    str_sql varchar(500):='';
begin
	strMessaggioFinale := 'Pulizia tabelle migrazione provvedimento da ['||idmin||'] a ['||idmax||'].';
    codResult := '0';

    if enteproprietarioid is null or loginoperazione is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid o loginoperazione Null ';
        return;
    end if;

    strMessaggioFinale := strMessaggioFinale || ' enteproprietarioid: '||enteproprietarioid;
    if loginoperazione is not null then
      strMessaggioFinale := strMessaggioFinale ||', loginoperazione: '||loginoperazione||'.';
    end if;

    if loginoperazione = '' then loginoperazione:= NULL; end if;

    delete from siac_r_atto_amm_stato r using siac_t_atto_amm t
    where
    t.attoamm_id>=idmin
    and t.attoamm_id <= idmax
    and t.ente_proprietario_id=enteproprietarioid::integer
    and t.login_operazione = loginoperazione
    and t.attoamm_id = r.attoamm_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete from siac_r_atto_amm_class r using siac_t_atto_amm t
    where
    t.attoamm_id>=idmin
    and t.attoamm_id <= idmax
    and t.ente_proprietario_id=enteproprietarioid::integer
    and t.login_operazione = loginoperazione
    and t.attoamm_id = r.attoamm_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete from siac_t_atto_amm t where
    t.attoamm_id>=idmin
    and t.attoamm_id <= idmax
    and t.login_operazione = loginoperazione
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete from siac_r_migr_provvedimento_attoamm r
	 where
     r.attoamm_id>=idmin
     and r.attoamm_id <= idmax
     and r.ente_proprietario_id = enteproprietarioid::integer;


    messaggiorisultato := strMessaggioFinale || 'Ok.';

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;