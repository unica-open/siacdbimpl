/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
 loginoperazione : valorizzato se da procedura si vogliono cancellare solo i record inseriti da un determinato utente (quello di migrazione)
 loginoperazione_classif: è l'utente di migrazione, usato nella delete delle tabelle di decodifica.
*/
CREATE OR REPLACE FUNCTION fnc_migr_impacc_clean (
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
		  'DROP TABLE IF EXISTS migr_movgestts_attoamm_allegato_del;
           create table migr_movgestts_attoamm_allegato_del as
           select distinct t.attoal_id, t.attoamm_id from SIAC_T_ATTO_ALLEGATO t
           join migr_movgestts_attoamm_del atto_del on (t.attoamm_id = atto_del.attoamm_id);
           alter table migr_movgestts_attoamm_allegato_del add primary key (attoal_id, attoamm_id);
		   ANALYZE migr_movgestts_attoamm_allegato_del;';
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
		  
-- Modifiche Impegni / Accertamenti
/*      execute 'DROP TABLE IF EXISTS migr_movgest_ts_det_mod_del;
      	create table migr_movgest_ts_det_mod_del as select movgest_ts_det_mod_id, mod_stato_r_id from siac_t_movgest_ts_det_mod movgest_ts_det_mod
        join migr_movgest_ts_del movgest on (movgest_ts_det_mod.movgest_ts_id = movgest.movgest_ts_id);
        alter table migr_movgest_ts_det_mod_del add primary key (movgest_ts_det_mod_id);
		ANALYZE migr_movgest_ts_det_mod_del;';

      execute 'DROP TABLE IF EXISTS migr_modifica_stato_del;
      	create table migr_modifica_stato_del as select r_modifica_stato.mod_stato_r_id, mod_id from siac_r_modifica_stato r_modifica_stato
        join migr_movgest_ts_det_mod_del movgest on (r_modifica_stato.mod_stato_r_id = movgest.mod_stato_r_id);
        alter table migr_modifica_stato_del add primary key (mod_stato_r_id);
		ANALYZE migr_modifica_stato_del;';

      execute 'DROP TABLE IF EXISTS migr_modifica_del;
      	create table migr_modifica_del as select modifica.mod_id from siac_t_modifica modifica
        join migr_modifica_stato_del movgest on (modifica.mod_id = movgest.mod_id);
        alter table migr_modifica_del add primary key (mod_id);
		ANALYZE migr_modifica_del;';*/

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    --strMessaggioFinale := strMessaggioFinale|| '.inizio delete.';

-- nota: la cancellazione dell'atto amministrativo potrebbe non avvenire per presenza di record figli nella tab siac_t_modifica
-- queste le fk della tabela:
/*siac_r_movgest_ts_sogclasse_mod --> siac_r_movgest_ts_sogclasse per movgest_ts_sogclasse_id
									  siac_t_movgest_ts	    	  per movgest_ts_id
									  siac_r_modifica_stato	      per mod_stato_r_id
										--> siac_t_modifica per mod_id
											--> siac_t_atto_amm	 per atto_amm_id*/

	delete from siac_r_movgest_ts_sogclasse_mod r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_ts_sogclasse r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

-- basterà???
-- nota: la cancellazione dell'atto amministrativo potrebbe non avvenire per presenza di record figli nella tab siac_t_modifica
-- queste le fk della tabela:
/*siac_r_movgest_ts_sog_mod --> siac_r_movgest_ts_sog per movgest_ts_sog_id
							  siac_t_movgest_ts	    per movgest_ts_id
							  siac_r_modifica_stato	per mod_stato_r_id
									--> siac_t_modifica per mod_id
										--> siac_t_atto_amm	 per atto_amm_id
*/
	delete
	from siac_r_movgest_ts_sog_mod r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_ts_sog r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_ts_programma r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_ts_attr r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_ts_stato r using migr_movgest_ts_del movgest_ts_del
	where r.movgest_ts_id = movgest_ts_del.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

--strMessaggioFinale := strMessaggioFinale|| '1.';
-- basterà???
-- nota: la cancellazione dell'atto amministrativo potrebbe non avvenire per presenza di record figli nella tab siac_t_modifica
-- queste le fk della tabela:
/*
siac_t_movgest_ts_det_mod --> siac_t_movgest_ts			per movgest_ts_id
								siac_t_movegest_ts_det	per movgest_ts_det_id
								siac_r_modifica_stato	per mod_stato_r_id
									--> siac_t_modifica per mod_id
										--> siac_t_atto_amm	 per atto_amm_id
*/

	delete
    from siac_t_movgest_ts_det_mod r using migr_movgest_ts_del movgest_ts_del
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

	delete
	from siac_r_atto_amm_class r using migr_movgestts_attoamm_del tmp
	where r.attoamm_id = tmp.attoamm_id and
	not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			where r2.attoamm_id = r.attoamm_id)
    and not exists (select 1 from siac_t_cassa_econ_operaz r3 -- 10.12.2015 Sofia
              where r3.attoamm_id=r.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;

	 delete
	  from siac_r_atto_amm_stato r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
      and not exists (select 1 from siac_t_cassa_econ_operaz r3 -- 10.12.2015 Sofia
              where r3.attoamm_id=r.attoamm_id )
      and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '2.';
--12.03.2015 nuove delete
	 delete
	  from SIAC_R_PROGRAMMA_ATTO_AMM r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
      and r.ente_proprietario_id=enteproprietarioid::integer;

    delete
	  from SIAC_R_MODIFICA_STATO r using siac_t_modifica t
      where r.mod_id = t.mod_id
      and exists (select 1 from migr_movgestts_attoamm_del tmp
      	where t.attoamm_id=tmp.attoamm_id )
     and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	  from siac_t_modifica t using migr_movgestts_attoamm_del tmp
	  where t.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where t.attoamm_id = r2.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete
	  from SIAC_R_LIQUIDAZIONE_ATTO_AMM r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	  from siac_r_ordinativo_atto_amm r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	  from SIAC_R_SUBDOC_ATTO_AMM r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
      from SIAC_R_ATTO_ALLEGATO_ELENCO_DOC r using migr_movgestts_attoamm_allegato_del tmp
	  where r.attoal_id = tmp.attoal_id
      and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
    		  where tmp.attoamm_id = r2.attoamm_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '3.';
	delete
      from SIAC_R_ATTO_ALLEGATO_STATO r using migr_movgestts_attoamm_allegato_del tmp
	  where r.attoal_id = tmp.attoal_id
      and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
    		  where tmp.attoamm_id = r2.attoamm_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete
	  from siac_t_atto_allegato t using migr_movgestts_attoamm_allegato_del tmp
	  where t.attoamm_id = tmp.attoamm_id
      and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
    		  where t.attoamm_id = r2.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete
	  from SIAC_R_MUTUO_ATTO_AMM r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete
      	from siac_t_cartacont_estera t using SIAC_T_CARTACONT t2
        where t.cartac_id = t2.cartac_id and
        exists (select 1 from migr_movgestts_attoamm_del tmp
        		where t2.attoamm_id = tmp.attoamm_id)
		and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where t2.attoamm_id = r2.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete
      	from SIAC_R_CARTACONT_DET_SUBDOC r using siac_t_cartacont_det t
        where r.cartac_det_id = t.cartac_det_id
        and exists (
        	select 1 from SIAC_T_CARTACONT t2
            where t.cartac_id = t2.cartac_id and
        		exists (select 1 from migr_movgestts_attoamm_del tmp
        				where t2.attoamm_id = tmp.attoamm_id)
				and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  			where t2.attoamm_id = r2.attoamm_id )
                        )
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete
      	from SIAC_R_CARTACONT_DET_MODPAG r using siac_t_cartacont_det t
        where r.cartac_det_id = t.cartac_det_id
        and exists (
        	select 1 from SIAC_T_CARTACONT t2
            where t.cartac_id = t2.cartac_id and
        		exists (select 1 from migr_movgestts_attoamm_del tmp
        				where t2.attoamm_id = tmp.attoamm_id)
				and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  			where t2.attoamm_id = r2.attoamm_id )
                        )
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '4.';
    delete
      	from SIAC_R_CARTACONT_DET_SOGGETTO r using siac_t_cartacont_det t
        where r.cartac_det_id = t.cartac_det_id
        and exists (
        	select 1 from SIAC_T_CARTACONT t2
            where t.cartac_id = t2.cartac_id and
        		exists (select 1 from migr_movgestts_attoamm_del tmp
        				where t2.attoamm_id = tmp.attoamm_id)
				and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  			where t2.attoamm_id = r2.attoamm_id )
                        )
    and r.ente_proprietario_id=enteproprietarioid::integer;
    -- altri record di questa tabella cancellati dopo...
	delete
      	from SIAC_R_CARTACONT_DET_MOVGEST_TS r using siac_t_cartacont_det t
        where r.cartac_det_id = t.cartac_det_id
        and exists (
        	select 1 from SIAC_T_CARTACONT t2
            where t.cartac_id = t2.cartac_id and
        		exists (select 1 from migr_movgestts_attoamm_del tmp
        				where t2.attoamm_id = tmp.attoamm_id)
				and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  			where t2.attoamm_id = r2.attoamm_id )
                        )
    and r.ente_proprietario_id=enteproprietarioid::integer;


	delete
      	from SIAC_R_CARTACONT_DET_ATTR r using siac_t_cartacont_det t
        where r.cartac_det_id = t.cartac_det_id
        and exists (
        	select 1 from SIAC_T_CARTACONT t2
            where t.cartac_id = t2.cartac_id and
        		exists (select 1 from migr_movgestts_attoamm_del tmp
        				where t2.attoamm_id = tmp.attoamm_id)
				and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  			where t2.attoamm_id = r2.attoamm_id )
                        )
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete
      	from siac_t_cartacont_det t using SIAC_T_CARTACONT t2
        where t.cartac_id = t2.cartac_id and
        exists (select 1 from migr_movgestts_attoamm_del tmp
        		where t2.attoamm_id = tmp.attoamm_id)
		and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where t2.attoamm_id = r2.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;
    delete
      	from siac_r_cartacont_stato r using SIAC_T_CARTACONT t
        where r.cartac_id = t.cartac_id and
        exists (select 1 from migr_movgestts_attoamm_del tmp
        		where t.attoamm_id = tmp.attoamm_id)
		and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where t.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;
    delete
      	from siac_r_cartacont_attr r using SIAC_T_CARTACONT t
        where r.cartac_id = t.cartac_id and
        exists (select 1 from migr_movgestts_attoamm_del tmp
        		where t.attoamm_id = tmp.attoamm_id)
		and not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where t.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;
	delete
      from SIAC_T_CARTACONT r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;
	delete
      from SIAC_R_PREDOC_ATTO_AMM r using migr_movgestts_attoamm_del tmp
	  where r.attoamm_id = tmp.attoamm_id and
	  not exists (select 1 from siac_r_movgest_ts_atto_amm r2
			  where r.attoamm_id = r2.attoamm_id )
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '5.';
	delete
      from SIAC_R_CAUSALE_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '5.a';
	delete
      from SIAC_R_SUBDOC_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale|| '5.b';
	delete
	  from SIAC_R_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_a_id = tmp.movgest_ts_id or r.movgest_ts_b_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '5.c';
    delete
	  from SIAC_R_PREDOC_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '5.d';
    delete
      from SIAC_R_LIQUIDAZIONE_MOVGEST r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '5.e';
	delete
      from SIAC_R_ORDINATIVO_TS_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

