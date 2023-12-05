/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_soggetto_clean (
  enteproprietarioid integer,
  loginoperazione varchar,
  idmin integer,
  idmax integer,
  cleanDecodifica VARCHAR,
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

	strMessaggioFinale := 'Pulizia tabelle soggetti da ['||idmin||'] a ['||idmax||'].';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;
--    if cleanDecodifica = '' then cleanDecodifica:= NULL; end if; parametro non piu utilizzato, la pulizia delle tabelle di decodifica è fatta su pentaho

    if enteproprietarioid is null
    	--or cleanDecodifica is null or  (cleanDecodifica = 'S' and loginoperazione is null) parametro non piu utilizzato, la pulizia delle tabelle di decodifica è fatta su pentaho
        then
    	codresult := '-1';
--        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||',cleanDecodifica: '||quote_nullable(cleanDecodifica)||',loginoperazione: '||quote_nullable(loginoperazione) ;
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||enteproprietarioid||',loginoperazione: '||quote_nullable(loginoperazione) ;
        return;
    end if;

    begin

	-- o si cancella tutto cio che è presente per ente oppure tutto quello che è stato creato dall'utente passato
    	strMessaggio := 'create migr_soggetto_del.';
      execute 'DROP TABLE IF EXISTS migr_soggetto_del;
      	create table migr_soggetto_del as
        select soggetto_id from siac_t_soggetto where
        login_creazione=COALESCE('||quote_nullable(loginoperazione)||', login_creazione)
        and ente_proprietario_id = '||enteproprietarioid||' and soggetto_id >='||idmin||' and soggetto_id<='||idmax||
        ' and soggetto_id not in (select r.soggetto_id from siac_r_soggetto_ruolo r where r.ente_proprietario_id='||enteproprietarioid||');
        alter table migr_soggetto_del add primary key (soggetto_id);
		ANALYZE migr_soggetto_del;';

    	strMessaggio := 'create migr_soggettorel_del.';

      execute 'DROP TABLE IF EXISTS migr_soggettorel_del;
      	create table migr_soggettorel_del as select soggetto_relaz_id from siac_r_soggetto_relaz rel
        where exists
        	(select 1 from migr_soggetto_del s where
             rel.soggetto_id_a=s.soggetto_id or rel.soggetto_id_da=s.soggetto_id);
        alter table migr_soggettorel_del add primary key (soggetto_relaz_id);
		ANALYZE migr_soggettorel_del;';

        strMessaggio := 'create migr_modpag_del.';
      execute
          'DROP TABLE IF EXISTS migr_modpag_del;
           create table migr_modpag_del as select modpag_id from siac_t_modpag modpag
           join migr_soggetto_del s on (modpag.soggetto_id = s.soggetto_id);
           alter table migr_modpag_del add primary key (modpag_id);
		   ANALYZE migr_modpag_del;';

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

-- SofiaDaniela 23.09.2015
 DELETE FROM siac_r_soggetto_onere r using migr_soggetto_del tmp
 where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

-- DAVIDE 18.09.2015 add delete nuove tabelle relazione
 DELETE FROM siac_r_subdoc_sog r USING siac_t_soggetto r2
	where r.soggetto_id = r2.soggetto_id and exists (select 1 from migr_soggetto_del tmp where
																r2.soggetto_id = tmp.soggetto_id)
	and r.ente_proprietario_id=enteproprietarioid::integer;

 DELETE FROM siac_r_doc_sog r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

--11.03.2015 add delete nuove tabelle relazione
 DELETE FROM siac_r_subdoc_modpag r USING siac_r_soggrel_modpag r2
	where r.soggrelmpag_id = r2.soggrelmpag_id and exists (select 1 from migr_soggettorel_del tmp where
															r2.soggetto_relaz_id = tmp.soggetto_relaz_id)
	and r.ente_proprietario_id=enteproprietarioid::integer;

--29.12.2015 add delete SIAC_R_SUBDOC_MODPAG per modpag
DELETE FROM SIAC_R_SUBDOC_MODPAG r using migr_modpag_del tmp
	where r.modpag_id = tmp.modpag_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_modpag_ordine r using migr_modpag_del tmp
	where r.modpag_id = tmp.modpag_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_modpag_ordine r using siac_r_soggrel_modpag r2
	where r.soggrelmpag_id = r2.soggrelmpag_id and exists (select 1 from migr_soggettorel_del tmp where
															r2.soggetto_relaz_id = tmp.soggetto_relaz_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

 DELETE FROM siac_r_soggrel_modpag_mod mod using siac_r_soggetto_relaz_mod mod2
	where mod.soggetto_relaz_mod_id = mod2.soggetto_relaz_mod_id
    and exists (select 1 from migr_soggettorel_del del where del.soggetto_relaz_id = mod2.soggetto_relaz_id)
    and mod.ente_proprietario_id=enteproprietarioid::integer;

-- 23.09.2015 SofiaDaniela
-- aggiunta delete poiche non cancellava le  siac_r_modpag_ordine
-- che da applicativo vengono create tra un soggetto e la sua sede secondaria
-- in cui soggetto_id_da --> soggetto da cancellare
--        soggetto_id_a  --> soggetto sede
--        siac_r_modpag_ordine --> soggetto_id=soggetto_da e modpag_id del soggetto_id_a
-- questo tipo di relazione non viene cancellata nella delete precedente poiche il soggrelmpag_id da applicativo
-- resta null

DELETE FROM siac_r_modpag_ordine r using siac_r_soggetto_relaz r2
 where r.soggetto_id = r2.soggetto_id_da and exists (select 1 from migr_soggettorel_del tmp where
               r2.soggetto_relaz_id = tmp.soggetto_relaz_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

 DELETE FROM siac_r_soggrel_modpag t using migr_soggettorel_del tmp
	WHERE t.soggetto_relaz_id = tmp.soggetto_relaz_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

 DELETE FROM siac_r_soggetto_relaz_stato r1 using migr_soggettorel_del r2
 where r1.soggetto_relaz_id = r2.soggetto_relaz_id
 and r1.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_relaz_mod mod using migr_soggettorel_del tmp
	where mod.soggetto_relaz_id = tmp.soggetto_relaz_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_relaz t using migr_soggettorel_del tmp
	where t.soggetto_relaz_id = tmp.soggetto_relaz_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

-- 29.12.2015 SIAC_R_ORDINATIVO_MODPAG
DELETE FROM SIAC_R_ORDINATIVO_MODPAG r using migr_modpag_del tmp
 WHERE r.modpag_id = tmp.modpag_id
 and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_modpag_stato t using migr_modpag_del tmp
 WHERE t.modpag_id = tmp.modpag_id
 and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_modpag_mod t using migr_modpag_del tmp
	where t.modpag_id = tmp.modpag_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_modpag t using migr_modpag_del tmp
	where t.modpag_id = tmp.modpag_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_indirizzo_soggetto_tipo_mod mod USING siac_t_indirizzo_soggetto_mod mod2
	where mod.indirizzo_mod_id = mod2.indirizzo_mod_id and exists (select 1 from migr_soggetto_del tmp where
																mod2.soggetto_id = tmp.soggetto_id)
	and mod.ente_proprietario_id=enteproprietarioid;
DELETE FROM siac_t_indirizzo_soggetto_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_indirizzo_soggetto_tipo r using siac_t_indirizzo_soggetto t
 	where r.indirizzo_id = t.indirizzo_id and exists (select 1 from migr_soggetto_del tmp where
													 t.soggetto_id = tmp.soggetto_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

-- 01.10.2015 pulizia tabella dui relazione migrazione/siac
DELETE FROM siac_r_migr_indirizzo_secondario_indirizzo m using siac_t_indirizzo_soggetto r
where m.indirizzo_id=r.indirizzo_id and exists (select 1 from migr_soggetto_del tmp where
												 r.soggetto_id = tmp.soggetto_id)
and m.ente_proprietario_id = enteproprietarioid::integer ;

DELETE FROM siac_t_indirizzo_soggetto t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_recapito_soggetto_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

-- 01.10.2015 pulizia tabella dui relazione migrazione/siac
DELETE FROM siac_r_migr_recapito_soggetto_recapito m using siac_t_recapito_soggetto r
where m.recapito_id=r.recapito_id and exists (select 1 from migr_soggetto_del tmp where
												 r.soggetto_id = tmp.soggetto_id)
and  m.ente_proprietario_id = enteproprietarioid::integer ;

DELETE FROM siac_t_recapito_soggetto t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_stato t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_attr_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_attr t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_classe_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

-- 01.10.2015 pulizia tabella dui relazione migrazione/siac
DELETE FROM siac_r_migr_soggetto_classe_rel_classe m using siac_r_soggetto_classe r
 where m.soggetto_classe_r_id=r.soggetto_classe_r_id and exists (select 1 from migr_soggetto_del tmp where
												 r.soggetto_id = tmp.soggetto_id)
 and m.ente_proprietario_id = enteproprietarioid::integer ;

DELETE FROM siac_r_soggetto_classe r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_tipo_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_soggetto_tipo r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--24.03.2015 Daniela

DELETE FROM SIAC_R_MOVGEST_TS_SOG_MOD r using migr_soggetto_del tmp
	where (r.soggetto_id_old = tmp.soggetto_id or r.soggetto_id_new = tmp.soggetto_id)
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM SIAC_R_MOVGEST_TS_SOG r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--fine
-- 17.04.2015 D.
DELETE FROM siac_r_mutuo_soggetto r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
-- 04.05.2015 d.
DELETE FROM siac_r_liquidazione_soggetto r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;
--
DELETE FROM siac_r_forma_giuridica_mod r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_r_forma_giuridica r using migr_soggetto_del tmp
	where r.soggetto_id = tmp.soggetto_id
    and r.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_persona_giuridica_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_persona_giuridica t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_persona_fisica_mod mod using migr_soggetto_del tmp
	where mod.soggetto_id = tmp.soggetto_id
    and mod.ente_proprietario_id=enteproprietarioid::integer;

DELETE FROM siac_t_persona_fisica t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

-- 05.08.2016 Sofia - aggiunte relazioni - inizio
DELETE FROM SIAC_R_PDCE_CONTO_SOGGETTO t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
DELETE FROM SIAC_R_CONCILIAZIONE_BENEFICIARIO t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
-- 05.08.2016 Sofia - aggiunte relazioni - fine

-- 02.11.2016 - DAVIDE - aggiunte clean tabelle mancanti
DELETE FROM siac_t_mov_ep_det k
    where k.movep_id in (select k1.movep_id from siac_t_mov_ep k1    
    where k1.regep_id in (select k2.pnota_id from siac_t_prima_nota k2
    where k2.soggetto_id in (select t.soggetto_id from siac_t_soggetto t, migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer)));

DELETE FROM siac_t_mov_ep k    
    where k.regep_id in (select k1.pnota_id from siac_t_prima_nota k1
    where k1.soggetto_id in (select t.soggetto_id from siac_t_soggetto t, migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer));
	
DELETE FROM siac_r_prima_nota_stato k
    where k.pnota_id in (select k1.pnota_id from siac_t_prima_nota k1
    where k1.soggetto_id in (select t.soggetto_id from siac_t_soggetto t, migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer));
	
DELETE FROM siac_t_prima_nota t using migr_soggetto_del tmp
    where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
	
DELETE FROM siac_r_ordinativo_soggetto t using migr_soggetto_del tmp
    where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;
-- 02.11.2016 - DAVIDE - Fine

DELETE FROM siac_t_soggetto t using migr_soggetto_del tmp
	where t.soggetto_id = tmp.soggetto_id
    and t.ente_proprietario_id=enteproprietarioid::integer;

    strMessaggio := 'Pulizia tabelle di relazione migr/siac.';
DELETE FROM siac_r_migr_sede_secondaria_rel_sede m using migr_soggettorel_del tmp
    where m.soggetto_relaz_id=tmp.soggetto_relaz_id
	and m.ente_proprietario_id = enteproprietarioid::integer ;
DELETE FROM siac_r_migr_soggetto_soggetto m using migr_soggetto_del tmp
    where m.soggetto_id=tmp.soggetto_id
	and m.ente_proprietario_id = enteproprietarioid::integer ;
DELETE FROM siac_r_migr_relaz_soggetto_relaz m using migr_soggettorel_del tmp
	where m.soggetto_relaz_id = tmp.soggetto_relaz_id
	and m.ente_proprietario_id = enteproprietarioid::integer;
DELETE FROM siac_r_migr_modpag_modpag m using migr_modpag_del tmp
	where m.modpag_id = tmp.modpag_id
	and m.ente_proprietario_id = enteproprietarioid::integer;

--DELETE FROM siac_r_migr_classe_soggclasse where ente_proprietario_id = enteproprietarioid::integer ; pulite dopo in pentaho con tabelle di decodifica
--DELETE FROM siac_r_migr_mod_accredito_accredito where ente_proprietario_id = enteproprietarioid::integer ; pulite dopo in pentaho con tabelle di decodifica

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