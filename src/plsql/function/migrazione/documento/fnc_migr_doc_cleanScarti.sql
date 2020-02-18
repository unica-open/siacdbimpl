/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_doc_cleanScarti (
  enteproprietarioid integer,
  annoBilancio varchar,
  dataelaborazione timestamp,
  out codresult varchar,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
--Elimina da siac i doc migrati, per cui una o piu quote sono state scartate.
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	bilancioid integer:=0;
	v_count integer :=0;
    countRuf record;
begin

	strMessaggioFinale := 'Pulizia tabelle doc con scarti.';
    codResult := '0';

    if enteproprietarioid is null then
    	codresult := '-1';
        messaggioRisultato := strMessaggioFinale || 'Verificare input function: enteproprietarioid '||quote_nullable(enteproprietarioid);
        return;
    end if;

	strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';

    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioid,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;
	if (bilancioid=-1) then
    	codresult := '-1';
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		return;
	end if;

    begin

	--Elenco id documenti con almeno una quota scartata
    strMessaggio := 'create migr_doc_del.';

      execute 'DROP TABLE IF EXISTS migr_doc_del;
      	create table migr_doc_del as
        select distinct rmigr.doc_id, ''S'' tipo_doc
        from
        siac_r_migr_doc_spesa_t_doc rmigr,
        migr_doc_spesa migrDoc,
        migr_docquo_spesa migrDocQ,
        migr_docquo_spesa_scarto migrDocQS
        where
        rmigr.ente_proprietario_id='||enteproprietarioid
        ||' and rmigr.migr_doc_spesa_id=migrDoc.migr_docspesa_id and migrDoc.ente_proprietario_id='||enteproprietarioid
        ||' and migrDocQ.docspesa_id=migrDoc.docspesa_id and migrDocQ.ente_proprietario_id='||enteproprietarioid
        ||' and migrDocQS.migr_docquo_spesa_id=migrDocQ.migr_docquo_spesa_id and migrDocQS.ente_proprietario_id='||enteproprietarioid
        ||'
        union
        select distinct rmigr.doc_id, ''E'' tipo_doc
        from
        siac_r_migr_doc_entrata_t_doc rmigr,
        migr_doc_entrata migrDoc,
        migr_docquo_entrata migrDocQ,
        migr_docquo_entrata_scarto migrDocQS
        where
        rmigr.ente_proprietario_id='||enteproprietarioid
        ||' and rmigr.migr_doc_entrata_id=migrDoc.migr_docentrata_id and migrDoc.ente_proprietario_id='||enteproprietarioid
        ||' and migrDocQ.docentrata_id=migrDoc.docentrata_id and migrDocQ.ente_proprietario_id='||enteproprietarioid
        ||' and migrDocQS.migr_docquo_entrata_id=migrDocQ.migr_docquo_entrata_id and migrDocQS.ente_proprietario_id='||enteproprietarioid||';
        alter table migr_doc_del add primary key (doc_id, tipo_doc);
		ANALYZE migr_doc_del;';

	-- elenco id quote migrate il cui documento e da cancellare
     strMessaggio := 'create migr_docquo_del.';
       execute 'DROP TABLE if exists migr_docquo_del;
       create table migr_docquo_del as
        select sd.subdoc_id, del.tipo_doc from siac_t_subdoc sd, migr_doc_del del
        where sd.ente_proprietario_id = '||enteproprietarioid
        ||' and sd.doc_id=del.doc_id;
		alter table migr_docquo_del add primary key (subdoc_id,tipo_doc);
		ANALYZE migr_docquo_del;';

	-- elenchi doc legati SOLO a quote a da cancellare
     strMessaggio := 'create migr_elencoDocAllegati_del.';
       execute 'DROP TABLE IF EXISTS migr_elencoDocAllegati_del;
		create table migr_elencoDocAllegati_del as
		select distinct relencodoc.eldoc_id
		from siac_r_elenco_doc_subdoc relencodoc
		where relencodoc.ente_proprietario_id='||enteproprietarioid
		||' and exists (select 1 from migr_docquo_del del where del.subdoc_id = relencodoc.subdoc_id)
		except
		select distinct relencodoc.eldoc_id
        from siac_r_elenco_doc_subdoc relencodoc, siac_t_subdoc sub
        where relencodoc.ente_proprietario_id='||enteproprietarioid
		||' and relencodoc.subdoc_id=sub.subdoc_id
        and sub.subdoc_id not in (select subdoc_id from migr_docquo_del del);
		alter table migr_elencoDocAllegati_del add primary key (eldoc_id);
		ANALYZE migr_elencoDocAllegati_del;';

	-- elenco degli atti allegati composti dagli elenchi da cancellare

     strMessaggio := 'create migr_atto_allegato_del.';
       execute 'DROP TABLE IF EXISTS migr_atto_allegato_del;
       create table migr_atto_allegato_del as
       select rel.attoal_id from siac_r_atto_allegato_elenco_doc rel
          where rel.ente_proprietario_id='||enteproprietarioid
          ||' and exists (select 1 from migr_elencoDocAllegati_del del where del.eldoc_id=rel.eldoc_id)
       except
       select rel.attoal_id from siac_r_atto_allegato_elenco_doc rel
       	  where rel.ente_proprietario_id='||enteproprietarioid
          ||' and rel.eldoc_id not in (select 1 from migr_elencoDocAllegati_del del where del.eldoc_id=rel.eldoc_id);
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


/* 27.11.2015
   Parte relativa ai dati iva: questa funzione viene richiamata nel flusso dopo la migrazione dei documenti e prima della migrazione
   dell'iva. Se l'iter non cambia non e necessario pulire questi dati perche non sono stati ancora migrati

	-- i subdoc iva legati a documenti che devono essere cancellati
     strMessaggio := 'create migr_docquo_iva_del.';
       execute 'DROP TABLE IF EXISTS migr_docquo_iva_del;
       create table migr_docquo_iva_del as
        select sd.subdociva_id from siac_t_subdoc_iva sd
        where exists (select 1 from siac_r_doc_iva riva, migr_doc_del m where m.doc_id=riva.doc_id and sd.dociva_r_id =riva.dociva_r_id and riva.ente_proprietario_id = '||enteproprietarioid||')
        and sd.ente_proprietario_id = '||enteproprietarioid||';
        alter table migr_docquo_iva_del add primary key (subdociva_id);
        ANALYZE migr_docquo_iva_del;';

	-- elenco dei movimenti iva (aliquote) legate ai subdoc iva da cancellare
       strMessaggio := 'create t_ivamov_del.';
         execute 'DROP TABLE IF EXISTS t_ivamov_del;
         create table t_ivamov_del as
          select mov.ivamov_id from siac_t_ivamov mov, siac_r_ivamov r, migr_docquo_iva_del ivaDel
          where ivaDel.subdociva_id = r.subdociva_id
          and r.ivamov_id = mov.ivamov_id
          and mov.ente_proprietario_id = '||enteproprietarioid||';
          alter table t_ivamov_del add primary key (ivamov_id);
          ANALYZE t_ivamov_del;';

	-- Relazioni tra subdoc iva per subdoc iva da cancellare
       strMessaggio := 'create migr_relaz_subdcoiva_del.';
         execute 'DROP TABLE IF EXISTS migr_relaz_subdcoiva_del;
         create table migr_relaz_subdcoiva_del as
          select r.doc_r_id from siac_r_subdoc_iva r, migr_docquo_iva_del tmp
          where r.ente_proprietario_id = '||enteproprietarioid||'
          and (r.subdociva_id_da=tmp.subdociva_id or r.subdociva_id_a=tmp.subdociva_id);
          alter table migr_relaz_subdcoiva_del add primary key (doc_r_id);
          ANALYZE migr_relaz_subdcoiva_del;';
*/
    exception
    	when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := '-1';
        return;
	end;

    strMessaggio := 'Pulizia tabelle.';

/* 27.11.2015
   Parte relativa ai dati iva: questa funzione viene richiamata nel flusso dopo la migrazione dei documenti e prima della migrazione
   dell'iva. Se l''iter non cambia non e necessario pulire questi dati perche non sono stati ancora migrati

      delete from siac_r_ivamov r using t_ivamov_del tmp
      where  r.ivamov_id=tmp.ivamov_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_t_ivamov t using t_ivamov_del tmp
      where  t.ivamov_id=tmp.ivamov_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_subdoc_iva r using migr_relaz_subdcoiva_del tmp
      where r.doc_r_id=tmp.doc_r_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_subdoc_iva_stato r using migr_docquo_iva_del tmp
      where r.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_subdoc_iva_attr r using migr_docquo_iva_del tmp
      where r.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_t_subdoc_iva t using migr_docquo_iva_del tmp
      where t.subdociva_id=tmp.subdociva_id
      and ente_proprietario_id = enteproprietarioid;

      delete from siac_r_doc_iva r using migr_doc_del tmp
      where r.doc_id=tmp.doc_id
      and ente_proprietario_id = enteproprietarioid;
*/

-- cancellazione atto allegato

	delete from siac_r_atto_allegato_elenco_doc r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_atto_allegato_stato r using migr_atto_allegato_del tmp
    where r.attoal_id=tmp.attoal_id
    and r.ente_proprietario_id=enteproprietarioid;

	delete from siac_r_atto_allegato_sog r using migr_atto_allegato_del tmp
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

-- cancellazione elenco doc
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

	--01.02.2017 SIAC_R_SUBDOC_SPLITREVERSE_IVA_TIPO - DAVIDE
    delete from siac_r_subdoc_splitreverse_iva_tipo r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

    delete from siac_t_subdoc r using migr_docquo_del tmp
    where r.subdoc_id=tmp.subdoc_id
    and r.ente_proprietario_id=enteproprietarioid;

-- cancellazione doc
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

    -- 06.10.2015
	delete from siac_t_registrounico_doc r using migr_doc_del tmp
    where r.doc_id=tmp.doc_id
    and r.ente_proprietario_id=enteproprietarioid;

    --09.02.2016
    delete from siac_t_subdoc_num num using migr_doc_del tmp
    where num.doc_id=tmp.doc_id
    and num.ente_proprietario_id=enteproprietarioid;

    delete from siac_t_doc t using migr_doc_del tmp
    where t.doc_id=tmp.doc_id
    and t.ente_proprietario_id=enteproprietarioid;

    -- riportiamo a N i record cancellati
    update migr_doc_entrata m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_doc_entrata_t_doc rm, migr_doc_del tmp
    			where rm.ente_proprietario_id=enteproprietarioid
                and rm.doc_id=tmp.doc_id and tmp.tipo_doc='E'
                and rm.migr_doc_entrata_id=m.migr_docentrata_id);

    update migr_docquo_entrata m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_docquo_entrata_t_subdoc rm, migr_docquo_del tmp
    		    where rm.ente_proprietario_id=enteproprietarioid
                and rm.subdoc_id=tmp.subdoc_id
    			and tmp.tipo_doc = 'E'
                and rm.migr_docquo_entrata_id=m.migr_docquo_entrata_id);


    update migr_doc_spesa m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_doc_spesa_t_doc rm, migr_doc_del tmp
    			where rm.ente_proprietario_id=enteproprietarioid
                and rm.doc_id=tmp.doc_id and tmp.tipo_doc='S'
                and rm.migr_doc_spesa_id=m.migr_docspesa_id);

    update migr_docquo_spesa m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_docquo_spesa_t_subdoc rm, migr_docquo_del tmp
    		    where rm.ente_proprietario_id=enteproprietarioid
                and rm.subdoc_id=tmp.subdoc_id
    			and tmp.tipo_doc = 'S'
                and rm.migr_docquo_spesa_id=m.migr_docquo_spesa_id);

    update migr_atto_allegato m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_atto_all_t_atto_allegato rm , migr_atto_allegato_del tmp
    			where rm.ente_proprietario_id = enteproprietarioid
                and rm.attoal_id=tmp.attoal_id
                and rm.migr_atto_allegato_id=m.migr_atto_allegato_id);

	update migr_elenco_doc_allegati m
    set fl_elab='N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_elenco_doc_all_t_elenco_doc rm ,migr_elencoDocAllegati_del tmp
    			where  rm.ente_proprietario_id = enteproprietarioid
                and rm.eldoc_id=tmp.eldoc_id
                and rm.migr_elenco_doc_id=m.migr_elenco_doc_id);