--strMessaggioFinale := strMessaggioFinale|| '5.f';
    -- altri record di questa tabella cancellati prima...
	delete
      	from SIAC_R_CARTACONT_DET_MOVGEST_TS r using migr_movgest_ts_del tmp
	where r.movgest_ts_id = tmp.movgest_ts_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

--strMessaggioFinale := strMessaggioFinale|| '5.g';
	delete
      	from SIAC_R_RICHIESTA_ECON_MOVGEST r using migr_movgest_del tmp
	where r.movgest_ts_id = tmp.movgest_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--strMessaggioFinale := strMessaggioFinale|| '6.';
--
-- delete voci di mutuo correlate 17.04.2015
	delete from siac_r_mutuo_voce_movgest r
    where exists (select 1 from siac_t_mutuo_voce v, migr_mutuo_del tmp
    			  where v.mut_id=tmp.mut_id
                  and v.mut_voce_id=r.mut_voce_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete from siac_r_mutuo_voce_liquidazione r
    where exists (select 1 from siac_t_mutuo_voce v, migr_mutuo_del tmp
    			  where v.mut_id=tmp.mut_id
                  and v.mut_voce_id=r.mut_voce_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

	-- 21.10.2015 pulizia tabella di relazione migrazione/siac
	delete
	 from siac_r_migr_voce_mutuo_t_mutuo_voce r using siac_t_mutuo_voce t
	 where r.ente_proprietario_id = enteproprietarioid::integer
     and t.mut_voce_id=r.mut_voce_id
     and t.ente_proprietario_id = enteproprietarioid::integer
     and exists (select 1 from migr_mutuo_del tmp where tmp.mut_id=t.mut_id);

    delete from siac_t_mutuo_voce t using migr_mutuo_del tmp
    where t.mut_id=tmp.mut_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

    delete from siac_r_mutuo_atto_amm r using migr_mutuo_del tmp
    where r.mut_id=tmp.mut_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete from siac_r_mutuo_soggetto r using migr_mutuo_del tmp
    where r.mut_id=tmp.mut_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

    delete from siac_r_mutuo_stato r using migr_mutuo_del tmp
    where r.mut_id=tmp.mut_id
    and r.ente_proprietario_id=enteproprietarioid::integer;


    delete from siac_t_mutuo t using migr_mutuo_del tmp
    where t.mut_id=tmp.mut_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
-- 11.12.2015 Sofia
-- da verificare se dobbiamo cancellare anche queste tabelle
-- SIAC_T_CASSA_ECON_OPERAZ ( ha il campo attoamm_id che se collegato ad impegno / accertamento richiede cancellazione )
-- siac_r_cassa_econ_operaz_stampa
-- siac_r_cassa_econ_operaz_stato
-- siac_r_cassa_econ_operaz_tipo

-- fine delete voci di mutuo correlate

-- 15.10.2016 Davide
    delete
	from siac_r_variazione_stato t using migr_movgestts_attoamm_del tmp
	where t.attoamm_id = tmp.attoamm_id
	and not exists (select 1 from  siac_r_movgest_ts_atto_amm r where r.attoamm_id = T.attoamm_id)
    and not exists (select 1 from siac_r_mutuo_atto_amm r where r.attoamm_id=T.attoamm_id)
    and not exists (select 1 from siac_t_cassa_econ_operaz r3 
                 where r3.attoamm_id=t.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;

    delete
	from siac_t_atto_amm t using migr_movgestts_attoamm_del tmp
	where t.attoamm_id = tmp.attoamm_id
	and not exists (select 1 from  siac_r_movgest_ts_atto_amm r where r.attoamm_id = T.attoamm_id)
    and not exists (select 1 from siac_r_mutuo_atto_amm r where r.attoamm_id=T.attoamm_id)
    and not exists (select 1 from siac_t_cassa_econ_operaz r3 -- 10.12.2015 Sofia
                 where r3.attoamm_id=t.attoamm_id )
    and t.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_r_movgest_class r using migr_movgest_class_del tmp
	where r.classif_id = tmp.classif_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

	delete
	from siac_t_class t using migr_movgest_class_del tmp
	where t.classif_id = tmp.classif_id and
	not exists (select 1 from siac_r_movgest_class r
		  where r.classif_id = t.classif_id) and
		t.login_operazione = loginoperazione_classif
    and t.ente_proprietario_id=enteproprietarioid::integer;
	
-- Modifiche Impegni / Accertamenti	
	/*delete
	from siac_t_movgest_ts_det_mod t using migr_movgest_ts_det_mod_del tmp
	where t.movgest_ts_det_mod_id = tmp.movgest_ts_det_mod_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
	
	delete
	from siac_r_modifica_stato t using migr_modifica_stato_del tmp
	where t.mod_stato_r_id = tmp.mod_stato_r_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
	
	delete
	from siac_t_modifica t using migr_modifica_del tmp
	where t.mod_id = tmp.mod_id
    and t.ente_proprietario_id=enteproprietarioid::integer;*/
	
	-- DAVIDE - 11.07.2016 - inserita clean per collegamenti Impegni / Accertamenti
	delete
	from siac_r_movgest_ts t using migr_movgest_ts_del tmp
	where (t.movgest_ts_a_id = tmp.movgest_ts_id or 
	       t.movgest_ts_b_id = tmp.movgest_ts_id)
    and t.ente_proprietario_id=enteproprietarioid::integer;
	-- DAVIDE - 11.07.2016 - Fine
	
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

	-- delete spostata sopra
	--delete
	 --from siac_r_migr_voce_mutuo_t_mutuo_voce
	 --where ente_proprietario_id = enteproprietarioid::integer;

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