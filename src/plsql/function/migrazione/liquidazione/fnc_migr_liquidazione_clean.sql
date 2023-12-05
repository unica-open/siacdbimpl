/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION fnc_migr_liquidazione_clean (
  enteproprietarioid integer,
  loginoperazione varchar,
  idMin integer,
  idMax integer,
  out codresult varchar,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	v_count integer :=0;
    str_sql varchar(500):='';
begin

	strMessaggioFinale := 'Pulizia tabelle liquidazione.';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che ?resente per ente oppure tutto quello che ?tato creato dall'utente passato
    	strMessaggio := 'create migr_liquidazione_del.';
      execute 'DROP TABLE IF EXISTS migr_liquidazione_del;
      	create table migr_liquidazione_del as
        select liq_id from siac_t_liquidazione where
        login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and liq_id >='||idmin||' and liq_id<='||idmax||';
        alter table migr_liquidazione_del add primary key (liq_id);
		ANALYZE migr_liquidazione_del;';

    	strMessaggio := 'create migr_liquidazione_del.';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

    delete from siac_r_mutuo_voce_liquidazione r  using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

    delete from siac_r_liquidazione_atto_amm r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

    delete from siac_r_liquidazione_movgest  r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

    delete from siac_r_liquidazione_soggetto  r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

    delete from siac_r_liquidazione_stato  r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

	delete from siac_r_liquidazione_class r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;

    delete from SIAC_R_SUBDOC_LIQUIDAZIONE r using migr_liquidazione_del tmp
    where r.liq_id = tmp.liq_id
    and r.ente_proprietario_id = enteproprietarioid;
	
    -- DAVIDE - 28.10.2016 - aggiunta delete mancante
    delete from SIAC_R_LIQUIDAZIONE_ATTR t using migr_liquidazione_del tmp
    where t.liq_id = tmp.liq_id
    and t.ente_proprietario_id = enteproprietarioid;	
	
    delete from siac_t_liquidazione t using migr_liquidazione_del tmp
    where t.liq_id = tmp.liq_id
    and t.ente_proprietario_id = enteproprietarioid;

    -- tabella di appoggio
    delete from siac_r_migr_liquidazione_t_liquidazione r  where ente_proprietario_id = enteproprietarioid
    and r.liquidazione_id >= idmin and r.liquidazione_id<=idmax;

	messaggiorisultato := strMessaggioFinale || 'Ok.';

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;