/* 27.11.2015
   Parte relativa ai dati iva: questa funzione viene richiamata nel flusso dopo la migrazione dei documenti e prima della migrazione
   dell'iva. Se l'iter non cambia non e necessario pulire questi dati perche non sono stati ancora migrati

	update migr_docquo_spesa_iva m
    set fl_elab= 'N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_docquospesaiva_t_subdoc_iva rm ,migr_docquo_iva_del tmp
    			where rm.ente_proprietario_id = enteproprietarioid
                and rm.subdociva_id=rm.subdociva_id
                and rm.migr_docquo_spesa_iva_id=m.migr_docquo_spesa_iva_id);

    update migr_docquo_spesa_iva_aliquota m
    set fl_elab= 'N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_docquospesaivaaliq_t_ivamov rm , t_ivamov_del tmp
    			where rm.ente_proprietario_id = enteproprietarioid
		        and rm.ivamov_id=tmp.ivamov_id
    			and rm.migr_docquospesa_iva_aliquota_id=m.migr_docquospesa_iva_aliquota_id);

	update migr_relaz_docquo_spesa_iva m
    set fl_elab = 'N'
    where m.ente_proprietario_id=enteproprietarioid
    and exists (select 1 from siac_r_migr_relazdocquospesaiva_subdoc rm , migr_relaz_subdcoiva_del tmp
    			where rm.ente_proprietario_id = enteproprietarioid
		        and rm.doc_r_id=tmp.doc_r_id
    			and rm.migr_relazdocquo_id=m.migr_relazdocquo_id);
*/

    -- Inseriamo i record come scarti 'DATO BONIFICATO'.

	insert into migr_doc_spesa_scarto
	(migr_doc_spesa_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_doc_spesa_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
     from migr_doc_del del, siac_r_migr_doc_spesa_t_doc rel
     where del.tipo_doc='S'
     and del.doc_id = rel.doc_id
     and rel.ente_proprietario_id=enteproprietarioid);

	insert into migr_docquo_spesa_scarto
	(migr_docquo_spesa_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_docquo_spesa_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
     from migr_docquo_del del, siac_r_migr_docquo_spesa_t_subdoc rel
     where del.subdoc_id=rel.subdoc_id
     and del.tipo_doc='S'
     and rel.ente_proprietario_id=enteproprietarioid);

	insert into migr_doc_entrata_scarto
	(migr_doc_entrata_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_doc_entrata_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
     from migr_doc_del del, siac_r_migr_doc_entrata_t_doc rel
     where del.tipo_doc='E'
     and del.doc_id = rel.doc_id
     and rel.ente_proprietario_id=enteproprietarioid);

	insert into migr_docquo_entrata_scarto
	(migr_docquo_entrata_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_docquo_entrata_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
     from migr_docquo_del del, siac_r_migr_docquo_entrata_t_subdoc rel
     where del.subdoc_id=rel.subdoc_id
     and del.tipo_doc='E'
     and rel.ente_proprietario_id=enteproprietarioid);

	insert into migr_elenco_doc_scarto
    (migr_elenco_doc_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_elenco_doc_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
    from migr_elencoDocAllegati_del del, siac_r_migr_elenco_doc_all_t_elenco_doc rel
    where del.eldoc_id=rel.eldoc_id
    and rel.ente_proprietario_id=ente_proprietario_id);

	insert into migr_atto_allegato_scarto
    (migr_atto_allegato_id,motivo_scarto,data_creazione,ente_proprietario_id)
    (select rel.migr_atto_allegato_id,'DATO BONIFICATO', clock_timestamp(),enteproprietarioid
    from migr_atto_allegato_del del, siac_r_migr_atto_all_t_atto_allegato rel
    where del.attoal_id=rel.attoal_id
    and rel.ente_proprietario_id=ente_proprietario_id);

	-- Cancelliamo la relazione creata tra dato da migrare e dato migrato
    delete from siac_r_migr_docquo_entrata_t_subdoc m using migr_docquo_del tmp
    where m.subdoc_id=tmp.subdoc_id
    and tmp.tipo_doc = 'E'
    and m.ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_doc_entrata_t_doc m using migr_doc_del tmp
    where m.doc_id=tmp.doc_id
    and tmp.tipo_doc = 'E'
    and ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_docquo_spesa_t_subdoc m using migr_docquo_del tmp
    where m.subdoc_id=tmp.subdoc_id
    and tmp.tipo_doc = 'S'
    and ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_doc_spesa_t_doc m using migr_doc_del tmp
    where m.doc_id=tmp.doc_id
    and tmp.tipo_doc = 'S'
    and ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_atto_all_t_atto_allegato m using migr_atto_allegato_del tmp
    where m.attoal_id=tmp.attoal_id
    and m.ente_proprietario_id=enteproprietarioid;

    delete from siac_r_migr_elenco_doc_all_t_elenco_doc r using migr_elencoDocAllegati_del tmp
    where r.eldoc_id=tmp.eldoc_id
    and r.ente_proprietario_id=enteproprietarioid;

