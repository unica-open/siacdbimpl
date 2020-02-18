/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_capitolo_clean (
  enteproprietarioid varchar,
  loginoperazione varchar,
  loginoperazione_classif varchar,
  bilelemtipo varchar,
  idMin integer,
  idMax integer,
  out codresult varchar,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggioFinale VARCHAR(1500):='';
    elemTipoId integer;
begin

	strMessaggioFinale := 'Migrazione capitoli.Pulizia tabelle da elem_id '||idMin||' a '||idMax||'.';
    codResult := '0';

    if enteproprietarioid is null or bilelemtipo is null or loginoperazione_classif is null then
    	codresult := '-1';
        messaggiorisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid='||quote_nullable(enteproprietarioid)||',bilelemtipo='||quote_nullable(bilelemtipo)||',loginoperazione_classif='||quote_nullable(loginoperazione_classif);
        return;
    end if;

	begin
      select elem_tipo_id into STRICT elemTipoId
      from siac_d_bil_elem_tipo
      where elem_tipo_code = bilelemtipo
      and ente_proprietario_id = enteproprietarioid::integer
      and data_cancellazione is null
      and (validita_fine is null or now() between validita_inizio and validita_fine);
	exception
    	WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'siac_d_bil_elem_tipo % not found', bilelemtipo;
        WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION 'siac_d_bil_elem_tipo % not unique', bilelemtipo;
    end;
    begin
      if loginoperazione = '' then loginoperazione:=NULL; end if;

      execute
          'DROP TABLE IF EXISTS migr_bilelem_del;
           create table migr_bilelem_del as
           select elem_id from siac_t_bil_elem
           where ente_proprietario_id = '||enteproprietarioid||
           ' and elem_tipo_id = '||elemTipoId ||
           ' and login_operazione=COALESCE('||quote_nullable(loginoperazione)||', login_operazione)
            and elem_id >='||idMin||' and elem_id <='||idMax||';
           ALTER TABLE migr_bilelem_del ADD PRIMARY KEY (elem_id);
           ANALYZE migr_bilelem_del;';

	 -- elenco atto_legge_id da cancellare (legati all'elemento)
	  execute
        'DROP TABLE IF EXISTS migr_bilelem_attolegge_del;
          create table migr_bilelem_attolegge_del as
          select r.attolegge_bil_elem_id, r.attolegge_id from siac_r_bil_elem_atto_legge r
          join migr_bilelem_del elem
          on (r.elem_id = elem.elem_id);
          ALTER TABLE migr_bilelem_attolegge_del ADD PRIMARY KEY (attolegge_bil_elem_id,attolegge_id);
          ANALYZE migr_bilelem_attolegge_del;';
          -- guida la login_operazione dell'elemento prinicpale cioè il capitolo, per questo commento la condizione
          --where r.login_operazione=COALESCE('||quote_nullable(loginoperazione)||', r.login_operazione);


	 -- elenco vincoli da cancellare (legati all'elemento)
	 execute
        'DROP TABLE IF EXISTS migr_bilelem_vincolo_del;
      	 create table migr_bilelem_vincolo_del as
          select distinct r.vincolo_id from siac_r_vincolo_bil_elem r
            join migr_bilelem_del elem
          	on (r.elem_id = elem.elem_id);
            ALTER TABLE migr_bilelem_vincolo_del ADD PRIMARY KEY (vincolo_id);
            ANALYZE migr_bilelem_vincolo_del;';
            -- guida la login_operazione dell'elemento prinicpale cioè il capitolo, per questo commento la condizione
            --where r.login_operazione=COALESCE('||quote_nullable(loginoperazione)||', r.login_operazione);';

	 -- elenco classificatori da cancellare (legati all'elemento)
	 execute
	  'DROP TABLE IF EXISTS migr_bilelem_class_del;
       create table migr_bilelem_class_del as
          select distinct r.classif_id, r.elem_id from siac_r_bil_elem_class r
          join migr_bilelem_del elem on (r.elem_id = elem.elem_id);
          ALTER TABLE migr_bilelem_class_del ADD PRIMARY KEY (classif_id,elem_id);
          ANALYZE migr_bilelem_class_del;';
          -- guida la login_operazione dell'elemento prinicpale cioè il capitolo, per questo commento la condizione
          --where r.login_operazione=COALESCE('||quote_nullable(loginoperazione)||', r.login_operazione);';

      execute 'DROP TABLE IF EXISTS migr_bilelem_variazioni_del;
          create table migr_bilelem_variazioni_del as
          select r.variazione_stato_id, r2.variazione_id from siac_t_bil_elem_var r, siac_r_variazione_stato r2
          	, migr_bilelem_del tmp
          where r.elem_id = tmp.elem_id
          and r2.variazione_stato_id = r.variazione_stato_id
          union
          select r.variazione_stato_id, r2.variazione_id from siac_t_bil_elem_det_var r, siac_r_variazione_stato r2
            , migr_bilelem_del tmp
          where r.elem_id = tmp.elem_id
          and r2.variazione_stato_id = r.variazione_stato_id
          union
          select r.variazione_stato_id, r2.variazione_id from siac_r_bil_elem_class_var r, siac_r_variazione_stato r2
              , migr_bilelem_del tmp
          where r.elem_id = tmp.elem_id
          and r2.variazione_stato_id = r.variazione_stato_id;
          ALTER TABLE migr_bilelem_variazioni_del ADD PRIMARY KEY (variazione_stato_id,variazione_id);
          ANALYZE migr_bilelem_variazioni_del;';

	exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

-- ATTI LEGGE
    delete from siac_r_bil_elem_atto_legge r
    using migr_bilelem_attolegge_del tmp
    where r.attolegge_bil_elem_id = tmp.attolegge_bil_elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

  delete from siac_r_atto_legge_stato r
    using migr_bilelem_attolegge_del tmp
    where r.attolegge_id = tmp.attolegge_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

  delete from siac_t_atto_legge r
    using migr_bilelem_attolegge_del tmp
    where r.attolegge_id = tmp.attolegge_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

-- VINCOLI
    delete from siac_r_vincolo_bil_elem r
	using migr_bilelem_vincolo_del tmp
    where r.vincolo_id = tmp.vincolo_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

	delete from siac_r_vincolo_stato r
    using migr_bilelem_vincolo_del tmp
    where r.vincolo_id = tmp.vincolo_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_vincolo_attr r
    using migr_bilelem_vincolo_del tmp
    where r.vincolo_id = tmp.vincolo_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_vincolo_genere r
    using migr_bilelem_vincolo_del tmp
    where r.vincolo_id = tmp.vincolo_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_t_vincolo t
    using migr_bilelem_vincolo_del tmp
    where t.vincolo_id = tmp.vincolo_id
    and t.ente_proprietario_id = enteproprietarioid::integer;

-- VARIAZIONI
    delete from siac_t_bil_elem_var var using migr_bilelem_variazioni_del tmp
    where var.variazione_stato_id = tmp.variazione_stato_id
    and var.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_t_bil_elem_det_var var using migr_bilelem_variazioni_del tmp
    where var.variazione_stato_id = tmp.variazione_stato_id
    and var.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_bil_elem_class_var var using migr_bilelem_variazioni_del tmp
    where var.variazione_stato_id = tmp.variazione_stato_id
    and var.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_variazione_stato var using migr_bilelem_variazioni_del tmp
    where var.variazione_stato_id = tmp.variazione_stato_id
    and var.ente_proprietario_id = enteproprietarioid::integer
    and not exists (select 1 from siac_t_bil_elem_var r where r.variazione_stato_id=var.variazione_stato_id)
    and not exists (select 1 from siac_t_bil_elem_det_var r where r.variazione_stato_id=var.variazione_stato_id)
    and not exists (select 1 from siac_r_bil_elem_class_var r where r.variazione_stato_id=var.variazione_stato_id);

    delete from siac_r_variazione_attr var using migr_bilelem_variazioni_del tmp
    where var.variazione_id = tmp.variazione_id
    and var.ente_proprietario_id = enteproprietarioid::integer
    and not exists (select 1 from siac_r_variazione_stato r where r.variazione_id=var.variazione_id);

    delete from siac_t_variazione var using migr_bilelem_variazioni_del tmp
    where var.variazione_id = tmp.variazione_id
    and var.ente_proprietario_id = enteproprietarioid::integer
    and not exists (select 1 from siac_r_variazione_stato r where r.variazione_id=var.variazione_id);

-- CLASSIFICATORI
  delete  from siac_r_bil_elem_class r using
      (select classif_id, elem_id from  siac_r_bil_elem_class
      intersect
       select classif_id, elem_id from  migr_bilelem_class_del)  c
       where c.classif_id=r.classif_id
       and c.elem_id = r.elem_id
       and r.ente_proprietario_id = enteproprietarioid::integer;

  delete from  siac_t_class t
    using migr_bilelem_class_del tmp
    where t.classif_id =tmp.classif_id
    and  not exists  (select 1 from  siac_r_bil_elem_class c where c.classif_id=t.classif_id)
    and t.login_operazione=loginoperazione_classif
    and t.ente_proprietario_id = enteproprietarioid::integer;

-- 05.08.2016 Sofia
	delete from SIAC_R_CONCILIAZIONE_BENEFICIARIO r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

-- REL IMP/ACC
	delete from SIAC_R_MOVGEST_BIL_ELEM r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

-- ELEMENTI
    delete from  siac_r_bil_elem_attr  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from  siac_r_bil_elem_stato  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from  siac_r_bil_elem_categoria  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

--10.03.2015 nuove tabelle di relazione aggiunta delete
delete from  SIAC_R_CRONOP_ELEM_BIL_ELEM  r
	using migr_bilelem_del tmp
	where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from SIAC_R_BIL_ELEM_REL_TEMPO  r
	using migr_bilelem_del tmp
	where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from  siac_r_predoc_bil_elem  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from  siac_r_ordinativo_bil_elem  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from  siac_r_fondo_econ_bil_elem  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from  siac_r_causale_bil_elem  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

delete from  siac_r_bil_elem_iva_attivita  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

--30.06.2015 Daniela
delete from  SIAC_R_BIL_ELEM_STIPENDIO_CODICE  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from  siac_t_bil_elem_det  t
    using migr_bilelem_del tmp
    where t.elem_id = tmp.elem_id
    and t.ente_proprietario_id = enteproprietarioid::integer;

-- 12.11.2015 Davide
    delete from  siac_t_dicuiimpegnato_bilprev  t
    using migr_bilelem_del tmp
    where t.elem_id = tmp.elem_id
    and t.ente_proprietario_id = enteproprietarioid::integer;
-- 12.11.2015 Davide  - fine

-- 14.10.2016 Davide
	delete from SIAC_R_CONCILIAZIONE_CAPITOLO r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;
	
    delete from  siac_t_bil_elem  t
    using migr_bilelem_del tmp
    where t.elem_id = tmp.elem_id
    and t.ente_proprietario_id = enteproprietarioid::integer;

-- MIGRAZIONE
    delete from siac_r_migr_attilegge_ent r
    using migr_bilelem_attolegge_del tmp
    where r.attolegge_bil_elem_id = tmp.attolegge_bil_elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_migr_attilegge_usc r
    using migr_bilelem_attolegge_del tmp
    where r.attolegge_bil_elem_id = tmp.attolegge_bil_elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_migr_vincolo_capitolo r
    using migr_bilelem_vincolo_del tmp
    where r.vincolo_id = tmp.vincolo_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_migr_capitolo_uscita_bil_elem  r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    delete from siac_r_migr_capitolo_entrata_bil_elem   r
    using migr_bilelem_del tmp
    where r.elem_id = tmp.elem_id
    and r.ente_proprietario_id = enteproprietarioid::integer;

    strMessaggioFinale := strMessaggioFinale || 'Ok.';
    messaggioRisultato := strMessaggioFinale;

exception
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500);
        codResult := '-1';
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;