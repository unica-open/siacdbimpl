/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION fnc_migr_prov_cassa_ord_clean (
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

	strMessaggioFinale := 'Pulizia tabelle siac_r_ordinativo_prov_cassa .';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||'.';
        return;
    end if;

    begin

	-- o si cancella tutto cio che ?resente per ente oppure tutto quello che ?tato creato dall'utente passato
      strMessaggio := 'create migr_prov_cassa_ord_del.';
      
      execute 'DROP TABLE IF EXISTS migr_prov_cassa_ord_del;
      	
		create table migr_prov_cassa_ord_del as

        select ord_provc_id from siac_r_ordinativo_prov_cassa where
        login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and ord_provc_id >='||idmin||' and ord_provc_id<='||idmax||';
        
		alter table migr_prov_cassa_ord_del add primary key (ord_provc_id);
		
		ANALYZE migr_prov_cassa_ord_del;';

    	strMessaggio := 'create migr_prov_cassa_ord_del.';

    	
	   delete from siac_r_ordinativo_prov_cassa r  using migr_prov_cassa_ord_del tmp
	    where r.ord_provc_id = tmp.ord_provc_id
		and r.ente_proprietario_id = enteproprietarioid;

		
	exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';



    -- tabella di appoggio
    delete from siac_r_migr_prov_cassa_ordinativo_siac_r_ordinativo_prov_cassa r  
    where ente_proprietario_id = enteproprietarioid
    and r.ord_provc_id >= idmin and r.ord_provc_id<=idmax;

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