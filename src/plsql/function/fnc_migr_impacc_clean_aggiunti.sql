/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_migr_impacc_clean_aggiunti (
  enteproprietarioid integer,
  loginoperazione varchar,
  loginoperazione_classif varchar,
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
	strMessaggioFinale := 'Pulizia tabelle migrazione impegni/accertamenti da ['||idmin||'] a ['||idmax||']';
    codResult := '0';

    if enteproprietarioid is null or loginoperazione_classif is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid o loginoperazione_classif Null ';
        return;
    end if;

    begin

      strMessaggioFinale := strMessaggioFinale || ' enteproprietarioid: '||enteproprietarioid;
      if loginoperazione is not null then
	strMessaggioFinale := strMessaggioFinale ||', loginoperazione: '||loginoperazione;
      end if;

      if loginoperazione = '' then loginoperazione:= NULL; end if;

      execute 'DROP TABLE IF EXISTS migr_movgest_del;
      	create table migr_movgest_del as
        select movgest_id from siac_t_movgest where login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
        and ente_proprietario_id = '||enteproprietarioid||' and movgest_id >='||idmin||' and movgest_id<='||idmax||';
        alter table migr_movgest_del add primary key (movgest_id);
		ANALYZE migr_movgest_del;';
      execute
          'DROP TABLE IF EXISTS migr_movgest_ts_del;
           create table migr_movgest_ts_del as select movgest_ts_id from siac_t_movgest_ts movgest_ts
           join migr_movgest_del movgest on (movgest_ts.movgest_id = movgest.movgest_id);
           alter table migr_movgest_ts_del add primary key (movgest_ts_id);
		   ANALYZE migr_movgest_ts_del;';
      execute
          'DROP TABLE IF EXISTS migr_movgestts_attoamm_del;
           create table migr_movgestts_attoamm_del as
           select movgest_atto_amm_id, attoamm_id from siac_r_movgest_ts_atto_amm r
           join migr_movgest_ts_del movgest_ts on (r.movgest_ts_id = movgest_ts.movgest_ts_id);
           alter table migr_movgestts_attoamm_del add primary key (movgest_atto_amm_id, attoamm_id);
		   ANALYZE migr_movgestts_attoamm_del;';
      execute
          'DROP TABLE IF EXISTS migr_movgest_class_del;
          create table migr_movgest_class_del as
          select distinct r.classif_id from siac_r_movgest_class r
          join migr_movgest_ts_del elem on (r.movgest_ts_id = elem.movgest_ts_id);
          alter table migr_movgest_class_del add primary key (classif_id);
		  ANALYZE migr_movgest_class_del;';

      -- saranno cancellati tutti i mutui per l''ente passato e la login operazione passata.
      execute
          'DROP TABLE IF EXISTS migr_mutuo_del;
          create table migr_mutuo_del as
          select mut_id from siac_t_mutuo t
          where login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
          and t.ente_proprietario_id = '||enteproprietarioid||';
          alter table migr_mutuo_del add primary key (mut_id);
		  ANALYZE migr_mutuo_del;';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggioFinale := strMessaggioFinale|| '.inizio delete.';

	delete
	from siac_r_movgest_ts_attr r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;	

	delete
	from siac_r_movgest_ts_stato r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;	

	delete
	from siac_t_movgest_ts_det r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;	

	delete
	from siac_r_movgest_ts_atto_amm r using migr_movgestts_attoamm_del tmp
	where r.movgest_atto_amm_id = tmp.movgest_atto_amm_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

-- fine delete voci di mutuo correlate

	delete
	from siac_r_movgest_class r using migr_movgest_class_del tmp
	where r.classif_id = tmp.classif_id
    and r.ente_proprietario_id=enteproprietarioid::integer;	
	
	delete
	from siac_t_movgest_ts t using migr_movgest_ts_del tmp
	where t.movgest_ts_id = tmp.movgest_ts_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_bil_elem r using migr_movgest_del tmp
	where r.movgest_id = tmp.movgest_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_t_movgest t using migr_movgest_del tmp
	where t.movgest_id = tmp.movgest_id
    and t.ente_proprietario_id=enteproprietarioid::integer;	
	
--pulire alla fine dell'elaborazione
	delete
	 from siac_r_migr_impegno_movgest_ts r using migr_movgest_ts_del tmp
	 where r.ente_proprietario_id = enteproprietarioid::integer
     and r.movgest_ts_id=tmp.movgest_ts_id;	 

	delete
	 from siac_r_migr_accertamento_movgest_ts r using migr_movgest_ts_del tmp
	 where r.ente_proprietario_id = enteproprietarioid::integer
     and r.movgest_ts_id=tmp.movgest_ts_id;
	 
	delete
	 from siac_r_migr_mutuo_t_mutuo r using migr_mutuo_del tmp
	 where r.ente_proprietario_id = enteproprietarioid::integer
     and r.mut_id=tmp.mut_id;

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