/* 27.11.2015
   Parte relativa ai dati iva: questa funzione viene richiamata nel flusso dopo la migrazione dei documenti e prima della migrazione
   dell'iva. Se l'iter non cambia non e necessario pulire questi dati perche non sono stati ancora migrati

    delete from siac_r_migr_docquospesaiva_t_subdoc_iva m using migr_docquo_iva_del tmp
    where m.subdociva_id=tmp.subdociva_id
    and ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_docquospesaivaaliq_t_ivamov m using t_ivamov_del tmp
    where m.ivamov_id=tmp.ivamov_id
    and ente_proprietario_id = enteproprietarioid;

    delete from siac_r_migr_relazdocquospesaiva_subdoc m using migr_relaz_subdcoiva_del r
    where m.doc_r_id=r.doc_r_id
    and m.ente_proprietario_id = enteproprietarioid;
*/
   -- Aggiorniamo contatore registro unico fatture

    strMessaggio:='Aggiornamento contatore per registro unico fattura 1 .';
	update siac_t_registrounico_doc_num num
    set rudoc_registrazione_numero = (select coalesce(max(rudoc_registrazione_numero),0)
    	from siac_t_registrounico_doc ruf
        where ente_proprietario_id = enteProprietarioId
        and ruf.rudoc_registrazione_anno = num.rudoc_registrazione_anno
        and data_cancellazione is null
        and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
        and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null))
    , data_modifica = clock_timestamp()
    where num.ente_proprietario_id=enteProprietarioId
    and data_cancellazione is null
    and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
    and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);


    strMessaggio:='Aggiornamento contatore per registro unico fattura 2.';
	update siac_t_registrounico_doc_num num
    set rudoc_registrazione_numero = 0
    , data_modifica = clock_timestamp()

    where num.ente_proprietario_id=enteProprietarioId
    and num.rudoc_registrazione_anno not in
    	(select distinct ruf.rudoc_registrazione_anno from siac_t_registrounico_doc ruf
        where ruf.ente_proprietario_id=enteProprietarioId
        and ruf.data_cancellazione is null
        and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
        and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null)
        )
    and data_cancellazione is null
    and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
    and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

   -- Aggiorniamo contatore elenco doc
   strMessaggio:='Aggiornamento contatore elenco doc.';
   -- 14.12.2015: da pentaho la funzione e richiamata tra la migrazione dei documenti e la migrazione dell'iva.
   -- Se viene eseguita la clean completa prima il numero elenco sara = 0 perche tutti i record saranno stati cancellati.
   -- Necessario dunque coalesce sul max
   update siac_t_elenco_doc_num num
   set eldoc_numero =
   		(select coalesce(max(el.eldoc_numero),0) from siac_t_elenco_doc el
        	where el.ente_proprietario_id=enteProprietarioId
            and el.eldoc_anno=annobilancio::integer)
   , data_modifica = clock_timestamp()
   where num.ente_proprietario_id=enteProprietarioId
   and num.bil_id=bilancioid
   and num.data_cancellazione is null
   and date_trunc('day',dataElaborazione)>=date_trunc('day',num.validita_inizio)
   and (date_trunc('day',dataElaborazione)<=date_trunc('day',num.validita_fine) or num.validita_fine is null);

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