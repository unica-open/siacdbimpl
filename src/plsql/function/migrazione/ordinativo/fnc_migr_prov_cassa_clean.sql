/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION fnc_migr_prov_cassa_clean (
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

	strMessaggioFinale := 'Pulizia tabelle migr_prov_cassa_ord_clean .';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che ?resente per ente oppure tutto quello che ?tato creato dall'utente passato
      strMessaggio := 'create migr_prov_cassa_ord_del';
      
      execute 'DROP TABLE IF EXISTS migr_prov_cassa_del;
      	
		create table migr_prov_cassa_del as

        select provc_id from siac_t_prov_cassa where
        login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and provc_id >='||idmin||' and provc_id<='||idmax||';
        
		alter table migr_prov_cassa_del add primary key (provc_id);
		
		ANALYZE migr_prov_cassa_del;';

    	strMessaggio := 'create migr_prov_cassa_del.';

    	
	   delete from siac_t_prov_cassa r  using migr_prov_cassa_del tmp
	    where r.provc_id = tmp.provc_id
		and r.ente_proprietario_id = enteproprietarioid;

		
	exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

    -- tabella di appoggio
    delete from siac_r_migr_prov_cassa_prov_cassa r  
    where ente_proprietario_id = enteproprietarioid
    and r.provc_id >= idmin and r.provc_id<=idmax;

	messaggiorisultato := strMessaggioFinale || 'Ok.';

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codResult := '-1';
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;