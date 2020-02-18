/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_atto_allegato_clean (
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
    str_sql varchar(500):='';
begin

	strMessaggioFinale := 'Pulizia tabelle atto allegato da ['||idmin||'] a ['||idmax||'].';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||quote_nullable(enteproprietarioid)||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che è presente per ente oppure tutto quello che è stato creato dall'utente passato
    	strMessaggio := 'create migr_atto_allegato_del.';
      execute 'DROP TABLE IF EXISTS migr_atto_allegato_del;
      	create table migr_atto_allegato_del as
        select attoal_id from siac_t_atto_allegato where
        login_creazione=COALESCE('||quote_nullable(loginoperazione)||', login_creazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and attoal_id>='||idmin||' and attoal_id<='||idmax||';
        alter table migr_atto_allegato_del add primary key (attoal_id);
		ANALYZE migr_atto_allegato_del;';

	-- DAVIDE - 21.10.2016 - aggiunta migr_atto_allegato_stampa_del
	 -- elenco atto_allegato_stampa_id da cancellare (legati all'elemento)
	  execute
        'DROP TABLE IF EXISTS migr_atto_allegato_stampa_del;
          create table migr_atto_allegato_stampa_del as
          select r.attoalst_id from siac_t_atto_allegato_stampa r
          join migr_atto_allegato_del doc
          on (r.attoal_id = doc.attoal_id);
          ALTER TABLE migr_atto_allegato_stampa_del ADD PRIMARY KEY (attoalst_id);
          ANALYZE migr_atto_allegato_stampa_del;';
	-- DAVIDE - 21.10.2016 - aggiunta migr_atto_allegato_stampa_del - Fine
		  
    	strMessaggio := 'create migr_atto_allegato_del.';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

	delete from siac_r_atto_allegato_elenco_doc r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_atto_allegato_stato r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id=enteproprietarioid;

	-- DAVIDE - 21.10.2016 - aggiunte queste delete 
	delete from siac_r_atto_allegato_stampa_file r using migr_atto_allegato_stampa_del tmp
    where r.attoalst_id=tmp.attoalst_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_allegato_atto_stampa_stato r using migr_atto_allegato_stampa_del tmp
    where r.attoalst_id=tmp.attoalst_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_t_atto_allegato_stampa r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id=enteproprietarioid;
	-- DAVIDE - 21.10.2016 - aggiunte queste delete - Fine

	delete from siac_t_atto_allegato t using migr_atto_allegato_del tmp
    where t.attoal_id=tmp.attoal_id
    and t.ente_proprietario_id=enteproprietarioid;

    -- tabella di appoggio
    delete from siac_r_migr_atto_all_t_atto_allegato r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id = enteproprietarioid;

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