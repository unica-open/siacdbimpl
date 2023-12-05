/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_doc_clean (
  enteproprietarioid integer,
  loginoperazione varchar,
  tipoFamDoc varchar,
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
    tipoFamId integer := 0;
begin

	strMessaggioFinale := 'Pulizia tabelle doc da ['||idmin||'] a ['||idmax||'].';
    codResult := '0';

	if loginoperazione = '' then loginoperazione:= NULL; end if;

    if enteproprietarioid is null or tipoFamDoc is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||quote_nullable(enteproprietarioid)||', tipoFamDoc='||quote_nullable(tipoFamDoc);
        return;
    end if;

	begin
      select d.doc_fam_tipo_id into strict tipoFamId
      from siac_d_doc_fam_tipo d
      where d.doc_fam_tipo_code = tipoFamDoc
      and d.ente_proprietario_id = enteproprietarioid
      and d.data_cancellazione is null
      and (validita_fine is null or now() between validita_inizio and validita_fine);
	exception
    	WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'siac_d_doc_fam_tipo % not found', tipoFamDoc;
        WHEN TOO_MANY_ROWS THEN
            RAISE EXCEPTION 'siac_d_doc_fam_tipo % not unique', tipoFamDoc;
    end;

    begin

	-- o si cancella tutto cio che ? presente per ente oppure tutto quello che ? stato creato dall'utente passato
    strMessaggio := 'create migr_doc_del.';
      execute 'DROP TABLE IF EXISTS migr_doc_del;
      	create table migr_doc_del as
        select t.doc_id from siac_t_doc t, siac_d_doc_tipo tipoDoc
        where t.ente_proprietario_id = '||enteproprietarioid||
        ' and t.login_operazione=COALESCE('||quote_nullable(loginoperazione)||', t.login_operazione)
        and t.doc_tipo_id = tipoDoc.doc_tipo_id
        and tipoDoc.doc_fam_tipo_id='||tipoFamId||
        ' and t.doc_id>='||idmin||' and t.doc_id<='||idmax||';
        alter table migr_doc_del add primary key (doc_id);
		ANALYZE migr_doc_del;';

     strMessaggio := 'create migr_docquo_del.';
       execute 'DROP TABLE IF EXISTS migr_docquo_del;
       create table migr_docquo_del as
        select sd.subdoc_id from siac_t_subdoc sd
        where exists (select 1 from migr_doc_del m where m.doc_id=sd.doc_id)
        and sd.ente_proprietario_id = '||enteproprietarioid||';
		alter table migr_docquo_del add primary key (subdoc_id);
		ANALYZE migr_docquo_del;';

	 if tipoFamDoc = 'S' then
       strMessaggio := 'create migr_docquo_iva_del.';
         execute 'DROP TABLE IF EXISTS migr_docquo_iva_del;
         create table migr_docquo_iva_del as
          select sd.subdociva_id from siac_t_subdoc_iva sd
          where exists (select 1 from siac_r_doc_iva riva, migr_doc_del m where m.doc_id=riva.doc_id and sd.dociva_r_id =riva.dociva_r_id and riva.ente_proprietario_id = '||enteproprietarioid||')
          and sd.ente_proprietario_id = '||enteproprietarioid||';
          alter table migr_docquo_iva_del add primary key (subdociva_id);
          ANALYZE migr_docquo_iva_del;';

       strMessaggio := 'create t_ivamov_del.';
         execute 'DROP TABLE IF EXISTS t_ivamov_del;
         create table t_ivamov_del as
          select mov.ivamov_id from siac_t_ivamov mov, siac_r_ivamov r, migr_docquo_iva_del ivaDel
          where ivaDel.subdociva_id = r.subdociva_id
          and r.ivamov_id = mov.ivamov_id
          and mov.ente_proprietario_id = '||enteproprietarioid||';
          alter table t_ivamov_del add primary key (ivamov_id);
          ANALYZE t_ivamov_del;';
     end if;

    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';


	if tipoFamDoc = 'S' then
-- 25.11.2015 cancellazione dati iva

      delete from siac_r_ivamov r using t_ivamov_del tmp
      where  r.ivamov_id=tmp.ivamov_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_t_ivamov t using t_ivamov_del tmp
      where  t.ivamov_id=tmp.ivamov_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_migr_docquospesaivaaliq_t_ivamov m using t_ivamov_del tmp
      where m.ivamov_id=tmp.ivamov_id
      and ente_proprietario_id = enteproprietarioid;

  -- fnc_migr_relaz_documenti_iva
      delete from siac_r_migr_relazdocquospesaiva_subdoc m using siac_r_subdoc_iva r
          where m.doc_r_id=r.doc_r_id
          and exists (select 1 from migr_docquo_iva_del tmp where (r.subdociva_id_da=tmp.subdociva_id or r.subdociva_id_a=tmp.subdociva_id))
          and r.ente_proprietario_id = enteproprietarioid
          and m.ente_proprietario_id = enteproprietarioid;

      delete from siac_r_subdoc_iva r using migr_docquo_iva_del tmp
      where (r.subdociva_id_da=tmp.subdociva_id or r.subdociva_id_a=tmp.subdociva_id)
      and ente_proprietario_id = enteproprietarioid;

  -- fnc_migr_docquo_spesa_iva

      delete from siac_r_subdoc_iva_stato r using migr_docquo_iva_del tmp
      where r.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_subdoc_iva_attr r using migr_docquo_iva_del tmp
      where r.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_t_subdoc_iva t using migr_docquo_iva_del tmp
      where t.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_migr_docquospesaiva_t_subdoc_iva m using migr_docquo_iva_del tmp
      where m.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_doc_iva r using migr_doc_del tmp
      where r.doc_id=tmp.doc_id
      and ente_proprietario_id = enteproprietarioid;

    end if;

-- cancellazione doc quo
    delete from siac_r_subdoc_atto_amm r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_subdoc_movgest_ts r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_subdoc_liquidazione r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_subdoc_ordinativo_ts r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from  siac_r_subdoc_sog r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from  siac_r_subdoc_modpag r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_subdoc_attr r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_subdoc_class r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    --29.12.2015 siac_t_registro_pcc
    delete from siac_t_registro_pcc t using migr_docquo_del tmp
    where t.subdoc_id=tmp.subdoc_id
    and t.ente_proprietario_id=enteproprietarioid;
	
    --01.02.2017 SIAC_R_SUBDOC_SPLITREVERSE_IVA_TIPO - DAVIDE
    delete from siac_r_subdoc_splitreverse_iva_tipo r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_t_subdoc r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    -- cancellazione doc
	delete from siac_t_registrounico_doc t using migr_doc_del tmp
    where t.doc_id=tmp.doc_id
    and t.ente_proprietario_id=enteproprietarioid;

	--25.11.2015 aggiunta perchè mancava..
	delete from siac_r_migr_relaz_documenti_doc m using siac_r_doc r
    where m.doc_r_id=r.doc_r_id
    and exists (select 1 from  migr_doc_del tmp where (r.doc_id_a=tmp.doc_id or r.doc_id_da=tmp.doc_id))
    and r.ente_proprietario_id=enteproprietarioid
    and m.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_doc r using migr_doc_del tmp
    where (r.doc_id_a=tmp.doc_id or r.doc_id_da=tmp.doc_id)
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_doc_stato r using migr_doc_del tmp
    where r.doc_id=tmp.doc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_doc_attr r using migr_doc_del tmp
    where r.doc_id=tmp.doc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_doc_class r using migr_doc_del tmp
    where r.doc_id=tmp.doc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_doc_sog r using migr_doc_del tmp
    where r.doc_id=tmp.doc_id
    and r.ente_proprietario_id=enteproprietarioid;

    --29.12.2015
    delete from SIAC_T_SUBDOC_NUM t using migr_doc_del tmp
    where t.doc_id=tmp.doc_id
    and t.ente_proprietario_id=enteproprietarioid;

    delete from siac_t_doc t using migr_doc_del tmp
    where t.doc_id=tmp.doc_id
    and t.ente_proprietario_id=enteproprietarioid;

    if tipoFamDoc = 'E' then
      delete from siac_r_migr_docquo_entrata_t_subdoc m using migr_docquo_del tmp
      where m.subdoc_id=tmp.subdoc_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_migr_doc_entrata_t_doc m using migr_doc_del tmp
      where m.doc_id=tmp.doc_id
      and ente_proprietario_id = enteproprietarioid;

    elsif tipoFamDoc = 'S' then
      delete from siac_r_migr_docquo_spesa_t_subdoc m using migr_docquo_del tmp
      where m.subdoc_id=tmp.subdoc_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_migr_doc_spesa_t_doc m using migr_doc_del tmp
      where m.doc_id=tmp.doc_id
      and ente_proprietario_id = enteproprietarioid;

    end if;

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