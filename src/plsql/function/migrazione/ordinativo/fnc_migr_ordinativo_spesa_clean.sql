/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_ordinativo_spesa_clean (
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
      strMessaggio := 'create migr_ordinativo_spesa_del.';
      
      execute 'DROP TABLE IF EXISTS migr_ordinativo_spesa_del;
      	create table migr_ordinativo_spesa_del as
        select ord_id from siac_t_ordinativo where
        login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||
        ' and ord_id >='||idmin||' and ord_id<='||idmax||';
        alter table migr_ordinativo_spesa_del add primary key (ord_id);
		ANALYZE migr_ordinativo_spesa_del;';

    	strMessaggio := 'create migr_ordinativo_spesa_del.';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';




   
   --siac_r_ordinativo_bil_elem
   delete from siac_r_ordinativo_bil_elem r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;


   --siac_r_ordinativo_atto_amm
   delete from siac_r_ordinativo_atto_amm r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;
    
   --siac_r_ordinativo_storno
   delete from siac_r_ordinativo_storno r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_attr
   delete from siac_r_ordinativo_attr r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_stato
   delete from siac_r_ordinativo_stato r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_firma
   delete from siac_r_ordinativo_firma r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_class
   delete from siac_r_ordinativo_class r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_soggetto
   delete from siac_r_ordinativo_soggetto r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_r_ordinativo_modpag
   delete from siac_r_ordinativo_modpag r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

   --siac_t_ordinativo
   delete from siac_t_ordinativo r  using migr_ordinativo_spesa_del tmp
    where r.ord_id = tmp.ord_id
    and r.ente_proprietario_id = enteproprietarioid;

    -- tabella di appoggio
    delete from siac_r_migr_ordinativo_spesa_ordinativo r  
    where ente_proprietario_id = enteproprietarioid
    and r.ord_id >= idmin and r.ord_id<=idmax;

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