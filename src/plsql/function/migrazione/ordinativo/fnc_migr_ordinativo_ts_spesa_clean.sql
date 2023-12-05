/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_migr_ordinativo_ts_spesa_clean (
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
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	v_count integer :=0;
    str_sql varchar(1500):='';
begin

	strMessaggioFinale := 'Pulizia tabelle ordinativo.';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che ?resente per ente oppure tutto quello che ?tato creato dall'utente passato
      strMessaggio := 'create migr_ordinativo_ts_spesa_del.';
      
      execute 'DROP TABLE IF EXISTS migr_ordinativo_ts_spesa_del;
      	create table migr_ordinativo_ts_spesa_del as
        select ord_ts_id from siac_t_ordinativo_ts where
        login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||
		'and ord_id in (select j.ord_id from siac_t_ordinativo j
                       where j.ente_proprietario_id='||enteproprietarioid||
                              'and j.ord_tipo_id in (select r.ord_tipo_id 
                        from siac_d_ordinativo_tipo r 
                       where r.ente_proprietario_id='||enteproprietarioid|| 
                         'and r.ord_tipo_code=''P''))'||
        ' and ord_ts_id >='||idmin||' and ord_ts_id<='||idmax||';
        alter table migr_ordinativo_ts_spesa_del add primary key (ord_ts_id);
		ANALYZE migr_ordinativo_ts_spesa_del;';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';


	strMessaggio := 'cancello siac_r_liquidazione_ord con idmin='||idmin ||' idmax='||idmax||'.';

	delete from siac_r_liquidazione_ord r  using migr_ordinativo_ts_spesa_del tmp
    where r.sord_id = tmp.ord_ts_id
    and r.ente_proprietario_id = enteproprietarioid;

	strMessaggio := 'cancello siac_t_ordinativo_ts_det con idmin='||idmin ||' idmax='||idmax||'.';

	delete from siac_t_ordinativo_ts_det r  using migr_ordinativo_ts_spesa_del tmp
    where r.ord_ts_id = tmp.ord_ts_id
    and r.ente_proprietario_id = enteproprietarioid;
    
    /*strMessaggio := 'cancello SIAC_R_SUBDOC_ORDINATIVO_TS con idmin='||idmin ||' idmax='||idmax||'.';
	delete from SIAC_R_SUBDOC_ORDINATIVO_TS r  using migr_ordinativo_ts_spesa_del tmp
    where r.ord_ts_id = tmp.ord_ts_id
    and r.ente_proprietario_id = enteproprietarioid;*/

    
    strMessaggio := 'cancello siac_t_ordinativo_ts con idmin='||idmin ||' idmax='||idmax||'.';
	delete from siac_t_ordinativo_ts r  using migr_ordinativo_ts_spesa_del tmp
    where r.ord_ts_id = tmp.ord_ts_id
    and r.ente_proprietario_id = enteproprietarioid;


	strMessaggio := 'cancello siac_r_migr_ordinativo_ts_spesa_ordinativo con idmin='||idmin ||' idmax='||idmax||'.';
    -- tabella di appoggio
    delete from siac_r_migr_ordinativo_ts_spesa_ordinativo r  
    where ente_proprietario_id = enteproprietarioid
    and r.ord_ts_id >= idmin and r.ord_ts_id<=idmax;

	strMessaggio := 'fine cancellazione tabelle ts ordinativo  con idmin='||idmin ||' idmax='||idmax||' loginoperazione='||loginoperazione||' ente='||enteproprietarioid;

	messaggiorisultato := strMessaggioFinale ||strMessaggio|| 'Ok.';

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 3500) ;
        codResult := '-1';
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;