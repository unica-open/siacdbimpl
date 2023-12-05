/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_elencoDocAllegati_clean (
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

	strMessaggioFinale := 'Pulizia tabelle elenco doc allegati da ['||idmin||'] a ['||idmax||'].';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||quote_nullable(enteproprietarioid)||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che è presente per ente oppure tutto quello che è stato creato dall'utente passato
    	strMessaggio := 'create migr_elencoDocAllegati_del.';
      execute 'DROP TABLE IF EXISTS migr_elencoDocAllegati_del;
      	create table migr_elencoDocAllegati_del as
        select eldoc_id from siac_t_elenco_doc where
        login_creazione=COALESCE('||quote_nullable(loginoperazione)||', login_creazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and eldoc_id>='||idmin||' and eldoc_id<='||idmax||';
        alter table migr_elencoDocAllegati_del add primary key (eldoc_id);
		ANALYZE migr_elencoDocAllegati_del;';

    	strMessaggio := 'create migr_elencoDocAllegati_del.';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

	delete from siac_r_atto_allegato_elenco_doc r using migr_elencoDocAllegati_del tmp
    where r.eldoc_id=tmp.eldoc_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_elenco_doc_stato r using migr_elencoDocAllegati_del tmp
    where r.eldoc_id=tmp.eldoc_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_elenco_doc_subdoc r using migr_elencoDocAllegati_del tmp
    where r.eldoc_id=tmp.eldoc_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_t_elenco_doc t using migr_elencoDocAllegati_del tmp
    where t.eldoc_id=tmp.eldoc_id
    and t.ente_proprietario_id=enteproprietarioid;

    -- tabella di appoggio
    delete from siac_r_migr_elenco_doc_all_t_elenco_doc r using migr_elencoDocAllegati_del tmp
    where r.eldoc_id=tmp.eldoc_id
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